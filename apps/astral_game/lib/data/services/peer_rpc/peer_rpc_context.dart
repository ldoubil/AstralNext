import 'package:astral_rust_core/src/rust/api/p2p.dart' show AppInboundKindC;

/// 一次入站 RPC 的"是请求还是通知"。
enum RpcKind {
  call,
  notify;

  static RpcKind fromInbound(AppInboundKindC kind) =>
      kind == AppInboundKindC.call ? RpcKind.call : RpcKind.notify;
}

/// 入站 RPC 的上下文。每次入站事件构造一个新实例，注入到 handler / middleware 中。
///
/// 拿到的字段都是只读的，不要在 handler 里修改 `ctx`。
class RpcContext {
  /// 当前 EasyTier instance id（router 绑定的实例）。
  final String instanceId;

  /// 调用方 peer_id。
  final int fromPeerId;

  /// 业务 channel（例如 `user.getInfo`）。
  final String channel;

  /// 请求-响应模式 vs 通知模式。
  final RpcKind kind;

  /// 收到事件的本地时间戳（用于在 middleware 里测耗时）。
  final DateTime receivedAt;

  /// EasyTier 内部的回包 token；仅 [`RpcKind.call`] 时有意义。框架会自动用它
  /// 回包，业务侧一般无需访问。
  final BigInt? token;

  RpcContext({
    required this.instanceId,
    required this.fromPeerId,
    required this.channel,
    required this.kind,
    required this.receivedAt,
    required this.token,
  });

  bool get isCall => kind == RpcKind.call;
  bool get isNotify => kind == RpcKind.notify;
}
