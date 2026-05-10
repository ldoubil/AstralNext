import 'dart:async';

import '../peer_rpc_client.dart' show RpcCallRequest, RpcClientInterceptor;
import '../peer_rpc_context.dart';
import '../peer_rpc_status.dart';

/// 智能重试：对"暂时性"传输错误自动退避重试，对"永久性"错误直接放弃。
///
/// 默认行为：
/// - 业务错误（status > 0）/成功（status == 0）：直接返回，不重试。
/// - 永久错误（method_not_found/parse/not_bound）：直接返回，不重试。
/// - 其它传输错误：重试 [maxRetries] 次，每次间隔 [baseDelay] * (attempt+1)。
///
/// 仅对 [`RpcKind.call`] 生效；ping/notify 直接放行。
RpcClientInterceptor smartRetryInterceptor({
  int maxRetries = 1,
  Duration baseDelay = const Duration(milliseconds: 200),
}) {
  return (RpcCallRequest req, next) async {
    if (req.kind != RpcKind.call) return await next(req);
    var attempt = 0;
    while (true) {
      final result = await next(req);
      if (result.status == RpcStatus.ok) return result;
      if (RpcStatus.isBusiness(result.status)) return result;
      if (RpcStatus.isPermanent(result.status)) return result;
      attempt++;
      if (attempt > maxRetries) return result;
      await Future<void>.delayed(baseDelay * attempt);
    }
  };
}
