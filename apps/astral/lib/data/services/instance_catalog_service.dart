import 'dart:io';

import 'package:astral/data/services/app_settings_service.dart';
import 'package:astral/data/services/platform_path_service.dart';
import 'package:astral/data/services/toml_config_service.dart';
import 'package:get_it/get_it.dart';

class InstanceCatalogSnapshot {
  final String rootPath;
  final List<InstanceCatalogItem> items;

  const InstanceCatalogSnapshot({required this.rootPath, required this.items});
}

class InstanceCatalogItem {
  final String path;
  final String name;
  final String fileName;
  final String relativePath;

  const InstanceCatalogItem({
    required this.path,
    required this.name,
    required this.fileName,
    required this.relativePath,
  });
}

class InstanceCatalogEntry {
  final String path;
  final String name;
  final String relativePath;
  final bool isDirectory;
  final bool isToml;

  const InstanceCatalogEntry({
    required this.path,
    required this.name,
    required this.relativePath,
    required this.isDirectory,
    required this.isToml,
  });
}

class InstanceCatalogDirectoryView {
  final String rootPath;
  final String currentPath;
  final List<InstanceCatalogEntry> entries;

  const InstanceCatalogDirectoryView({
    required this.rootPath,
    required this.currentPath,
    required this.entries,
  });
}

class InstanceCatalogService {
  final PlatformPathService _pathService;
  final TomlConfigService _tomlService;

  const InstanceCatalogService(this._pathService, this._tomlService);

  Future<InstanceCatalogSnapshot> loadSnapshot() async {
    final rootPath = await ensureSourceDirPath();
    final srcDir = Directory(rootPath);
    final items = <InstanceCatalogItem>[];

    await for (final entity in srcDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.toml')) {
        continue;
      }
      items.add(await _buildItem(rootPath, entity));
    }

    items.sort(
      (a, b) =>
          a.relativePath.toLowerCase().compareTo(b.relativePath.toLowerCase()),
    );
    return InstanceCatalogSnapshot(rootPath: rootPath, items: items);
  }

  Future<InstanceCatalogDirectoryView> loadDirectory({
    String? directoryPath,
  }) async {
    final rootPath = await ensureSourceDirPath();
    final requested = directoryPath ?? rootPath;
    final currentPath = _normalizePath(requested);
    final rootNormalized = _normalizePath(rootPath);
    if (!_isWithinRoot(rootNormalized, currentPath)) {
      throw const FileSystemException('Directory path is outside of root.');
    }

    final dir = Directory(currentPath);
    if (!await dir.exists()) {
      throw const FileSystemException('Directory does not exist.');
    }

    final entries = <InstanceCatalogEntry>[];
    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      final isDirectory = entity is Directory;
      final name = basename(entity.path);
      entries.add(
        InstanceCatalogEntry(
          path: entity.path,
          name: name,
          relativePath: _relativePath(rootPath, entity.path),
          isDirectory: isDirectory,
          isToml: !isDirectory && name.toLowerCase().endsWith('.toml'),
        ),
      );
    }

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return InstanceCatalogDirectoryView(
      rootPath: rootPath,
      currentPath: currentPath,
      entries: entries,
    );
  }

  Future<List<String>> listAllDirectories({String? rootPath}) async {
    final root = _normalizePath(rootPath ?? await ensureSourceDirPath());
    final rootDir = Directory(root);
    if (!await rootDir.exists()) {
      return [root];
    }

    final result = <String>[root];
    await for (final entity in rootDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is Directory) {
        result.add(_normalizePath(entity.path));
      }
    }
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  Future<String> createInstanceFile(String name) async {
    final rootPath = await ensureSourceDirPath();
    return createFile(
      directoryPath: rootPath,
      name: name,
      appendTomlWhenMissing: true,
      withTomlTemplate: true,
    );
  }

  Future<String> createFile({
    required String directoryPath,
    required String name,
    bool appendTomlWhenMissing = true,
    bool withTomlTemplate = true,
  }) async {
    if (!isValidName(name)) {
      throw const FormatException('File name cannot contain path separators.');
    }
    final parent = _normalizePath(directoryPath);
    final root = _normalizePath(await ensureSourceDirPath());
    if (!_isWithinRoot(root, parent)) {
      throw const FileSystemException('Target directory is outside of root.');
    }

    var fileName = name.trim();
    if (appendTomlWhenMissing && !fileName.contains('.')) {
      fileName = ensureTomlName(fileName);
    }

    final path = '$parent${Platform.pathSeparator}$fileName';
    final file = File(path);
    if (await file.exists()) {
      throw StateError('File already exists.');
    }

    await file.create(recursive: true);
    if (withTomlTemplate && fileName.toLowerCase().endsWith('.toml')) {
      final template = _tomlService.defaultToml();
      await file.writeAsString(template);
    }
    return file.path;
  }

  Future<String> createFolder({
    required String directoryPath,
    required String name,
  }) async {
    if (!isValidName(name)) {
      throw const FormatException(
        'Folder name cannot contain path separators.',
      );
    }

    final parent = _normalizePath(directoryPath);
    final root = _normalizePath(await ensureSourceDirPath());
    if (!_isWithinRoot(root, parent)) {
      throw const FileSystemException('Target directory is outside of root.');
    }

    final path = '$parent${Platform.pathSeparator}${name.trim()}';
    final dir = Directory(path);
    if (await dir.exists()) {
      throw StateError('Folder already exists.');
    }
    await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> renameEntry({
    required String path,
    required String newName,
  }) async {
    if (!isValidName(newName)) {
      throw const FormatException('Name cannot contain path separators.');
    }

    final normalized = _normalizePath(path);
    final parent = Directory(normalized).parent.path;
    final targetPath = '$parent${Platform.pathSeparator}${newName.trim()}';
    return _renameEntity(fromPath: normalized, toPath: targetPath);
  }

  Future<String> moveEntry({
    required String sourcePath,
    required String destinationDirectoryPath,
  }) async {
    final root = _normalizePath(await ensureSourceDirPath());
    final source = _normalizePath(sourcePath);
    final destination = _normalizePath(destinationDirectoryPath);

    if (!_isWithinRoot(root, source) || !_isWithinRoot(root, destination)) {
      throw const FileSystemException('Path is outside of root.');
    }

    final sourceEntity = FileSystemEntity.typeSync(source);
    if (sourceEntity == FileSystemEntityType.notFound) {
      throw const FileSystemException('Source does not exist.');
    }

    final name = basename(source);
    final toPath = '$destination${Platform.pathSeparator}$name';
    if (source == toPath) {
      return source;
    }

    if (sourceEntity == FileSystemEntityType.directory &&
        _isWithinRoot(source, destination)) {
      throw const FileSystemException('Cannot move folder into itself.');
    }

    return _renameEntity(fromPath: source, toPath: toPath);
  }

  Future<void> deleteEntry(String path) async {
    final root = _normalizePath(await ensureSourceDirPath());
    final normalized = _normalizePath(path);
    if (!_isWithinRoot(root, normalized)) {
      throw const FileSystemException('Path is outside of root.');
    }

    final type = FileSystemEntity.typeSync(normalized);
    switch (type) {
      case FileSystemEntityType.directory:
        await Directory(normalized).delete(recursive: true);
        return;
      case FileSystemEntityType.file:
        await File(normalized).delete();
        return;
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
      case FileSystemEntityType.link:
      case FileSystemEntityType.notFound:
        throw const FileSystemException('Entry does not exist.');
    }
  }

  bool isValidName(String name) {
    return !name.contains('/') && !name.contains('\\');
  }

  String ensureTomlName(String name) {
    final trimmed = name.trim();
    return trimmed.toLowerCase().endsWith('.toml') ? trimmed : '$trimmed.toml';
  }

  String basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index == -1 ? normalized : normalized.substring(index + 1);
  }

  Future<String> ensureSourceDirPath() async {
    final settings = GetIt.I<AppSettingsService>();
    final customDir = settings.getSourceDir();
    if (customDir != null && customDir.isNotEmpty) {
      final dir = Directory(customDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    }
    return await _defaultSourceDirPath();
  }

  Future<String> getDefaultSourceDirPath() async {
    return await _defaultSourceDirPath();
  }

  Future<String> _defaultSourceDirPath() async {
    final configDir = await _pathService.configDir();
    final srcDir = Directory('${configDir.path}${Platform.pathSeparator}src');
    if (!await srcDir.exists()) {
      await srcDir.create(recursive: true);
    }
    return srcDir.path;
  }

  String relativePath(String rootPath, String fullPath) {
    return _relativePath(rootPath, fullPath);
  }

  bool isWithinRoot(String rootPath, String targetPath) {
    return _isWithinRoot(_normalizePath(rootPath), _normalizePath(targetPath));
  }

  Future<InstanceCatalogItem> _buildItem(String rootPath, File file) async {
    final displayName = basename(file.path).replaceAll('.toml', '');

    return InstanceCatalogItem(
      path: file.path,
      name: displayName,
      fileName: basename(file.path),
      relativePath: _relativePath(rootPath, file.path),
    );
  }

  Future<String> _renameEntity({
    required String fromPath,
    required String toPath,
  }) async {
    final type = FileSystemEntity.typeSync(fromPath);
    if (FileSystemEntity.typeSync(toPath) != FileSystemEntityType.notFound) {
      throw StateError('Target already exists.');
    }

    try {
      switch (type) {
        case FileSystemEntityType.directory:
          return (await Directory(fromPath).rename(toPath)).path;
        case FileSystemEntityType.file:
          return (await File(fromPath).rename(toPath)).path;
        case FileSystemEntityType.pipe:
        case FileSystemEntityType.unixDomainSock:
        case FileSystemEntityType.link:
        case FileSystemEntityType.notFound:
          throw const FileSystemException('Source does not exist.');
      }
    } on FileSystemException {
      if (type == FileSystemEntityType.file) {
        final target = await File(fromPath).copy(toPath);
        await File(fromPath).delete();
        return target.path;
      }
      rethrow;
    }

    throw const FileSystemException('Rename failed.');
  }

  String _relativePath(String rootPath, String fullPath) {
    final root = _normalizePath(rootPath);
    final full = _normalizePath(fullPath);
    if (full == root) {
      return '';
    }
    if (full.startsWith('$root/')) {
      return full.substring(root.length + 1);
    }
    return fullPath;
  }

  String _normalizePath(String path) {
    return path.replaceAll('\\', '/');
  }

  bool _isWithinRoot(String rootPath, String targetPath) {
    if (targetPath == rootPath) {
      return true;
    }
    return targetPath.startsWith('$rootPath/');
  }
}
