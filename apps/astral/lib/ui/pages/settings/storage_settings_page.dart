import 'package:astral/data/services/instance_catalog_service.dart';
import 'package:astral/data/services/app_settings_service.dart';
import 'package:astral/di.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  State<StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  String? _currentSourceDir;
  String? _defaultSourceDir;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSourceDir();
  }

  Future<void> _loadSourceDir() async {
    final catalog = getIt<InstanceCatalogService>();
    final current = await catalog.ensureSourceDirPath();
    final defaultDir = await catalog.getDefaultSourceDirPath();
    setState(() {
      _currentSourceDir = current;
      _defaultSourceDir = defaultDir;
      _isLoading = false;
    });
  }

  Future<void> _pickSourceDir() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final settings = GetIt.I<AppSettingsService>();
      await settings.setSourceDir(result);
      setState(() {
        _currentSourceDir = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置文件目录已更新')),
        );
      }
    }
  }

  Future<void> _resetSourceDir() async {
    final settings = GetIt.I<AppSettingsService>();
    await settings.clearSourceDir();
    setState(() {
      _currentSourceDir = _defaultSourceDir;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已重置为默认目录')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  title: Text('数据存储'),
                  subtitle: Text('设置配置文件的存储位置'),
                  leading: Icon(Icons.folder),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Text(
                  '配置文件目录',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '此目录用于存储网络配置文件（.toml）',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentSourceDir ?? '',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickSourceDir,
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('浏览'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _currentSourceDir != _defaultSourceDir
                            ? _resetSourceDir
                            : null,
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('重置为默认'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
