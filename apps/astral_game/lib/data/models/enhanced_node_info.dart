import 'dart:typed_data';

import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNodeInfo;

/// 增强的节点信息：在 EasyTier 提供的 [`KVNodeInfo`] 基础上，叠加一份由
/// peer-RPC（`user.getInfo` channel）拿回来的"业务资料"——昵称与头像。
///
/// 历史上还存在 `port` / `avatarPort` / `lastNameFetch` 等字段，那是 HTTP
/// JSON-RPC 时代用来"独立扫描每个节点的 RPC 端口"的缓存，迁移到 peer-RPC 之后
/// 寻址不再依赖 IP/端口，这些字段已全部废弃。
class EnhancedNodeInfo {
  final KVNodeInfo baseInfo;
  final Map<String, dynamic> metadata;
  final String? customName;
  final Uint8List? avatar;

  EnhancedNodeInfo({
    required this.baseInfo,
    this.metadata = const {},
    this.customName,
    this.avatar,
  });

  factory EnhancedNodeInfo.fromKVNodeInfo(KVNodeInfo info) {
    return EnhancedNodeInfo(baseInfo: info);
  }

  EnhancedNodeInfo copyWith({
    KVNodeInfo? baseInfo,
    Map<String, dynamic>? metadata,
    String? customName,
    Uint8List? avatar,
  }) {
    return EnhancedNodeInfo(
      baseInfo: baseInfo ?? this.baseInfo,
      metadata: metadata ?? this.metadata,
      customName: customName ?? this.customName,
      avatar: avatar ?? this.avatar,
    );
  }

  int get peerId => baseInfo.peerId;
  String get hostname => baseInfo.hostname;
  String get ipv4 => baseInfo.ipv4;
  String get displayName => customName ?? baseInfo.hostname;

  /// 节点是否拥有有效的虚拟网 IPv4（兼容 CIDR：`x.x.x.x/24`）。
  /// 公共服务器、未分配 IP 的节点会返回 `false`。UI 用它决定"IP 文字是否高亮"。
  bool get hasValidIpv4 {
    final raw = baseInfo.ipv4.trim();
    if (raw.isEmpty) return false;
    final slash = raw.indexOf('/');
    final ip = (slash >= 0 ? raw.substring(0, slash) : raw).trim();
    return ip.isNotEmpty && ip != '0.0.0.0';
  }
}
