import 'package:astral_game/utils/logger.dart';

import '../peer_rpc_context.dart';
import '../peer_rpc_router.dart' show RpcMiddleware;

/// 入站慢调用告警：handler 执行超过 [threshold] 时打 warn。
///
/// 不影响业务结果，仅做监控。
RpcMiddleware slowCallWarnMiddleware({
  Duration threshold = const Duration(seconds: 1),
}) {
  return (RpcContext ctx, Object? params, next) async {
    final sw = Stopwatch()..start();
    final result = await next(params);
    if (sw.elapsed > threshold) {
      appLogger.w(
        '[rpc slow] ${ctx.channel} from=${ctx.fromPeerId} cost=${sw.elapsedMilliseconds}ms (threshold=${threshold.inMilliseconds}ms)',
      );
    }
    return result;
  };
}
