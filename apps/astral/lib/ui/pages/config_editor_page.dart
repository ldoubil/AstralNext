import 'dart:io';

import 'package:astral/data/services/app_settings_service.dart';
import 'package:astral/data/services/toml_config_service.dart';
import 'package:astral/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:highlight/highlight_core.dart';

enum _EditorPane { visual, text }

class ConfigEditorPage extends StatefulWidget {
  final String path;

  const ConfigEditorPage({super.key, required this.path});

  @override
  State<ConfigEditorPage> createState() => _ConfigEditorPageState();
}

class _ConfigEditorPageState extends State<ConfigEditorPage> {
  static final Mode _tomlMode = Mode(
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

  static const List<String> _protocolOptions = ['tcp', 'udp', 'quic', 'kcp', 'wg'];

  late final TomlConfigService _tomlService;
  late final AppSettingsService _settingsService;
  late final CodeController _textController;
  late final TextEditingController _instanceNameController;
  late final TextEditingController _hostnameController;
  late final TextEditingController _ipv4Controller;
  late final TextEditingController _networkNameController;
  late final TextEditingController _networkSecretController;
  late final TextEditingController _devNameController;

  List<TextEditingController> _listenerControllers = [];
  List<TextEditingController> _peerControllers = [];

  String _savedText = '';
  bool _dhcp = true;
  bool _acceptDns = false;
  bool _enableKcpProxy = false;
  bool _enableQuicProxy = false;
  bool _disableP2p = false;
  bool _p2pOnly = false;
  String _defaultProtocol = 'tcp';
  bool _isLoading = true;
  bool _isSaving = false;
  // 进入可视化模式前的原始文本快照，用于“无可视化改动时”回切文本模式。
  String? _textSnapshotForRoundTrip;
  // 文本快照对应的可视化标准编码，用于判断可视化侧是否真的发生变更。
  String? _visualBaselineEncodedFromText;

  _EditorPane _pane = _EditorPane.visual;


  @override
  void initState() {
    super.initState();
    _tomlService = getIt<TomlConfigService>();
    _settingsService = getIt<AppSettingsService>();
    _textController = CodeController(text: '', language: _tomlMode);
    _instanceNameController = TextEditingController();
    _hostnameController = TextEditingController();
    _ipv4Controller = TextEditingController();
    _networkNameController = TextEditingController();
    _networkSecretController = TextEditingController();
    _devNameController = TextEditingController();
    _pane = _settingsService.getEditorDefaultMode() == ConfigEditorDefaultMode.text
        ? _EditorPane.text
        : _EditorPane.visual;
    _load();
  }

  @override
  void dispose() {
    _textController.dispose();
    _instanceNameController.dispose();
    _hostnameController.dispose();
    _ipv4Controller.dispose();
    _networkNameController.dispose();
    _networkSecretController.dispose();
    _devNameController.dispose();
    for (final controller in _listenerControllers) {
      controller.dispose();
    }
    for (final controller in _peerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _fileName {
    final normalized = widget.path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index == -1 ? normalized : normalized.substring(index + 1);
  }

  bool get _dirty {
    if (_pane == _EditorPane.text) {
      return _textController.fullText != _savedText;
    }
    // 可视化模式仅比较“受控字段基线”，避免未建模文本字段导致误报未保存。
    final baseline = _visualBaselineEncodedFromText;
    if (baseline == null) return true;
    return _tomlService.encodeVisualConfig(_collectVisualConfig()) != baseline;
  }


  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final text = await File(widget.path).readAsString();
      _savedText = text;
      _textController.fullText = text;
      _textController.setCursor(text.length);
      final parsed = _tomlService.parseVisualConfig(text);
      _textSnapshotForRoundTrip = text;
      _visualBaselineEncodedFromText = _tomlService.encodeVisualConfig(parsed);
      _applyVisualConfig(parsed);


    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载失败: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyVisualConfig(VisualTomlConfig config) {
    _instanceNameController.text = config.instanceName;
    _hostnameController.text = config.hostname;
    _dhcp = config.dhcp;
    _ipv4Controller.text = config.ipv4;
    _networkNameController.text = config.networkName;
    _networkSecretController.text = config.networkSecret;
    _devNameController.text = config.devName;
    _defaultProtocol = config.defaultProtocol.trim().isEmpty ? 'tcp' : config.defaultProtocol;
    _acceptDns = config.acceptDns;
    _enableKcpProxy = config.enableKcpProxy;
    _enableQuicProxy = config.enableQuicProxy;
    _disableP2p = config.disableP2p;
    _p2pOnly = config.p2pOnly;

    for (final controller in _listenerControllers) {
      controller.dispose();
    }
    for (final controller in _peerControllers) {
      controller.dispose();
    }

    final listeners = config.listeners.isEmpty
        ? <String>['tcp://0.0.0.0:11010']
        : config.listeners;
    _listenerControllers = listeners
        .map((item) => TextEditingController(text: item))
        .toList(growable: true);

    _peerControllers = config.peerUris
        .map((item) => TextEditingController(text: item))
        .toList(growable: true);
  }

  VisualTomlConfig _collectVisualConfig() {
    final listeners = _listenerControllers
        .map((item) => item.text.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final peers = _peerControllers
        .map((item) => item.text.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    return VisualTomlConfig(
      instanceName: _instanceNameController.text.trim(),
      hostname: _hostnameController.text.trim(),
      dhcp: _dhcp,
      ipv4: _ipv4Controller.text.trim(),
      listeners: listeners,
      networkName: _networkNameController.text.trim(),
      networkSecret: _networkSecretController.text.trim(),
      peerUris: peers,
      defaultProtocol: _defaultProtocol.trim(),
      devName: _devNameController.text.trim(),
      acceptDns: _acceptDns,
      enableKcpProxy: _enableKcpProxy,
      enableQuicProxy: _enableQuicProxy,
      disableP2p: _disableP2p,
      p2pOnly: _p2pOnly,
    );
  }

  String? _validateVisual(VisualTomlConfig config) {
    if (config.instanceName.isEmpty) return '实例名称不能为空。';
    if (config.networkName.isEmpty) return '网络名称不能为空。';
    if (config.networkSecret.isEmpty) return '网络密码不能为空。';
    if (config.listeners.isEmpty) return '至少需要一个监听地址。';
    if (!config.dhcp && config.ipv4.isEmpty) return '关闭 DHCP 后必须填写 IPv4。';
    return null;

  }

  Future<void> _switchPane(_EditorPane pane) async {
    if (_pane == pane || _isLoading || _isSaving) return;

    if (pane == _EditorPane.visual) {
      try {
        final textSnapshot = _textController.fullText;
        final parsed = _tomlService.parseVisualConfig(textSnapshot);
        _textSnapshotForRoundTrip = textSnapshot;
        _visualBaselineEncodedFromText = _tomlService.encodeVisualConfig(parsed);
        _applyVisualConfig(parsed);
      } catch (error) {

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('文本解析失败: $error')));
        return;
      }
    } else {
      final visual = _collectVisualConfig();
      final error = _validateVisual(visual);
      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      final generated = _tomlService.encodeVisualConfig(visual);
      // 若可视化侧没有实际改动，则恢复原始文本，避免不必要的格式变化。
      final hasVisualChanges = _visualBaselineEncodedFromText != null

          ? generated != _visualBaselineEncodedFromText
          : true;

      final nextText = (!hasVisualChanges && _textSnapshotForRoundTrip != null)
          ? _textSnapshotForRoundTrip!
          : generated;

      _textController.fullText = nextText;
      _textController.setCursor(nextText.length);
    }


    setState(() => _pane = pane);
  }

  Future<void> _save() async {
    if (_isSaving || !_dirty) return;

    setState(() => _isSaving = true);
    try {
      late final String text;
      if (_pane == _EditorPane.text) {
        text = _textController.fullText;
      } else {
        final visual = _collectVisualConfig();
        final error = _validateVisual(visual);
        if (error != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
          return;
        }
        // 可视化保存时仅覆盖受控字段，保留文本中的额外配置内容。
        // 始终以最新已保存文本为基底合并，确保额外自定义参数不被旧快照覆盖。
        text = _tomlService.mergeVisualConfigPreservingUnknown(_savedText, visual);


      }

      await File(widget.path).writeAsString(text);
      if (!mounted) return;
      _savedText = text;
      _textSnapshotForRoundTrip = text;
      _visualBaselineEncodedFromText = _tomlService.encodeVisualConfig(
        _tomlService.parseVisualConfig(text),
      );

      if (_pane == _EditorPane.visual) {
        _textController.fullText = text;
        _textController.setCursor(text.length);
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功。')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }


  Map<String, TextStyle> _buildTomlTheme(ColorScheme colorScheme, Brightness brightness) {
    final base = brightness == Brightness.dark ? a11yDarkTheme : a11yLightTheme;
    final keyStyle = TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600);
    return {...base, 'attr': keyStyle, 'section': keyStyle};
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ?? const SizedBox.shrink(),


              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildListEditor({
    required String emptyHint,
    required List<TextEditingController> controllers,
    required String Function(int index) labelBuilder,
    required VoidCallback onAdd,
    required void Function(int index) onDelete,
    required String addLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (controllers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              emptyHint,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
        for (var i = 0; i < controllers.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers[i],
                  decoration: _fieldDecoration(label: labelBuilder(i)),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '删除',
                onPressed: () => onDelete(i),
                icon: const Icon(Icons.remove),
              ),
            ],
          ),
          if (i != controllers.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildFlagSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildFlagValueRow(
      title: title,
      subtitle: subtitle,
      control: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildFlagValueRow({
    required String title,
    required String subtitle,
    required Widget control,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          control,
        ],
      ),
    );
  }

  Widget _buildVisualEditor() {

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _buildSectionCard(
          title: '基础配置',
          subtitle: '实例标识、地址分配与主机名',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _instanceNameController,
                      decoration: _fieldDecoration(
                        label: '实例名称（instance_name）',
                        hint: 'default',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _hostnameController,
                      decoration: _fieldDecoration(
                        label: '主机名（hostname）',
                        hint: '可选',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildFlagSwitchRow(
                title: '启用 DHCP',
                subtitle: '自动分配虚拟地址。关闭后手动输入 IPv4。',
                value: _dhcp,
                onChanged: (value) => setState(() => _dhcp = value),
              ),

              if (!_dhcp) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _ipv4Controller,
                  decoration: _fieldDecoration(
                    label: 'IPv4/CIDR（ipv4）',
                    hint: '100.100.100.1/24',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: '网络身份',
          subtitle: '身份凭据与网络加入参数',
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _networkNameController,
                  decoration: _fieldDecoration(label: '网络名称（network_name）'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _networkSecretController,
                  decoration: _fieldDecoration(label: '网络密码（network_secret）'),
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: '监听器',
          subtitle: '本地监听地址列表（listeners）',
          child: _buildListEditor(
            emptyHint: '请至少添加一个监听地址。',
            controllers: _listenerControllers,
            labelBuilder: (index) => '监听地址 ${index + 1}',
            onAdd: () {
              _listenerControllers.add(TextEditingController());
              setState(() {});
            },
            onDelete: (index) {
              if (_listenerControllers.length <= 1) return;
              final target = _listenerControllers.removeAt(index);
              target.dispose();
              setState(() {});
            },
            addLabel: '新增监听器',
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: '对等节点',
          subtitle: '手动指定 peer 节点（[[peer]].uri）',
          child: _buildListEditor(
            emptyHint: '可选：未设置时将仅使用默认发现方式。',
            controllers: _peerControllers,
            labelBuilder: (index) => 'Peer URI ${index + 1}',
            onAdd: () {
              _peerControllers.add(TextEditingController());
              setState(() {});
            },
            onDelete: (index) {
              final target = _peerControllers.removeAt(index);
              target.dispose();
              setState(() {});
            },
            addLabel: '新增 Peer',
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: 'FLAGS 高级选项',
          subtitle: '左侧参数说明，右侧控件（下拉 / 开关）',
          child: Column(
            children: [
              _buildFlagValueRow(
                title: 'default_protocol',
                subtitle: '默认连接协议',
                control: SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: _protocolOptions.contains(_defaultProtocol)
                        ? _defaultProtocol
                        : _protocolOptions.first,
                    items: _protocolOptions
                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _defaultProtocol = value);
                    },
                    decoration: _fieldDecoration(label: '协议'),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              _buildFlagValueRow(
                title: 'dev_name',
                subtitle: '虚拟网卡名称',
                control: SizedBox(
                  width: 180,
                  child: TextFormField(
                    controller: _devNameController,
                    decoration: _fieldDecoration(label: '网卡名'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              _buildFlagSwitchRow(
                title: 'accept-dns',
                subtitle: '启用魔法 DNS，可使用 hostname.et.net。',
                value: _acceptDns,
                onChanged: (value) => setState(() => _acceptDns = value),
              ),
              const SizedBox(height: 8),
              _buildFlagSwitchRow(
                title: 'enable_kcp_proxy',
                subtitle: 'UDP 丢包场景下提升 TCP 延迟与吞吐。',
                value: _enableKcpProxy,
                onChanged: (value) => setState(() => _enableKcpProxy = value),
              ),
              const SizedBox(height: 8),
              _buildFlagSwitchRow(
                title: 'enable_quic_proxy',
                subtitle: '使用 QUIC 代理 TCP 流。',
                value: _enableQuicProxy,
                onChanged: (value) => setState(() => _enableQuicProxy = value),
              ),
              const SizedBox(height: 8),
              _buildFlagSwitchRow(
                title: 'disable-p2p',
                subtitle: '禁用 P2P，仅通过配置的 peer 转发。',
                value: _disableP2p,
                onChanged: (value) {
                  // 两个选项语义互斥：禁用 P2P 时不允许同时仅 P2P。
                  setState(() {
                    _disableP2p = value;
                    if (value) {
                      _p2pOnly = false;
                    }
                  });
                },

              ),
              const SizedBox(height: 8),
              _buildFlagSwitchRow(
                title: 'p2p_only',
                subtitle: '只与已建立 P2P 的节点通信。',
                value: _p2pOnly,
                onChanged: (value) {
                  // 两个选项语义互斥：仅 P2P 时不能再标记禁用 P2P。
                  setState(() {
                    _p2pOnly = value;
                    if (value) {
                      _disableP2p = false;
                    }
                  });
                },

              ),

            ],
          ),
        ),

      ],
    );
  }

  Widget _buildTextEditor(ColorScheme colorScheme) {
    final highlightTheme = _buildTomlTheme(colorScheme, Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CodeTheme(
          data: CodeThemeData(styles: highlightTheme),
          child: CodeField(
            controller: _textController,
            expands: true,
            wrap: true,
            gutterStyle: GutterStyle.none,
            padding: const EdgeInsets.all(12),
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4),
            background: colorScheme.surfaceContainerHighest,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<_EditorPane>(
              segments: const [
                ButtonSegment<_EditorPane>(value: _EditorPane.visual, label: Text('可视化')),
                ButtonSegment<_EditorPane>(value: _EditorPane.text, label: Text('文本')),
              ],
              selected: {_pane},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                _switchPane(selection.first);
              },
            ),
          ),
          if (_dirty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text('未保存', style: TextStyle(color: colorScheme.error, fontSize: 12)),
              ),
            ),
          IconButton(
            tooltip: '保存',
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    widget.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _pane == _EditorPane.visual
                      ? _buildVisualEditor()
                      : _buildTextEditor(colorScheme),
                ),
              ],
            ),
    );
  }
}
