import 'dart:convert';
import 'dart:io' as io;

import 'package:archive/archive.dart';
import 'package:astral_game/utils/logger.dart';
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart' hide File;

import 'package:astral_game/data/models/room_mod.dart';
import 'app_settings_service.dart';
import 'room_persistence_service.dart';

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
  final int roomCount;

  const BackupMeta({
    required this.createdAt,
    required this.appVersion,
    required this.roomCount,
  });

  Map<String, dynamic> toJson() => {
        'created_at': createdAt.toIso8601String(),
        'app_version': appVersion,
        'room_count': roomCount,
      };

  factory BackupMeta.fromJson(Map<String, dynamic> json) => BackupMeta(
        createdAt: DateTime.parse(json['created_at'] as String),
        appVersion: json['app_version'] as String? ?? 'unknown',
        roomCount: (json['room_count'] as num?)?.toInt() ?? 0,
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
  final RoomPersistenceService _roomPersistence;

  static const _backupDirName = 'astral_game/backups';
  static const _metaFileName = 'backup_meta.json';
  static const _roomsFileName = 'rooms.json';

  dynamic _client;

  WebDavBackupService(this._settings, this._roomPersistence);

  // ---- WebDAV 客户端管理 ----

  dynamic _createClient() {
    final rawUrl = _settings.getWebDavUrl();
    final username = _settings.getWebDavUsername();
    final password = _settings.getWebDavPassword();
    if (rawUrl == null || rawUrl.isEmpty) return null;

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

  dynamic _getClient() {
    return _client ?? _createClient();
  }

  String _getRemoteBackupDir() {
    final remotePath = _settings.getWebDavRemotePath();
    if (remotePath != null && remotePath.isNotEmpty) {
      var normalized = remotePath.replaceAll('\\', '/');
      if (!normalized.startsWith('/')) {
        normalized = '/$normalized';
      }
      if (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      return '$normalized/$_backupDirName/';
    }
    return '/$_backupDirName/';
  }

  // ---- 备份操作 ----

  /// 执行完整备份
  Future<void> backup({BackupProgressCallback? onProgress}) async {
    final client = _getClient();
    if (client == null) throw Exception('WebDAV 未配置');

    try {
      onProgress?.call('prepare', 0, '正在收集数据...');

      // 1. 读取房间数据 JSON
      final rooms = await _roomPersistence.loadRooms();
      final roomsJson = jsonEncode(rooms.map((r) => r.toJson()).toList());

      // 2. 构建元数据
      final meta = BackupMeta(
        createdAt: DateTime.now(),
        appVersion: '1.0.0',
        roomCount: rooms.length,
      );

      onProgress?.call('pack', 0.2, '正在打包备份...');

      // 3. 创建 ZIP
      final tempDir = await getTemporaryDirectory();
      final backupTempDir = io.Directory('${tempDir.path}/backup');
      if (!await backupTempDir.exists()) {
        await backupTempDir.create(recursive: true);
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[^\d]'), '')
          .substring(0, 14);
      final zipFileName = 'astral_game_backup_$timestamp.zip';
      final zipPath = path_lib.join(backupTempDir.path, zipFileName);

      final archive = Archive();

      // 添加元数据
      final metaBytes = utf8.encode(jsonEncode(meta.toJson()));
      archive.addFile(ArchiveFile(_metaFileName, metaBytes.length, metaBytes));

      // 添加房间数据
      final roomsBytes = utf8.encode(roomsJson);
      archive
          .addFile(ArchiveFile(_roomsFileName, roomsBytes.length, roomsBytes));

      // 写入 ZIP 文件
      final zipData = ZipEncoder().encode(archive);
      await io.File(zipPath).writeAsBytes(zipData);

      onProgress?.call('upload', 0.6, '正在上传...');

      // 4. 确保远程目录存在
      final remoteDir = _getRemoteBackupDir();
      final parts = remoteDir.split('/').where((p) => p.isNotEmpty).toList();
      String currentPath = '';
      for (final part in parts) {
        currentPath += '/$part';
        try {
          await client.mkdir('$currentPath/');
        } catch (_) {
          // 目录可能已存在
        }
      }

      // 5. 上传 ZIP
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

      // 6. 清理临时文件
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
            !file.name!.startsWith('astral_game_backup_') ||
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
    BackupProgressCallback? onProgress,
  }) async {
    final client = _getClient();
    if (client == null) throw Exception('WebDAV 未配置');

    try {
      onProgress?.call('download', 0, '正在下载备份...');

      // 1. 下载到临时目录
      final tempDir = await getTemporaryDirectory();
      final restoreDir = io.Directory('${tempDir.path}/restore');
      if (!await restoreDir.exists()) {
        await restoreDir.create(recursive: true);
      }

      final fileName = remotePath.split('/').last;
      final localZipPath = path_lib.join(restoreDir.path, fileName);

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

      // 3. 提取房间数据
      for (final file in archive) {
        if (file.isFile == false) continue;
        if (file.name == _roomsFileName) {
          final content = utf8.decode(file.content as List<int>);
          onProgress?.call('restore', 0.2, '正在恢复房间数据...');

          final list = jsonDecode(content) as List;
          final rooms = list
              .map((e) => RoomMod.fromJson(e as Map<String, dynamic>))
              .toList();

          await _roomPersistence.saveRooms(rooms);
          onProgress?.call('done', 1.0, '恢复完成');
        }
      }

      // 4. 清理临时文件
      try {
        await io.File(localZipPath).delete();
      } catch (_) {}
    } catch (e, st) {
      appLogger.e('[备份恢复] 恢复失败: $e', error: e, stackTrace: st);
      onProgress?.call('error', 0, _webDavErrorMessage(e));
      rethrow;
    }
  }
}
