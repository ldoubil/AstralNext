import 'dart:convert';
import 'dart:io' as io;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart' hide File;

import 'app_settings_service.dart';
import 'instance_catalog_service.dart';
import 'platform_path_service.dart';

/// 将 WebDAV 错误转为用户可读的中文提示
String _webDavErrorMessage(dynamic error) {
  final msg = error.toString();
  if (msg.contains('401') || msg.contains('Unauthorized')) {
    return '登录失败：用户名或密码错误';
  }
  if (msg.contains('403') || msg.contains('Forbidden')) {
    return '没有写入权限：请检查 WebDAV 账户是否对该路径有写入权限';
  }
  if (msg.contains('404') || msg.contains('Not Found')) {
    return '路径不存在：请检查远程路径配置是否正确';
  }
  if (msg.contains('409') || msg.contains('Conflict')) {
    return '路径冲突：远程目录结构异常，请手动检查';
  }
  if (msg.contains('Connection') ||
      msg.contains('Socket') ||
      msg.contains('Timeout')) {
    return '连接失败：无法连接到 WebDAV 服务器，请检查网络和地址';
  }
  return '备份失败：$msg';
}

/// 备份元数据
class BackupMeta {
  final DateTime createdAt;
  final String appVersion;
  final List<String> configFiles;
  final bool hasSettings;
  final bool hasDashboardLayout;

  const BackupMeta({
    required this.createdAt,
    required this.appVersion,
    required this.configFiles,
    this.hasSettings = true,
    this.hasDashboardLayout = true,
  });

  Map<String, dynamic> toJson() => {
        'created_at': createdAt.toIso8601String(),
        'app_version': appVersion,
        'config_files': configFiles,
        'has_settings': hasSettings,
        'has_dashboard_layout': hasDashboardLayout,
      };

  factory BackupMeta.fromJson(Map<String, dynamic> json) => BackupMeta(
        createdAt: DateTime.parse(json['created_at'] as String),
        appVersion: json['app_version'] as String? ?? 'unknown',
        configFiles: (json['config_files'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        hasSettings: json['has_settings'] as bool? ?? false,
        hasDashboardLayout: json['has_dashboard_layout'] as bool? ?? false,
      );
}

/// 远程备份条目
class RemoteBackupEntry {
  final String fileName;
  final String remotePath;
  final String? size;
  final DateTime? lastModified;

  const RemoteBackupEntry({
    required this.fileName,
    required this.remotePath,
    this.size,
    this.lastModified,
  });
}

/// 备份进度回调
typedef BackupProgressCallback = void Function(
    String stage, double progress, String message);

class WebDavBackupService {
  final AppSettingsService _settings;
  final PlatformPathService _pathService;
  final InstanceCatalogService _catalogService;

  static const _backupDirName = 'astral/backups';
  static const _metaFileName = 'backup_meta.json';
  static const _settingsFileName = 'settings.json';
  static const _dashboardLayoutFileName = 'dashboard_layout.json';
  static const _configsDirName = 'configs';

  dynamic _client;

  WebDavBackupService(this._settings, this._pathService, this._catalogService);

  // ---- WebDAV 客户端管理 ----

  dynamic _createClient() {
    final rawUrl = _settings.getWebDavUrl();
    final username = _settings.getWebDavUsername();
    final password = _settings.getWebDavPassword();
    if (rawUrl == null || rawUrl.isEmpty) return null;

    // 标准化 URL：去掉尾部斜杠，避免与路径拼接时产生双斜杠
    var url = rawUrl;
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return newClient(
      url,
      user: username ?? '',
      password: password ?? '',
    );
  }

  /// 测试 WebDAV 连接
  Future<bool> testConnection() async {
    try {
      final client = _createClient();
      if (client == null) return false;
      _client = client;
      await client.ping();
      return true;
    } catch (_) {
      _client = null;
      return false;
    }
  }

  /// 获取 WebDAV 客户端（懒创建）
  dynamic _getClient() {
    return _client ?? _createClient();
  }

  /// 获取远程备份基础路径
  String _getRemoteBasePath() {
    final remotePath = _settings.getWebDavRemotePath();
    if (remotePath != null && remotePath.isNotEmpty) {
      var normalized = remotePath.replaceAll('\\', '/');
      // 确保以 / 开头（绝对路径）
      if (!normalized.startsWith('/')) {
        normalized = '/$normalized';
      }
      // 去掉末尾斜杠
      if (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      return normalized;
    }
    return '';
  }

  String _getRemoteBackupDir() {
    final base = _getRemoteBasePath();
    if (base.isEmpty) {
      return '/$_backupDirName/';
    }
    return '$base/$_backupDirName/';
  }

  // ---- 备份操作 ----

  /// 执行完整备份
  Future<void> backup({BackupProgressCallback? onProgress}) async {
    final client = _getClient();
    if (client == null) throw Exception('WebDAV 未配置');

    try {
      onProgress?.call('prepare', 0, '正在收集数据...');

      // 1. 收集要备份的 TOML 文件
      // configDir 可能是 Windows 路径 (C:\...)，统一为 / 以便字符串匹配
      final configDir = await _catalogService.ensureSourceDirPath();
      final configDirForward = configDir.replaceAll('\\', '/');
      final configFiles = <io.File>[];
      await for (final entity in io.Directory(configDir)
          .list(recursive: true, followLinks: false)) {
        if (entity is io.File &&
            entity.path.toLowerCase().endsWith('.toml')) {
          configFiles.add(entity);
        }
      }

      // 2. 导出应用设置
      final settingsJson = await _exportSettings();

      // 3. 读取 Dashboard 布局
      final appSupportDir = await getApplicationSupportDirectory();
      final dashboardFile = io.File(
          path_lib.join(appSupportDir.path, _dashboardLayoutFileName));

      final hasDashboard = await dashboardFile.exists();
      String? dashboardContent;
      if (hasDashboard) {
        dashboardContent = await dashboardFile.readAsString();
      }

      // 4. 构建元数据
      final meta = BackupMeta(
        createdAt: DateTime.now(),
        appVersion: '1.0.0-beta.1',
        configFiles: configFiles
            .map((f) {
              final rel = f.path
                  .replaceAll('\\', '/')
                  .replaceFirst('$configDirForward/', '');
              return rel;
            })
            .toList(),
        hasSettings: true,
        hasDashboardLayout: hasDashboard,
      );

      onProgress?.call('pack', 0.2, '正在打包备份...');

      // 5. 创建 ZIP
      final tempDir = await _pathService.tempDir(subDir: 'backup');
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[^\d]'), '')
          .substring(0, 14);
      final zipFileName = 'astral_backup_$timestamp.zip';
      final zipPath = path_lib.join(tempDir.path, zipFileName);

      final archive = Archive();

      // 添加元数据
      final metaBytes = utf8.encode(jsonEncode(meta.toJson()));
      archive.addFile(ArchiveFile(_metaFileName, metaBytes.length, metaBytes));

      // 添加应用设置
      final settingsBytes = utf8.encode(settingsJson);
      archive.addFile(
          ArchiveFile(_settingsFileName, settingsBytes.length, settingsBytes));

      // 添加 Dashboard 布局
      if (dashboardContent != null) {
        final dashBytes = utf8.encode(dashboardContent);
        archive.addFile(ArchiveFile(
            _dashboardLayoutFileName, dashBytes.length, dashBytes));
      }

      // 添加 TOML 配置文件
      for (var i = 0; i < configFiles.length; i++) {
        final file = configFiles[i];
        final relPath = file.path
            .replaceAll('\\', '/')
            .replaceFirst('$configDirForward/', '');
        final remoteName = '$_configsDirName/$relPath';
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(remoteName, bytes.length, bytes));

        onProgress?.call('pack',
            0.2 + 0.3 * ((i + 1) / configFiles.length), '正在打包: $relPath');
      }

      // 写入 ZIP 文件
      final zipData = ZipEncoder().encode(archive);
      await io.File(zipPath).writeAsBytes(zipData!);

      onProgress?.call('upload', 0.6, '正在上传...');

      // 6. 确保远程目录存在（分步创建）
      final remoteDir = _getRemoteBackupDir();
      final parts = remoteDir.split('/').where((p) => p.isNotEmpty).toList();
      String currentPath = '';
      for (final part in parts) {
        currentPath += '/$part';
        try {
          await client.mkdir('$currentPath/');
        } catch (_) {
          // 目录可能已存在，忽略
        }
      }

      // 7. 上传 ZIP
      final uploadPath = '$remoteDir$zipFileName';

      await client.writeFromFile(
        zipPath,
        uploadPath,
        onProgress: (count, total) {
          if (total > 0) {
            final p = 0.6 + 0.4 * (count / total);
            onProgress?.call(
                'upload',
                p.clamp(0.0, 1.0),
                '正在上传: ${(count / 1024).toStringAsFixed(1)} KB '
                    '/ ${(total / 1024).toStringAsFixed(1)} KB');
          }
        },
      );

      // 8. 清理临时文件
      try {
        await io.File(zipPath).delete();
      } catch (_) {}

      onProgress?.call('done', 1.0, '备份完成');
    } catch (e) {
      onProgress?.call('error', 0, _webDavErrorMessage(e));
      rethrow;
    }
  }

  /// 获取远程备份列表
  Future<List<RemoteBackupEntry>> listBackups() async {
    final client = _getClient();
    if (client == null) throw Exception('WebDAV 未配置');

    final remoteDir = _getRemoteBackupDir();

    try {
      final files = await client.readDir(remoteDir);
      final entries = <RemoteBackupEntry>[];

      for (final file in files) {
        if (file.name == null ||
            !file.name!.startsWith('astral_backup_') ||
            !file.name!.endsWith('.zip')) {
          continue;
        }
        entries.add(RemoteBackupEntry(
          fileName: file.name!,
          remotePath: '$remoteDir${file.name!}',
          size: file.size?.toString(),
          lastModified: file.mTime,
        ));
      }

      // 按时间倒序
      entries.sort((a, b) {
        final aTime = a.lastModified ?? DateTime(2000);
        final bTime = b.lastModified ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      return entries;
    } catch (e) {
      if (e.toString().contains('404') ||
          e.toString().contains('Not Found')) {
        return [];
      }
      rethrow;
    }
  }

  /// 删除远程备份
  Future<void> deleteBackup(String remotePath) async {
    final client = _getClient();
    if (client == null) throw Exception('WebDAV 未配置');
    await client.remove(remotePath);
  }

  /// 恢复备份
  Future<void> restore(
    String remotePath, {
    bool restoreSettings = true,
    bool restoreDashboardLayout = true,
    bool restoreConfigs = true,
    BackupProgressCallback? onProgress,
  }) async {
    final client = _getClient();
    if (client == null) throw Exception('WebDAV 未配置');

    try {
      onProgress?.call('download', 0, '正在下载备份...');

      // 1. 下载到临时目录
      final tempDir = await _pathService.tempDir(subDir: 'restore');
      final fileName = remotePath.split('/').last;
      final localZipPath = path_lib.join(tempDir.path, fileName);

      await client.read2File(
        remotePath,
        localZipPath,
        onProgress: (count, total) {
          if (total > 0) {
            final p = 0.1 * (count / total);
            onProgress?.call(
                'download',
                p.clamp(0.0, 0.1),
                '正在下载: ${(count / 1024).toStringAsFixed(1)} KB '
                    '/ ${(total / 1024).toStringAsFixed(1)} KB');
          }
        },
      );

      onProgress?.call('extract', 0.1, '正在解压...');

      // 2. 解压 ZIP
      final zipBytes = await io.File(localZipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // 3. 分类文件
      ArchiveFile? settingsFile;
      ArchiveFile? dashboardFile;
      final configArchiveFiles = <ArchiveFile>[];

      for (final file in archive) {
        if (file.isFile == false) continue;
        if (file.name == _settingsFileName) {
          settingsFile = file;
        } else if (file.name == _dashboardLayoutFileName) {
          dashboardFile = file;
        } else if (file.name.startsWith('$_configsDirName/')) {
          configArchiveFiles.add(file);
        }
      }

      onProgress?.call('restore', 0.2, '正在恢复数据...');

      // 4. 恢复应用设置
      if (restoreSettings && settingsFile != null) {
        final content = utf8.decode(settingsFile.content as List<int>);
        await _importSettings(content);
        onProgress?.call('restore', 0.35, '已恢复应用设置');
      }

      // 5. 恢复 Dashboard 布局
      if (restoreDashboardLayout && dashboardFile != null) {
        final appSupportDir = await getApplicationSupportDirectory();
        final targetPath =
            path_lib.join(appSupportDir.path, _dashboardLayoutFileName);
        final content = utf8.decode(dashboardFile.content as List<int>);
        await io.File(targetPath).writeAsString(content);
        onProgress?.call('restore', 0.45, '已恢复面板布局');
      }

      // 6. 恢复 TOML 配置文件
      if (restoreConfigs && configArchiveFiles.isNotEmpty) {
        final configDir = await _catalogService.ensureSourceDirPath();

        for (var i = 0; i < configArchiveFiles.length; i++) {
          final configFile = configArchiveFiles[i];
          // ZIP 内路径统一用 /，去掉 configs/ 前缀得到相对路径
          final relativePath = configFile.name
              .replaceFirst('$_configsDirName/', '')
              .replaceAll('\\', '/');
          // 用 p.join 拼接本地路径，自动处理分隔符
          final targetPath = path_lib.join(configDir, relativePath);

          // 确保父目录存在
          final parentDir = io.Directory(targetPath).parent;
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }

          final content = configFile.content as List<int>;
          debugPrint('[备份恢复] 写入: $targetPath');
          await io.File(targetPath).writeAsBytes(content);

          final p = 0.45 + 0.45 * ((i + 1) / configArchiveFiles.length);
          onProgress?.call('restore', p, '正在恢复: $relativePath');
        }
      }

      // 7. 清理临时文件
      try {
        await io.File(localZipPath).delete();
      } catch (_) {}

      onProgress?.call('done', 1.0, '恢复完成');
    } catch (e, st) {
      debugPrint('[备份恢复] 恢复失败: $e\n$st');
      onProgress?.call('error', 0, _webDavErrorMessage(e));
      rethrow;
    }
  }

  // ---- 设置导出/导入 ----

  /// 导出应用设置为 JSON 字符串
  Future<String> _exportSettings() async {
    final settings = <String, dynamic>{};

    final themeMode = _settings.getThemeMode();
    settings['theme_mode'] = switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    settings['theme_seed_color'] = _settings.getThemeSeedColor().value;

    final closeBehavior = _settings.getCloseBehavior();
    settings['close_behavior'] = switch (closeBehavior) {
      CloseBehavior.minimizeToTray => 'minimizeToTray',
      CloseBehavior.exitApp => 'exitApp',
    };

    settings['source_dir'] = _settings.getSourceDir();

    final editorMode = _settings.getEditorDefaultMode();
    settings['editor_default_mode'] = switch (editorMode) {
      ConfigEditorDefaultMode.visual => 'visual',
      ConfigEditorDefaultMode.text => 'text',
    };

    return jsonEncode(settings);
  }

  /// 从 JSON 字符串导入应用设置
  Future<void> _importSettings(String jsonStr) async {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (map.containsKey('theme_mode')) {
        final value = map['theme_mode'] as String;
        final mode = switch (value) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          'system' => ThemeMode.system,
          _ => null,
        };
        if (mode != null) await _settings.setThemeMode(mode);
      }

      if (map.containsKey('theme_seed_color')) {
        final value = map['theme_seed_color'] as int?;
        if (value != null) {
          await _settings.setThemeSeedColor(Color(value));
        }
      }

      if (map.containsKey('close_behavior')) {
        final value = map['close_behavior'] as String;
        final behavior = switch (value) {
          'minimizeToTray' => CloseBehavior.minimizeToTray,
          'exitApp' => CloseBehavior.exitApp,
          _ => null,
        };
        if (behavior != null) await _settings.setCloseBehavior(behavior);
      }

      if (map.containsKey('source_dir')) {
        final value = map['source_dir'] as String?;
        await _settings.setSourceDir(value);
      }

      if (map.containsKey('editor_default_mode')) {
        final value = map['editor_default_mode'] as String;
        final mode = switch (value) {
          'visual' => ConfigEditorDefaultMode.visual,
          'text' => ConfigEditorDefaultMode.text,
          _ => null,
        };
        if (mode != null) {
          await _settings.setEditorDefaultMode(mode);
        }
      }
    } catch (e) {
      // 静默忽略设置导入错误
    }
  }
}
