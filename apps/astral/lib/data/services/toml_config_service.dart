/// 可视化编辑器使用的 TOML 视图模型。
///
/// 该模型只覆盖当前 UI 暴露的核心配置项，不尝试完整表达所有 TOML 语法。
class VisualTomlConfig {

  final String instanceName;
  final String hostname;
  final bool dhcp;
  final String ipv4;
  final List<String> listeners;
  final String networkName;
  final String networkSecret;
  final List<String> peerUris;
  final String defaultProtocol;
  final String devName;
  final bool acceptDns;
  final bool enableKcpProxy;
  final bool enableQuicProxy;
  final bool disableP2p;
  final bool p2pOnly;

  const VisualTomlConfig({
    required this.instanceName,
    required this.hostname,
    required this.dhcp,
    required this.ipv4,
    required this.listeners,
    required this.networkName,
    required this.networkSecret,
    required this.peerUris,
    required this.defaultProtocol,
    required this.devName,
    required this.acceptDns,
    required this.enableKcpProxy,
    required this.enableQuicProxy,
    required this.disableP2p,
    required this.p2pOnly,
  });

  VisualTomlConfig copyWith({
    String? instanceName,
    String? hostname,
    bool? dhcp,
    String? ipv4,
    List<String>? listeners,
    String? networkName,
    String? networkSecret,
    List<String>? peerUris,
    String? defaultProtocol,
    String? devName,
    bool? acceptDns,
    bool? enableKcpProxy,
    bool? enableQuicProxy,
    bool? disableP2p,
    bool? p2pOnly,
  }) {
    return VisualTomlConfig(
      instanceName: instanceName ?? this.instanceName,
      hostname: hostname ?? this.hostname,
      dhcp: dhcp ?? this.dhcp,
      ipv4: ipv4 ?? this.ipv4,
      listeners: listeners ?? this.listeners,
      networkName: networkName ?? this.networkName,
      networkSecret: networkSecret ?? this.networkSecret,
      peerUris: peerUris ?? this.peerUris,
      defaultProtocol: defaultProtocol ?? this.defaultProtocol,
      devName: devName ?? this.devName,
      acceptDns: acceptDns ?? this.acceptDns,
      enableKcpProxy: enableKcpProxy ?? this.enableKcpProxy,
      enableQuicProxy: enableQuicProxy ?? this.enableQuicProxy,
      disableP2p: disableP2p ?? this.disableP2p,
      p2pOnly: p2pOnly ?? this.p2pOnly,
    );
  }
}

class TomlConfigService {
  static const String _defaultTemplate = '''
instance_name = "default"
#hostname = "" #用于更改当前主机在节点列表显示的名称
dhcp = true
#ipv4=""   #需将dhcp改为为false后取消ipv4前的注释并填写虚拟ip如100.100.100.1/24
listeners = [
    "tcp://0.0.0.0:0",
    "udp://0.0.0.0:0",
] #监听器用于接受连接

[network_identity]
network_name = "test" #网络名称
network_secret = "test" #网络密码

# 对等节点列表
[[peer]]
#uri = "" #需填写公共节点或自建节点

[flags]
default_protocol = "tcp" #连接到对等节点时使用的默认协议
dev_name = "astral" #astral将创建的虚拟网卡名称
#accept-dns = true #如果为true，则启用魔法DNS。可以使用域名访问其他节点，例如：hostname.et.net，hostname为节点列表显示的名称
#enable_kcp_proxy = true #使用kcp代理TCP流，提高在UDP丢包网络上的延迟和吞吐量
#enable_quic_proxy = true #使用quic代理TCP流，提高在UDP丢包网络上的延迟和吞吐量
#disable-p2p = true #禁用P2P通信，只通过peer配置项指定的节点转发数据包
#p2p_only = true #仅与已经建立P2P连接的对等节点通信
#更多配置和说明请参考https://easytier.cn/guide/network/configurations.html


''';

  String defaultToml() => _defaultTemplate;

  VisualTomlConfig defaultVisualConfig() => parseVisualConfig(_defaultTemplate);

  /// 从 TOML 文本提取可视化编辑器字段。
  ///
  /// 采用“宽容读取”策略：缺失或无法解析的字段回退到默认模板值，
  /// 以保证文本/可视化切换时功能稳定。
  VisualTomlConfig parseVisualConfig(String toml) {

    final fallback = _safeParseDefault();
    final listeners = _extractArray(toml, 'listeners');
    final peerUris = _extractPeerUris(toml);

    return VisualTomlConfig(
      instanceName: _extractString(toml, 'instance_name') ?? fallback.instanceName,
      hostname: _extractString(toml, 'hostname') ?? fallback.hostname,
      dhcp: _extractBool(toml, 'dhcp') ?? fallback.dhcp,
      ipv4: _extractString(toml, 'ipv4') ?? fallback.ipv4,
      listeners: listeners.isEmpty ? fallback.listeners : listeners,
      networkName: _extractString(toml, 'network_name') ?? fallback.networkName,
      networkSecret:
          _extractString(toml, 'network_secret') ?? fallback.networkSecret,
      peerUris: peerUris,
      defaultProtocol:
          _extractString(toml, 'default_protocol') ?? fallback.defaultProtocol,
      devName: _extractString(toml, 'dev_name') ?? fallback.devName,
      acceptDns: _extractBool(toml, 'accept-dns') ?? fallback.acceptDns,
      enableKcpProxy:
          _extractBool(toml, 'enable_kcp_proxy') ?? fallback.enableKcpProxy,
      enableQuicProxy:
          _extractBool(toml, 'enable_quic_proxy') ?? fallback.enableQuicProxy,
      disableP2p: _extractBool(toml, 'disable-p2p') ?? fallback.disableP2p,
      p2pOnly: _extractBool(toml, 'p2p_only') ?? fallback.p2pOnly,
    );
  }

  /// 将可视化模型编码为规范化 TOML 文本。
  ///
  /// 注意：未启用的布尔 flag 会以注释行写出，便于用户在文本模式中看到完整选项。
  String encodeVisualConfig(VisualTomlConfig config) {

    final hostnameLine = config.hostname.trim().isEmpty
        ? '#hostname = "" #用于更改当前主机在节点列表显示的名称'
        : 'hostname = "${_escapeString(config.hostname.trim())}" #用于更改当前主机在节点列表显示的名称';

    final ipv4Line = config.dhcp
        ? '#ipv4=""   #需将dhcp改为为false后取消ipv4前的注释并填写虚拟ip如100.100.100.1/24'
        : 'ipv4="${_escapeString(config.ipv4.trim())}"   #需将dhcp改为为false后取消ipv4前的注释并填写虚拟ip如100.100.100.1/24';

    final listenerLines = config.listeners
        .map((item) => '    "${_escapeString(item.trim())}",')
        .join('\n');

    final peerBlock = config.peerUris.isEmpty
        ? '[[peer]]\n#uri = "" #需填写公共节点或自建节点'
        : config.peerUris
              .map(
                (uri) =>
                    '[[peer]]\nuri = "${_escapeString(uri.trim())}" #需填写公共节点或自建节点',
              )
              .join('\n\n');

    return '''instance_name = "${_escapeString(config.instanceName.trim())}"
$hostnameLine
dhcp = ${config.dhcp}
$ipv4Line
listeners = [
$listenerLines
] #监听器用于接受连接

[network_identity]
network_name = "${_escapeString(config.networkName.trim())}" #网络名称
network_secret = "${_escapeString(config.networkSecret.trim())}" #网络密码

# 对等节点列表
$peerBlock

[flags]
default_protocol = "${_escapeString(config.defaultProtocol.trim())}" #连接到对等节点时使用的默认协议
dev_name = "${_escapeString(config.devName.trim())}" #astral将创建的虚拟网卡名称
${_encodeFlag(key: 'accept-dns', enabled: config.acceptDns, comment: '如果为true，则启用魔法DNS。可以使用域名访问其他节点，例如：hostname.et.net，hostname为节点列表显示的名称')}
${_encodeFlag(key: 'enable_kcp_proxy', enabled: config.enableKcpProxy, comment: '使用kcp代理TCP流，提高在UDP丢包网络上的延迟和吞吐量')}
${_encodeFlag(key: 'enable_quic_proxy', enabled: config.enableQuicProxy, comment: '使用quic代理TCP流，提高在UDP丢包网络上的延迟和吞吐量')}
${_encodeFlag(key: 'disable-p2p', enabled: config.disableP2p, comment: '禁用P2P通信，只通过peer配置项指定的节点转发数据包')}
${_encodeFlag(key: 'p2p_only', enabled: config.p2pOnly, comment: '仅与已经建立P2P连接的对等节点通信')}
#更多配置和说明请参考https://easytier.cn/guide/network/configurations.html
''';
  }

  VisualTomlConfig _safeParseDefault() {
    final listeners = _extractArray(_defaultTemplate, 'listeners');
    return VisualTomlConfig(
      instanceName: _extractString(_defaultTemplate, 'instance_name') ?? 'default',
      hostname: _extractString(_defaultTemplate, 'hostname') ?? '',
      dhcp: _extractBool(_defaultTemplate, 'dhcp') ?? true,
      ipv4: _extractString(_defaultTemplate, 'ipv4') ?? '',
      listeners: listeners.isEmpty ? const ['tcp://0.0.0.0:11010'] : listeners,
      networkName: _extractString(_defaultTemplate, 'network_name') ?? 'test',
      networkSecret: _extractString(_defaultTemplate, 'network_secret') ?? 'test',
      peerUris: _extractPeerUris(_defaultTemplate),
      defaultProtocol:
          _extractString(_defaultTemplate, 'default_protocol') ?? 'tcp',
      devName: _extractString(_defaultTemplate, 'dev_name') ?? 'astral',
      acceptDns: _extractBool(_defaultTemplate, 'accept-dns') ?? false,
      enableKcpProxy: _extractBool(_defaultTemplate, 'enable_kcp_proxy') ?? false,
      enableQuicProxy:
          _extractBool(_defaultTemplate, 'enable_quic_proxy') ?? false,
      disableP2p: _extractBool(_defaultTemplate, 'disable-p2p') ?? false,
      p2pOnly: _extractBool(_defaultTemplate, 'p2p_only') ?? false,
    );
  }

  /// 只匹配非注释行，避免将注释示例误识别为有效值。
  String? _extractString(String toml, String key) {

    final escapedKey = RegExp.escape(key);
    final pattern = RegExp(
      '^\\s*(?!#)$escapedKey\\s*=\\s*"([^"\\n]*)"',
      multiLine: true,
    );
    return pattern.firstMatch(toml)?.group(1);
  }


  bool? _extractBool(String toml, String key) {
    final escapedKey = RegExp.escape(key);
    final pattern = RegExp(
      '^\\s*(?!#)$escapedKey\\s*=\\s*(true|false)\\b',
      multiLine: true,
    );
    final value = pattern.firstMatch(toml)?.group(1);
    if (value == null) {
      return null;
    }
    return value == 'true';
  }


  /// 提取数组字段（如 listeners）。同样限制为非注释行起始。
  List<String> _extractArray(String toml, String key) {
    final escapedKey = RegExp.escape(key);
    final pattern = RegExp(
      '^\\s*(?!#)$escapedKey\\s*=\\s*\\[([\\s\\S]*?)\\]',
      multiLine: true,
    );

    final body = pattern.firstMatch(toml)?.group(1);
    if (body == null) {
      return const [];
    }
    return RegExp('"([^"\\n]+)"')
        .allMatches(body)
        .map((match) => match.group(1)!.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  /// 仅提取真实配置的 `uri`，忽略注释中的示例行。
  List<String> _extractPeerUris(String toml) {

    return RegExp('^\\s*(?!#)uri\\s*=\\s*"([^"\\n]+)"', multiLine: true)
        .allMatches(toml)
        .map((match) => match.group(1)!.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }


  /// flag 统一编码：开启时输出有效行，关闭时输出注释行。
  String _encodeFlag({

    required String key,
    required bool enabled,
    required String comment,
  }) {
    final line = '$key = true';
    return enabled ? '$line #$comment' : '#$line #$comment';
  }

  /// 将可视化改动合并回原始 TOML，仅覆盖受控字段，尽量保留用户额外配置。
  String mergeVisualConfigPreservingUnknown(String originalToml, VisualTomlConfig config) {
    var merged = originalToml;

    void replaceOrAppendLine({required String key, required String line}) {
      final escapedKey = RegExp.escape(key);
      final pattern = RegExp(
        '^\\s*#?\\s*$escapedKey\\s*=\\s*[^\\n\\r]*',
        multiLine: true,
      );
      if (pattern.hasMatch(merged)) {
        merged = merged.replaceFirst(pattern, line);
      } else {
        final suffix = merged.endsWith('\n') ? '' : '\n';
        merged = '$merged$suffix$line\n';
      }
    }

    final hostnameLine = config.hostname.trim().isEmpty
        ? '#hostname = "" #用于更改当前主机在节点列表显示的名称'
        : 'hostname = "${_escapeString(config.hostname.trim())}" #用于更改当前主机在节点列表显示的名称';
    final ipv4Line = config.dhcp
        ? '#ipv4=""   #需将dhcp改为为false后取消ipv4前的注释并填写虚拟ip如100.100.100.1/24'
        : 'ipv4="${_escapeString(config.ipv4.trim())}"   #需将dhcp改为为false后取消ipv4前的注释并填写虚拟ip如100.100.100.1/24';

    replaceOrAppendLine(
      key: 'instance_name',
      line: 'instance_name = "${_escapeString(config.instanceName.trim())}"',
    );
    replaceOrAppendLine(key: 'hostname', line: hostnameLine);
    replaceOrAppendLine(key: 'dhcp', line: 'dhcp = ${config.dhcp}');
    replaceOrAppendLine(key: 'ipv4', line: ipv4Line);
    replaceOrAppendLine(
      key: 'network_name',
      line: 'network_name = "${_escapeString(config.networkName.trim())}" #网络名称',
    );
    replaceOrAppendLine(
      key: 'network_secret',
      line: 'network_secret = "${_escapeString(config.networkSecret.trim())}" #网络密码',
    );

    final listenerLines = config.listeners
        .map((item) => '    "${_escapeString(item.trim())}",')
        .join('\n');
    final listenersBlock = 'listeners = [\n$listenerLines\n] #监听器用于接受连接';
    final listenersPattern = RegExp(
      '^\\s*listeners\\s*=\\s*\\[[\\s\\S]*?\\](?:\\s*#.*)?',
      multiLine: true,
    );
    if (listenersPattern.hasMatch(merged)) {
      merged = merged.replaceFirst(listenersPattern, listenersBlock);
    } else {
      final suffix = merged.endsWith('\n') ? '' : '\n';
      merged = '$merged$suffix$listenersBlock\n';
    }

    final peerBlock = config.peerUris.isEmpty
        ? '[[peer]]\n#uri = "" #需填写公共节点或自建节点'
        : config.peerUris
              .map(
                (uri) =>
                    '[[peer]]\nuri = "${_escapeString(uri.trim())}" #需填写公共节点或自建节点',
              )
              .join('\n\n');

    // 只替换 [[peer]] 条目本身，避免误覆盖用户在其它区域添加的自定义参数。
    final peerEntryPattern = RegExp(
      '^\\s*\\[\\[peer\\]\\]\\s*\\r?\\n(?:\\s*#?\\s*uri\\s*=.*\\r?\\n)?',
      multiLine: true,
    );
    merged = merged.replaceAll(peerEntryPattern, '');

    final peerHeaderPattern = RegExp(r'^\s*#\s*对等节点列表\s*$', multiLine: true);

    final peerInsert = '$peerBlock\n\n';
    if (peerHeaderPattern.hasMatch(merged)) {
      merged = merged.replaceFirstMapped(
        peerHeaderPattern,
        (match) => '${match.group(0)}\n$peerInsert',
      );
    } else {
      final flagsPattern = RegExp('^\\s*\\[flags\\]', multiLine: true);
      final flagsMatch = flagsPattern.firstMatch(merged);
      final peerSection = '# 对等节点列表\n$peerInsert';
      if (flagsMatch != null) {
        merged =
            '${merged.substring(0, flagsMatch.start)}$peerSection${merged.substring(flagsMatch.start)}';
      } else {
        final suffix = merged.endsWith('\n') ? '' : '\n';
        merged = '$merged$suffix$peerSection';
      }
    }


    replaceOrAppendLine(
      key: 'default_protocol',
      line:
          'default_protocol = "${_escapeString(config.defaultProtocol.trim())}" #连接到对等节点时使用的默认协议',
    );
    replaceOrAppendLine(
      key: 'dev_name',
      line: 'dev_name = "${_escapeString(config.devName.trim())}" #astral将创建的虚拟网卡名称',
    );
    replaceOrAppendLine(
      key: 'accept-dns',
      line: _encodeFlag(
        key: 'accept-dns',
        enabled: config.acceptDns,
        comment: '如果为true，则启用魔法DNS。可以使用域名访问其他节点，例如：hostname.et.net，hostname为节点列表显示的名称',
      ),
    );
    replaceOrAppendLine(
      key: 'enable_kcp_proxy',
      line: _encodeFlag(
        key: 'enable_kcp_proxy',
        enabled: config.enableKcpProxy,
        comment: '使用kcp代理TCP流，提高在UDP丢包网络上的延迟和吞吐量',
      ),
    );
    replaceOrAppendLine(
      key: 'enable_quic_proxy',
      line: _encodeFlag(
        key: 'enable_quic_proxy',
        enabled: config.enableQuicProxy,
        comment: '使用quic代理TCP流，提高在UDP丢包网络上的延迟和吞吐量',
      ),
    );
    replaceOrAppendLine(
      key: 'disable-p2p',
      line: _encodeFlag(
        key: 'disable-p2p',
        enabled: config.disableP2p,
        comment: '禁用P2P通信，只通过peer配置项指定的节点转发数据包',
      ),
    );
    replaceOrAppendLine(
      key: 'p2p_only',
      line: _encodeFlag(
        key: 'p2p_only',
        enabled: config.p2pOnly,
        comment: '仅与已经建立P2P连接的对等节点通信',
      ),
    );

    return merged;
  }


  String _escapeString(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  }
}

