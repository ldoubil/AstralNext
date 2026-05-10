import 'peer_rpc_status.dart';

/// 跨节点 RPC 异常。状态码语义见 [`RpcStatus`]。
class RpcException implements Exception {
  final int code;
  final String message;
  final Object? data;

  const RpcException(this.code, this.message, {this.data});

  // ---------------- 常用构造器（语义化） ----------------

  factory RpcException.timeout([String? detail]) =>
      RpcException(RpcStatus.requestTimeout,
          detail == null ? 'Request timeout' : 'Request timeout: $detail');

  factory RpcException.notBound([String? detail]) => RpcException(
      RpcStatus.notBound,
      detail ??
          'PeerRpcClient is not bound to any instance (call bindInstance first)');

  factory RpcException.methodNotFound(String channel) =>
      RpcException(RpcStatus.methodNotFound, 'Method not found: $channel');

  factory RpcException.parse(String detail) =>
      RpcException(RpcStatus.parseError, 'Parse error: $detail');

  factory RpcException.internal(Object error) =>
      RpcException(RpcStatus.internalError, 'Internal error: $error');

  // ---------------- 语义化分类 ----------------

  bool get isTransport => RpcStatus.isTransport(code);
  bool get isBusiness => RpcStatus.isBusiness(code);
  bool get isUnreachable => RpcStatus.isUnreachable(code);
  bool get isPermanent => RpcStatus.isPermanent(code);
  bool get isLocalTimeout => RpcStatus.isLocalTimeout(code);

  @override
  String toString() => 'RpcException($code): $message';
}
