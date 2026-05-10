import 'package:astral_game/utils/logger.dart';

import '../peer_rpc_context.dart';
import '../peer_rpc_router.dart' show RpcMiddleware;

/// 入站访问日志中间件。
///
/// - [verboseSuccess] 是否打印成功调用（默认 false，避免每秒轮询刷屏）。
/// - [logErrors] 是否打印异常（默认 true）。
RpcMiddleware accessLogMiddleware({
  bool verboseSuccess = false,
  bool logErrors = true,
}) {
  return (RpcContext ctx, Object? params, next) async {
    final sw = Stopwatch()..start();
    try {
      final result = await next(params);
      if (verboseSuccess) {
        appLogger.d(
          '[rpc <-] ${ctx.kind.name} ${ctx.channel} from=${ctx.fromPeerId} ok cost=${sw.elapsedMilliseconds}ms',
        );
      }
      return result;
    } catch (e) {
      if (logErrors) {
        appLogger.w(
          '[rpc <-] ${ctx.kind.name} ${ctx.channel} from=${ctx.fromPeerId} err=$e cost=${sw.elapsedMilliseconds}ms',
        );
      }
      rethrow;
    }
  };
}
