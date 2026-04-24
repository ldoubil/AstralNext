import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNodeInfo;

/// 增强的节点信息，包含自定义扩展字段
class EnhancedNodeInfo {
  final KVNodeInfo baseInfo;
  final int? avatarPort;
  final DateTime? lastAvatarPortScan;
  final Map<String, dynamic> metadata;

  EnhancedNodeInfo({
    required this.baseInfo,
    this.avatarPort,
    this.lastAvatarPortScan,
    this.metadata = const {},
  });

  factory EnhancedNodeInfo.fromKVNodeInfo(KVNodeInfo info) {
    return EnhancedNodeInfo(baseInfo: info);
  }

  EnhancedNodeInfo copyWith({
    KVNodeInfo? baseInfo,
    int? avatarPort,
    DateTime? lastAvatarPortScan,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedNodeInfo(
      baseInfo: baseInfo ?? this.baseInfo,
      avatarPort: avatarPort ?? this.avatarPort,
      lastAvatarPortScan: lastAvatarPortScan ?? this.lastAvatarPortScan,
      metadata: metadata ?? this.metadata,
    );
  }

  int get peerId => baseInfo.peerId;
  String get hostname => baseInfo.hostname;
  String get ipv4 => baseInfo.ipv4;
  bool get hasAvatarPort => avatarPort != null && avatarPort! > 0;
}
