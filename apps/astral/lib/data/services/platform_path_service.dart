import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 平台路径工具服务，统一获取配置/数据/缓存/临时等目录。
class PlatformPathService {
  /// 配置目录（Application Support），可选子目录。
  Future<Directory> configDir({String? subDir}) async {
    final base = await getApplicationSupportDirectory();
    return _ensureDir(_withSubDir(base, subDir));
  }

  /// 数据目录（Documents），可选子目录。
  Future<Directory> dataDir({String? subDir}) async {
    final base = await getApplicationDocumentsDirectory();
    return _ensureDir(_withSubDir(base, subDir));
  }

  /// 缓存目录（Cache），异常时回退到临时目录。
  Future<Directory> cacheDir({String? subDir}) async {
    Directory base;
    try {
      base = await getApplicationCacheDirectory();
    } catch (_) {
      base = await getTemporaryDirectory();
    }
    return _ensureDir(_withSubDir(base, subDir));
  }

  /// 临时目录，可选子目录。
  Future<Directory> tempDir({String? subDir}) async {
    final base = await getTemporaryDirectory();
    return _ensureDir(_withSubDir(base, subDir));
  }

  /// 下载目录（可能为 null），可选子目录。
  Future<Directory?> downloadsDir({String? subDir}) async {
    try {
      final base = await getDownloadsDirectory();
      if (base == null) {
        return null;
      }
      return _ensureDir(_withSubDir(base, subDir));
    } catch (_) {
      return null;
    }
  }

  /// 日志目录，默认放在配置目录的 logs 下。
  Future<Directory> logsDir({String? subDir}) async {
    final base = await configDir(subDir: 'logs');
    return _ensureDir(_withSubDir(base, subDir));
  }

  /// 拼接子目录。
  Directory _withSubDir(Directory base, String? subDir) {
    if (subDir == null || subDir.trim().isEmpty) {
      return base;
    }
    return Directory('${base.path}${Platform.pathSeparator}$subDir');
  }

  Future<Directory> _ensureDir(Directory dir) async {
    if (await dir.exists()) {
      return dir;
    }
    await dir.create(recursive: true);
    return dir;
  }
}
