import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNodeInfo;

/// 增强的节点信息，包含自定义扩展字段
class EnhancedNodeInfo {
  final KVNodeInfo baseInfo;
  final int? port;
  final int? avatarPort;
  final DateTime? lastAvatarPortScan;
  final Map<String, dynamic> metadata;
  final String? customName;
  final DateTime? lastNameFetch;

  EnhancedNodeInfo({
    required this.baseInfo,
    this.port,
    this.avatarPort,
    this.lastAvatarPortScan,
    this.metadata = const {},
    this.customName,
    this.lastNameFetch,
  });

  factory EnhancedNodeInfo.fromKVNodeInfo(KVNodeInfo info) {
    return EnhancedNodeInfo(baseInfo: info);
  }

  EnhancedNodeInfo copyWith({
    KVNodeInfo? baseInfo,
    int? port,
    int? avatarPort,
    DateTime? lastAvatarPortScan,
    Map<String, dynamic>? metadata,
    String? customName,
    DateTime? lastNameFetch,
  }) {
    return EnhancedNodeInfo(
      baseInfo: baseInfo ?? this.baseInfo,
      port: port ?? this.port,
      avatarPort: avatarPort ?? this.avatarPort,
      lastAvatarPortScan: lastAvatarPortScan ?? this.lastAvatarPortScan,
      metadata: metadata ?? this.metadata,
      customName: customName ?? this.customName,
      lastNameFetch: lastNameFetch ?? this.lastNameFetch,
    );
  }

  int get peerId => baseInfo.peerId;
  String get hostname => baseInfo.hostname;
  String get ipv4 => baseInfo.ipv4;
  bool get hasAvatarPort => avatarPort != null && avatarPort! > 0;
  String get displayName => customName ?? baseInfo.hostname;
}
