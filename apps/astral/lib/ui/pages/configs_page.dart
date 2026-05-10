import 'dart:io';

import 'package:astral/data/services/instance_catalog_service.dart';
import 'package:astral/data/services/platform_path_service.dart';
import 'package:astral/data/services/toml_config_service.dart';
import 'package:astral/di.dart';
import 'package:astral/ui/pages/config_editor_page.dart';
import 'package:astral/ui/shell/shell_content_controller.dart';
import 'package:flutter/material.dart';

enum _EntryAction { open, rename, move, delete }

class ConfigsPage extends StatefulWidget {
  const ConfigsPage({super.key});

  @override
  State<ConfigsPage> createState() => _ConfigsPageState();
}

class _ConfigsPageState extends State<ConfigsPage> {
  late final InstanceCatalogService _catalogService;
  Future<InstanceCatalogDirectoryView>? _viewFuture;
  InstanceCatalogDirectoryView? _cachedView;
  String? _currentPath;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _catalogService = InstanceCatalogService(
      getIt<PlatformPathService>(),
      getIt<TomlConfigService>(),
    );
    _reload(resetToRoot: true);
  }

  void _reload({bool resetToRoot = false}) {
    setState(() {
      final path = resetToRoot ? null : _currentPath;
      _viewFuture = _catalogService.loadDirectory(directoryPath: path);
    });
  }

  Future<void> _refresh() async {
    final future = _catalogService.loadDirectory(directoryPath: _currentPath);
    setState(() {
      _viewFuture = future;
    });
    await future;
  }

  void _setFabExpanded(bool expanded) {
    if (_isFabExpanded == expanded) {
      return;
    }
    setState(() {
      _isFabExpanded = expanded;
    });
  }

  void _toggleFabExpanded() {
    _setFabExpanded(!_isFabExpanded);
  }

  void _collapseFab() {
    _setFabExpanded(false);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _promptForName({
    required String title,
    required String hintText,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue);

    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: hintText),
              onSubmitted: (input) => Navigator.of(context).pop(input),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    } finally {
      // 延迟释放控制器，确保TextField已经完全销毁
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          controller.dispose();
        } catch (_) {
          // 忽略可能的重复释放错误
        }
      });
    }
  }

  Future<void> _createFile() async {
    final directory = _currentPath;
    if (directory == null) {
      return;
    }
    final name = await _promptForName(title: '新建文件', hintText: '例如 node.toml');
    if (name == null) {
      return;
    }

    try {
      final created = await _catalogService.createFile(
        directoryPath: directory,
        name: name,
        appendTomlWhenMissing: true,
        withTomlTemplate: true,
      );
      _showMessage('已创建文件: ${_catalogService.basename(created)}');
      await _refresh();
    } on FormatException catch (_) {
      _showMessage('文件名不能包含路径分隔符。');
    } on StateError catch (_) {
      _showMessage('文件已存在。');
    } catch (error) {
      _showMessage('创建失败: $error');
    }
  }

  Future<void> _createFolder() async {
    final directory = _currentPath;
    if (directory == null) {
      return;
    }
    final name = await _promptForName(title: '新建文件夹', hintText: '输入文件夹名称');
    if (name == null) {
      return;
    }

    try {
      final created = await _catalogService.createFolder(
        directoryPath: directory,
        name: name,
      );
      _showMessage('已创建文件夹: ${_catalogService.basename(created)}');
      await _refresh();
    } on FormatException catch (_) {
      _showMessage('文件夹名不能包含路径分隔符。');
    } on StateError catch (_) {
      _showMessage('文件夹已存在。');
    } catch (error) {
      _showMessage('创建失败: $error');
    }
  }

  Future<void> _openEntry(InstanceCatalogEntry entry) async {
    if (entry.isDirectory) {
      setState(() {
        _viewFuture = _catalogService.loadDirectory(directoryPath: entry.path);
      });
      return;
    }

    final controller = getIt<ShellContentController>();
    controller.showOverlay(
      content: ConfigEditorPage(path: entry.path),
      title: entry.name,
      onClose: () {
        if (mounted) {
          _reload();
        }
      },
    );
  }

  Future<void> _renameEntry(InstanceCatalogEntry entry) async {
    final name = await _promptForName(
      title: '重命名',
      hintText: '输入新名称',
      initialValue: entry.name,
    );
    if (name == null || name == entry.name) {
      return;
    }

    try {
      await _catalogService.renameEntry(path: entry.path, newName: name);
      _showMessage('已重命名。');
      await _refresh();
    } on FormatException catch (_) {
      _showMessage('名称不能包含路径分隔符。');
    } on StateError catch (_) {
      _showMessage('目标名称已存在。');
    } catch (error) {
      _showMessage('重命名失败: $error');
    }
  }

  Future<void> _moveEntry(
    InstanceCatalogEntry entry,
    InstanceCatalogDirectoryView view,
  ) async {
    final allDirs = await _catalogService.listAllDirectories(
      rootPath: view.rootPath,
    );
    final normalizedSource = entry.path.replaceAll('\\', '/');
    final allowedDirs = allDirs
        .where((dir) {
          if (!entry.isDirectory) {
            return true;
          }
          if (dir == normalizedSource) {
            return false;
          }
          return !dir.startsWith('$normalizedSource/');
        })
        .toList(growable: false);

    if (!mounted) {
      return;
    }

    if (allowedDirs.isEmpty) {
      _showMessage('没有可移动到的目标目录。');
      return;
    }

    var selected = allowedDirs.first;
    final destination = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('移动到'),
              content: DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '目标目录'),
                items: allowedDirs
                    .map((path) {
                      final relative = _catalogService.relativePath(
                        view.rootPath,
                        path,
                      );
                      final label = relative.isEmpty ? 'src' : 'src/$relative';
                      return DropdownMenuItem(value: path, child: Text(label));
                    })
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setDialogState(() {
                    selected = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: const Text('移动'),
                ),
              ],
            );
          },
        );
      },
    );

    if (destination == null) {
      return;
    }

    try {
      await _catalogService.moveEntry(
        sourcePath: entry.path,
        destinationDirectoryPath: destination,
      );
      _showMessage('移动成功。');
      await _refresh();
    } on StateError catch (_) {
      _showMessage('目标位置已存在同名项。');
    } on FileSystemException catch (error) {
      _showMessage('移动失败: ${error.message}');
    } catch (error) {
      _showMessage('移动失败: $error');
    }
  }

  Future<void> _deleteEntry(InstanceCatalogEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除'),
          content: Text(
            entry.isDirectory
                ? '确认删除文件夹 "${entry.name}" 及其所有内容？'
                : '确认删除文件 "${entry.name}"？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _catalogService.deleteEntry(entry.path);
      _showMessage('删除成功。');
      await _refresh();
    } catch (error) {
      _showMessage('删除失败: $error');
    }
  }

  Future<void> _handleEntryAction(
    _EntryAction action,
    InstanceCatalogEntry entry,
    InstanceCatalogDirectoryView view,
  ) async {
    switch (action) {
      case _EntryAction.open:
        await _openEntry(entry);
        return;
      case _EntryAction.rename:
        await _renameEntry(entry);
        return;
      case _EntryAction.move:
        await _moveEntry(entry, view);
        return;
      case _EntryAction.delete:
        await _deleteEntry(entry);
        return;
    }
  }

  Widget _buildPathBar(InstanceCatalogDirectoryView view, int entryCount) {
    final colorScheme = Theme.of(context).colorScheme;
    final relative = _catalogService.relativePath(
      view.rootPath,
      view.currentPath,
    );
    final segments = relative.isEmpty
        ? <String>[]
        : relative
              .split('/')
              .where((item) => item.isNotEmpty)
              .toList(growable: false);

    final roots = <_PathCrumb>[_PathCrumb(label: 'src', path: view.rootPath)];
    var current = view.rootPath;
    for (final segment in segments) {
      current = '$current/${segment.trim()}';
      roots.add(_PathCrumb(label: segment, path: current));
    }

    final canGoUp =
        view.currentPath.replaceAll('\\', '/') !=
        view.rootPath.replaceAll('\\', '/');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回上级',
            visualDensity: VisualDensity.compact,
            onPressed: !canGoUp
                ? null
                : () {
                    final parent = Directory(view.currentPath).parent.path;
                    setState(() {
                      _viewFuture = _catalogService.loadDirectory(
                        directoryPath: parent,
                      );
                    });
                  },
            icon: const Icon(Icons.arrow_upward),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < roots.length; i++) ...[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _viewFuture = _catalogService.loadDirectory(
                            directoryPath: roots[i].path,
                          );
                        });
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(roots[i].label),
                    ),
                    if (i != roots.length - 1)
                      Text(
                        '/',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entryCount} 项',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(
    InstanceCatalogEntry entry,
    InstanceCatalogDirectoryView view,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final leadingIcon = entry.isDirectory
        ? Icons.folder_outlined
        : Icons.description_outlined;
    final subtitle = entry.isDirectory ? '文件夹' : '文件';

    return ListTile(
      dense: true,
      onTap: () => _openEntry(entry),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: entry.isDirectory
              ? colorScheme.tertiaryContainer
              : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          leadingIcon,
          size: 18,
          color: entry.isDirectory
              ? colorScheme.onTertiaryContainer
              : colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: PopupMenuButton<_EntryAction>(
        tooltip: '更多操作',
        onSelected: (action) => _handleEntryAction(action, entry, view),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _EntryAction.open,
            child: Text(entry.isDirectory ? '打开文件夹' : '打开文件'),
          ),
          const PopupMenuItem(value: _EntryAction.rename, child: Text('重命名')),
          const PopupMenuItem(value: _EntryAction.move, child: Text('移动到')),
          const PopupMenuItem(value: _EntryAction.delete, child: Text('删除')),
        ],
      ),
    );
  }

  Widget _buildFabAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required String heroTag,
    required int order,
  }) {
    return IgnorePointer(
      ignoring: !_isFabExpanded,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        opacity: _isFabExpanded ? 1 : 0,
        child: AnimatedSlide(
          duration: Duration(milliseconds: 180 + order * 40),
          curve: Curves.easeOutCubic,
          offset: _isFabExpanded ? Offset.zero : const Offset(0, 0.2),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 1,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(label),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  heroTag: heroTag,
                  tooltip: label,
                  onPressed: onPressed,
                  child: Icon(icon),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildFabAction(
          icon: Icons.refresh,
          label: '刷新',
          order: 1,
          heroTag: 'configs-page-refresh-fab',
          onPressed: () {
            _collapseFab();
            _reload();
          },
        ),
        _buildFabAction(
          icon: Icons.create_new_folder_outlined,
          label: '新建文件夹',
          order: 2,
          heroTag: 'configs-page-new-folder-fab',
          onPressed: () {
            _collapseFab();
            _createFolder();
          },
        ),
        _buildFabAction(
          icon: Icons.note_add_outlined,
          label: '新建文件',
          order: 3,
          heroTag: 'configs-page-new-file-fab',
          onPressed: () {
            _collapseFab();
            _createFile();
          },
        ),
        FloatingActionButton(
          heroTag: 'configs-page-main-fab',
          tooltip: _isFabExpanded ? '收起操作' : '更多操作',
          onPressed: _toggleFabExpanded,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 180),
            turns: _isFabExpanded ? 0.125 : 0,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<InstanceCatalogDirectoryView>(
      future: _viewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedView == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && _cachedView == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '加载失败: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reload, child: const Text('重试')),
              ],
            ),
          );
        }

        if (snapshot.hasData) {
          _cachedView = snapshot.data;
          _currentPath = snapshot.data?.currentPath;
        }

        final view = snapshot.data ?? _cachedView;
        if (view == null) {
          return const SizedBox.shrink();
        }

        final bottomInset = MediaQuery.of(context).padding.bottom;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPathBar(view, view.entries.length),
                  const SizedBox(height: 10),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: view.entries.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 120),
                                Icon(
                                  Icons.folder_open_outlined,
                                  size: 36,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    '当前目录为空。',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Card(
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              color: colorScheme.surfaceContainerLow,
                              surfaceTintColor: colorScheme.surfaceTint,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: view.entries.length,
                                separatorBuilder: (context, index) {
                                  return Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.45),
                                  );
                                },
                                itemBuilder: (context, index) {
                                  return _buildEntryTile(
                                    view.entries[index],
                                    view,
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isFabExpanded)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _collapseFab,
                  child: const SizedBox.shrink(),
                ),
              ),
            Positioned(
              right: 20,
              bottom: 20 + bottomInset,
              child: _buildExpandableFab(),
            ),
          ],
        );
      },
    );
  }
}

class _PathCrumb {
  final String label;
  final String path;

  const _PathCrumb({required this.label, required this.path});
}
