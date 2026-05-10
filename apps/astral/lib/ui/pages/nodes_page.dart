
import 'dart:async';
import 'dart:io';

import 'package:astral/data/services/platform_path_service.dart';
import 'package:astral/data/services/toml_config_service.dart';
import 'package:astral/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:highlight/highlight_core.dart';

class NodesPage extends StatefulWidget {
  const NodesPage({super.key});

  @override
  State<NodesPage> createState() => _NodesPageState();
}

class _NodesPageState extends State<NodesPage> {
  Future<_Snapshot>? _snapshotFuture;
  _Snapshot? _cachedSnapshot;
  final Map<String, DateTime> _runningByPath = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reload();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _runningByPath.isNotEmpty) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
  }

  Future<void> _refresh() async {
    final future = _loadSnapshot();
    setState(() {
      _snapshotFuture = future;
    });
    await future;
  }

  Future<_Snapshot> _loadSnapshot() async {
    final configDir = await getIt<PlatformPathService>().configDir();
    final srcDir = Directory('${configDir.path}${Platform.pathSeparator}src');
    if (!await srcDir.exists()) {
      await srcDir.create(recursive: true);
    }

    final items = <_Item>[];
    await for (final entity in srcDir.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.toml')) {
        continue;
      }
      items.add(await _buildItem(srcDir.path, entity));
    }

    items.sort((a, b) => a.relativePath.toLowerCase().compareTo(b.relativePath.toLowerCase()));
    return _Snapshot(rootPath: srcDir.path, items: items);
  }

  Future<_Item> _buildItem(String rootPath, File file) async {
    final displayName = _basename(file.path).replaceAll('.toml', '');

    return _Item(
      path: file.path,
      name: displayName,
      fileName: _basename(file.path),
      relativePath: _relativePath(rootPath, file.path),
    );
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index == -1 ? normalized : normalized.substring(index + 1);
  }

  String _relativePath(String rootPath, String fullPath) {
    final root = rootPath.replaceAll('\\', '/');
    final full = fullPath.replaceAll('\\', '/');
    if (full.startsWith('$root/')) {
      return full.substring(root.length + 1);
    }
    return fullPath;
  }

  bool _isValidName(String name) {
    return !name.contains('/') && !name.contains('\\');
  }

  String _ensureTomlName(String name) {
    return name.toLowerCase().endsWith('.toml') ? name : '$name.toml';
  }

  void _showMessage(BuildContext context, String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _promptForName(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建实例'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入实例名称'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = result?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> _createInstance(BuildContext context, String rootPath) async {
    final name = await _promptForName(context);
    if (!context.mounted) {
      return;
    }
    if (name == null) {
      return;
    }
    if (!_isValidName(name)) {
      _showMessage(context, '实例名不能包含路径分隔符');
      return;
    }

    final fileName = _ensureTomlName(name);
    final filePath = '$rootPath${Platform.pathSeparator}$fileName';
    final file = File(filePath);
    if (await file.exists()) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, '实例已存在');
      return;
    }

    await file.create(recursive: true);
    final template = getIt<TomlConfigService>().defaultToml();
    await file.writeAsString(template);

    if (!context.mounted) {
      return;
    }
    await _refresh();
    if (!context.mounted) {
      return;
    }
    await _openEditor(context, filePath);
  }

  Future<void> _openEditor(BuildContext context, String path) async {
    final file = File(path);
    if (!await file.exists()) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, '配置文件不存在');
      return;
    }

    final initial = await file.readAsString();
    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CodeEditorPage(path: path, initialText: initial),
      ),
    );

    if (!context.mounted) {
      return;
    }
    _reload();
  }

  void _toggleRun(BuildContext context, _Item item) {
    if (_runningByPath.containsKey(item.path)) {
      setState(() {
        _runningByPath.remove(item.path);
      });
      _showMessage(context, '已关闭：${item.name}');
      return;
    }

    setState(() {
      _runningByPath[item.path] = DateTime.now();
    });
    _showMessage(context, '已启动：${item.name}');
  }

    String _formatUptime(DateTime startedAt) {
    final duration = DateTime.now().difference(startedAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  int _resolveColumns(double width) {
    if (width >= 1400) {
      return 4;
    }
    if (width >= 1000) {
      return 3;
    }
    if (width >= 680) {
      return 2;
    }
    return 1;
  }

  Widget _buildCard(BuildContext context, _Item item) {
    final startedAt = _runningByPath[item.path];
    final isRunning = startedAt != null;

    return _NodeCard(
      item: item,
      isRunning: isRunning,
      startedAt: startedAt,
      formatUptime: _formatUptime,
      onToggleRun: () => _toggleRun(context, item),
      onOpenEditor: () => _openEditor(context, item.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<_Snapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _cachedSnapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && _cachedSnapshot == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('加载失败：${snapshot.error}', style: TextStyle(color: colorScheme.error)),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reload, child: const Text('重试')),
              ],
            ),
          );
        }

        if (snapshot.hasData) {
          _cachedSnapshot = snapshot.data;
        }
        final data = snapshot.data ?? _cachedSnapshot;
        if (data == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '实例列表',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${data.items.length} 个实例',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: '刷新',
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _createInstance(context, data.rootPath),
                    icon: const Icon(Icons.add),
                    label: const Text('新建实例'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: data.items.isEmpty
                      ? ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            const SizedBox(height: 140),
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 36,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                '还没有实例配置，请先创建',
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 10.0;
                            final columns = _resolveColumns(constraints.maxWidth);
                            final tileWidth =
                                (constraints.maxWidth - (columns - 1) * spacing) / columns;
                            final ratio = (tileWidth / 112).clamp(2.2, 6.0);

                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                childAspectRatio: ratio,
                              ),
                              itemCount: data.items.length,
                              itemBuilder: (context, index) {
                                return _buildCard(context, data.items[index]);
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CodeEditorPage extends StatefulWidget {
  final String path;
  final String initialText;

  const _CodeEditorPage({
    required this.path,
    required this.initialText,
  });

  @override
  State<_CodeEditorPage> createState() => _CodeEditorPageState();
}

class _CodeEditorPageState extends State<_CodeEditorPage> {
  late final _TomlCodeController _controller;
  late String _savedText;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = _TomlCodeController(
      completions: _completionItems,
      text: widget.initialText,
      language: _tomlMode,
    );
    _savedText = widget.initialText;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _dirty => _controller.fullText != _savedText;

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index == -1 ? normalized : normalized.substring(index + 1);
  }

  Future<void> _save() async {
    if (_isSaving || !_dirty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final text = _controller.fullText;
      await File(widget.path).writeAsString(text);
      if (!mounted) {
        return;
      }
      setState(() {
        _savedText = text;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlightTheme = _buildTomlTheme(colorScheme, Theme.of(context).brightness);

    return Scaffold(
      appBar: AppBar(
        title: Text('代码编辑窗口 - ${_basename(widget.path)}'),
        actions: [
          if (_dirty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '未保存',
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ),
            ),
          IconButton(
            tooltip: '保存',
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Card(
              margin: EdgeInsets.zero,
              surfaceTintColor: colorScheme.surfaceTint,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.code, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                surfaceTintColor: colorScheme.surfaceTint,
                child: CodeTheme(
                  data: CodeThemeData(styles: highlightTheme),
                  child: CodeField(
                    controller: _controller,
                    expands: true,
                    wrap: true,
                    gutterStyle: _editorGutterStyle,
                    padding: const EdgeInsets.all(12),
                    textStyle: _editorTextStyle,
                    background: colorScheme.surfaceContainerHighest,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Snapshot {
  final String rootPath;
  final List<_Item> items;

  const _Snapshot({required this.rootPath, required this.items});
}

class _Item {
  final String path;
  final String name;
  final String fileName;
  final String relativePath;

  const _Item({
    required this.path,
    required this.name,
    required this.fileName,
    required this.relativePath,
  });
}

enum _CardAction { edit }

final Mode _tomlMode = Mode(
  contains: [
    Mode(className: 'comment', begin: r'#', end: r'$'),
    Mode(className: 'section', begin: r'\[', end: r'\]'),
    Mode(
      className: 'string',
      variants: [
        Mode(begin: r'"""', end: r'"""', relevance: 10),
        Mode(begin: "'''", end: "'''", relevance: 10),
        Mode(begin: '"', end: '"'),
        Mode(begin: "'", end: "'"),
      ],
    ),
    Mode(className: 'literal', begin: r'\b(true|false)\b'),
    Mode(className: 'number', begin: r'\b\d+(?:\.\d+)?\b'),
    Mode(
      className: 'attr',
      begin: r'[A-Za-z_][A-Za-z0-9_\.-]*\s*=',
      relevance: 0,
    ),
  ],
);

const _completionItems = [
  _TomlCompletion(key: 'network_name', zh: '网络名称', insertText: 'network_name'),
  _TomlCompletion(key: 'network_secret', zh: '网络密钥', insertText: 'network_secret'),
  _TomlCompletion(key: 'listeners', zh: '监听地址', insertText: 'listeners'),
  _TomlCompletion(key: 'hostname', zh: '主机名', insertText: 'hostname'),
  _TomlCompletion(key: 'ipv4', zh: 'IPv4 地址', insertText: 'ipv4'),
  _TomlCompletion(key: 'dhcp', zh: 'DHCP 开关', insertText: 'dhcp'),
  _TomlCompletion(key: 'peer', zh: '对等节点', insertText: 'peer'),
];

const _editorGutterStyle = GutterStyle.none;
const _editorTextStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 13,
  height: 1.4,
);

Map<String, TextStyle> _buildTomlTheme(ColorScheme colorScheme, Brightness brightness) {
  final base = brightness == Brightness.dark ? a11yDarkTheme : a11yLightTheme;
  final keyStyle = TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600);
  return {
    ...base,
    'attr': keyStyle,
    'section': keyStyle,
  };
}

class _TomlCodeController extends CodeController {
  final List<_TomlCompletion> completions;
  final Map<String, String> _insertByLabel = {};

  _TomlCodeController({
    required this.completions,
    required super.text,
    required super.language,
  });

  @override
  Future<void> generateSuggestions() async {
    if (!value.selection.isCollapsed) {
      popupController.hide();
      return;
    }

    final prefix = value.wordToCursor;
    if (prefix == null || prefix.isEmpty) {
      popupController.hide();
      return;
    }

    final matches = completions.where((item) => item.key.startsWith(prefix)).toList(growable: false);
    if (matches.isEmpty) {
      popupController.hide();
      return;
    }

    _insertByLabel.clear();
    final suggestions = matches.map((item) {
      final label = '${item.key}  ${item.zh}';
      _insertByLabel[label] = item.insertText;
      return label;
    }).toList(growable: false);

    popupController.show(suggestions);
  }

  @override
  void insertSelectedWord() {
    final previousSelection = selection;
    final selectedWord = popupController.getSelectedWord();
    final insertText = _insertByLabel[selectedWord] ?? selectedWord;
    final cursorPosition = previousSelection.baseOffset;
    var startPosition = value.wordAtCursorStart;
    var currentWord = value.wordAtCursor;

    if (cursorPosition < 0) {
      popupController.hide();
      return;
    }

    if (startPosition == null || currentWord == null) {
      startPosition = cursorPosition;
      currentWord = '';
    }

    final endReplacingPosition = startPosition + currentWord.length;
    final endSelectionPosition = startPosition + insertText.length;

    var additionalSpaceIfEnd = '';
    var offsetIfEndsWithSpace = insertText.contains('\n') ? 0 : 1;
    if (!insertText.contains('\n')) {
      if (text.length < endReplacingPosition + 1) {
        additionalSpaceIfEnd = ' ';
      } else {
        final charAfterText = text[endReplacingPosition];
        if (charAfterText != ' ' && !_isAsciiLetterOrDigit(charAfterText)) {
          offsetIfEndsWithSpace = 0;
        }
      }
    }

    final replacedText = text.replaceRange(
      startPosition,
      endReplacingPosition,
      '$insertText$additionalSpaceIfEnd',
    );

    final adjustedSelection = previousSelection.copyWith(
      baseOffset: endSelectionPosition + offsetIfEndsWithSpace,
      extentOffset: endSelectionPosition + offsetIfEndsWithSpace,
    );

    value = TextEditingValue(text: replacedText, selection: adjustedSelection);
    popupController.hide();
  }
}

class _TomlCompletion {
  final String key;
  final String zh;
  final String insertText;

  const _TomlCompletion({
    required this.key,
    required this.zh,
    required this.insertText,
  });
}

bool _isAsciiLetterOrDigit(String value) {
  if (value.isEmpty) {
    return false;
  }
  final code = value.codeUnitAt(0);
  return (code >= 48 && code <= 57) || (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
}

class _NodeCard extends StatefulWidget {
  final _Item item;
  final VoidCallback onToggleRun;
  final VoidCallback onOpenEditor;
  final bool isRunning;
  final DateTime? startedAt;
  final String Function(DateTime) formatUptime;

  const _NodeCard({
    required this.item,
    required this.onToggleRun,
    required this.onOpenEditor,
    required this.isRunning,
    this.startedAt,
    required this.formatUptime,
  });

  @override
  State<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<_NodeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = widget.isRunning
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: widget.isRunning ? 1 : 0,
        margin: EdgeInsets.zero,
        color: widget.isRunning
            ? colorScheme.primaryContainer.withValues(alpha: 0.28)
            : colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: (_isHovered || widget.isRunning)
                ? colorScheme.primary.withValues(alpha: 0.45)
                : colorScheme.outlineVariant.withValues(alpha: 0),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.developer_board_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  PopupMenuButton<_CardAction>(
                    tooltip: '更多操作',
                    iconSize: 18,
                    onSelected: (value) {
                      if (value == _CardAction.edit) {
                        widget.onOpenEditor();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _CardAction.edit,
                        child: Text('编辑代码'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.item.relativePath,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    widget.isRunning ? '运行中' : '未运行',
                    style: TextStyle(color: statusColor, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.item.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isRunning ? '运行时长 ${widget.startedAt != null ? widget.formatUptime(widget.startedAt!) : ''}' : '可直接启动',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: widget.onToggleRun,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    icon: Icon(widget.isRunning ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                    label: Text(widget.isRunning ? '关闭' : '启动'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
