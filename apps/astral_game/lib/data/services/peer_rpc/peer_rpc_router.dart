import 'dart:async';
import 'dart:typed_data';

import 'package:astral_game/utils/logger.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart';

import 'peer_rpc_codec.dart';
import 'peer_rpc_context.dart';
import 'peer_rpc_exception.dart';
import 'peer_rpc_method.dart';
import 'peer_rpc_status.dart';

/// 入站 handler：拿到 typed 参数 [P] 与 [`RpcContext`]，返回 typed 结果 [R]。
typedef RpcHandler<P, R> = FutureOr<R> Function(P params, RpcContext ctx);

/// 通知监听器：每条 notify 都会被广播一遍（在 method handler 之外，方便业务做埋点）。
typedef RpcNotifyListener = void Function(RpcContext ctx, Object? rawParams);

/// 服务端中间件：可在 handler 前后做 logging / metrics / rate-limit 等。
///
/// `params` 是已经 [`decodeRpcPayload`] 过的 raw JSON（null/Map/List/...），
/// 链尾会再经 [`RpcMethod.decodeParams`] 解成 typed 值。
typedef RpcMiddleware = FutureOr<Object?> Function(
  RpcContext ctx,
  Object? params,
  Future<Object?> Function(Object? params) next,
);

/// peer-RPC 路由器：监听同一 EasyTier instance 上的入站事件，
/// 按 channel 分发到 [`RpcMethod`] 注册的 handler，并自动回包。
///
/// 用法：
/// ```dart
/// final router = PeerRpcRouter()
///   ..use(accessLogMiddleware())
///   ..on(UserRpc.getInfo, (params, ctx) => myUserInfo)
///   ..on(MessageRpc.send, (params, ctx) { /* fire & forget */ });
/// await router.start(instanceId);
/// ```
class PeerRpcRouter {
  final Map<String, _MethodEntry> _methods = {};
  final List<RpcMiddleware> _middlewares = [];
  final List<RpcNotifyListener> _notifyListeners = [];

  // ignore: cancel_subscriptions
  StreamSubscription<AppInboundEventC>? _inboundSub;
  String? _instanceId;

  bool get isRunning => _instanceId != null;
  String? get instanceId => _instanceId;
  int get methodsCount => _methods.length;
  Iterable<String> get registeredChannels => _methods.keys;

  // ---------------- 注册 API ----------------

  /// 注册一个 typed 方法的 handler。重复注册会覆盖，并打印 warn。
  PeerRpcRouter on<P, R>(RpcMethod<P, R> method, RpcHandler<P, R> handler) {
    final channel = method.channel;
    if (_methods.containsKey(channel)) {
      appLogger.w('[PeerRpcRouter] 覆盖已注册方法: $channel');
    }
    _methods[channel] = _MethodEntry(
      channel: channel,
      dispatch: (raw, ctx) async {
        final params = method.decodeParams(raw);
        final result = await handler(params, ctx);
        return method.encodeResult(result);
      },
    );
    return this;
  }

  /// 批量注册：把同一个对象暴露的多个方法一次挂上去。
  PeerRpcRouter onAll(Iterable<RpcBindingBase> bindings) {
    for (final b in bindings) {
      b.attach(this);
    }
    return this;
  }

  /// 注销指定 channel；从未注册时静默忽略。
  void off(String channel) {
    _methods.remove(channel);
  }

  /// 装上一个中间件（按顺序生效）。
  PeerRpcRouter use(RpcMiddleware mw) {
    _middlewares.add(mw);
    return this;
  }

  /// 添加 notify 监听器（在 method handler 之外，所有 notify 都会回调一遍）。
  PeerRpcRouter addNotifyListener(RpcNotifyListener listener) {
    _notifyListeners.add(listener);
    return this;
  }

  // ---------------- 生命周期 ----------------

  /// 绑定到指定 EasyTier instance，开始监听入站事件。
  ///
  /// 已在运行则会先 [`stop`] 再重新 start，保证同一时刻只绑定一个实例。
  Future<void> start(String instanceId) async {
    if (_instanceId != null) {
      await stop();
    }
    _instanceId = instanceId;

    final stream = subscribeAppInbound(instanceId: instanceId);
    _inboundSub = stream.listen(
      _onEvent,
      onError: (Object err, StackTrace st) {
        appLogger.e(
          '[PeerRpcRouter] 入站流错误 instance=$instanceId: $err',
          error: err,
          stackTrace: st,
        );
      },
      onDone: () {
        if (_instanceId == instanceId) {
          _instanceId = null;
          _inboundSub = null;
          appLogger.i('[PeerRpcRouter] 入站流已关闭 instance=$instanceId');
        }
      },
    );

    appLogger.i(
      '[PeerRpcRouter] 已启动 instance=$instanceId methods=$methodsCount middlewares=${_middlewares.length}',
    );
  }

  Future<void> stop() async {
    final sub = _inboundSub;
    final id = _instanceId;
    _inboundSub = null;
    _instanceId = null;
    await sub?.cancel();
    if (id != null) {
      appLogger.i('[PeerRpcRouter] 已停止 instance=$id');
    }
  }

  // ---------------- 内部分发 ----------------

  Future<void> _onEvent(AppInboundEventC evt) async {
    final ctx = RpcContext(
      instanceId: _instanceId ?? '',
      fromPeerId: evt.fromPeerId,
      channel: evt.channel,
      kind: RpcKind.fromInbound(evt.kind),
      receivedAt: DateTime.now(),
      token: evt.kind == AppInboundKindC.call ? evt.token : null,
    );

    Object? rawParams;
    try {
      rawParams = decodeRpcPayload(evt.payload);
    } catch (e) {
      appLogger.w(
        '[PeerRpcRouter] payload 解析失败 channel=${ctx.channel} from=${ctx.fromPeerId}: $e',
      );
      if (ctx.isCall) {
        await _safeReply(evt.token, RpcStatus.parseError, 'Parse error: $e', null);
      }
      return;
    }

    if (ctx.isNotify) {
      await _dispatchNotify(ctx, rawParams);
      return;
    }
    await _dispatchCall(ctx, rawParams, evt.token);
  }

  Future<void> _dispatchNotify(RpcContext ctx, Object? rawParams) async {
    final entry = _methods[ctx.channel];
    if (entry != null) {
      try {
        await _runWithMiddlewares(entry, ctx, rawParams);
      } catch (e, st) {
        appLogger.e(
          '[PeerRpcRouter] notify handler 异常 channel=${ctx.channel}: $e',
          error: e,
          stackTrace: st,
        );
      }
    }
    for (final l in _notifyListeners) {
      try {
        l(ctx, rawParams);
      } catch (e) {
        appLogger.w('[PeerRpcRouter] notify listener 抛错: $e');
      }
    }
  }

  Future<void> _dispatchCall(
    RpcContext ctx,
    Object? rawParams,
    BigInt token,
  ) async {
    final entry = _methods[ctx.channel];
    if (entry == null) {
      appLogger.w('[PeerRpcRouter] 未注册的 channel: ${ctx.channel}');
      await _safeReply(
        token,
        RpcStatus.methodNotFound,
        'Method not found',
        ctx.channel,
      );
      return;
    }
    try {
      final encoded = await _runWithMiddlewares(entry, ctx, rawParams);
      await _safeReply(token, RpcStatus.ok, '', encoded);
    } on RpcException catch (e) {
      await _safeReply(token, e.code, e.message, e.data);
    } catch (e, st) {
      appLogger.e(
        '[PeerRpcRouter] handler 内部错误 channel=${ctx.channel}: $e',
        error: e,
        stackTrace: st,
      );
      await _safeReply(
        token,
        RpcStatus.internalError,
        'Internal error: $e',
        null,
      );
    }
  }

  /// 把 middleware 链组合在 method dispatch 外侧。链按注册顺序执行。
  Future<Object?> _runWithMiddlewares(
    _MethodEntry entry,
    RpcContext ctx,
    Object? rawParams,
  ) {
    Future<Object?> Function(Object?) chain = (p) => entry.dispatch(p, ctx);
    for (final mw in _middlewares.reversed) {
      final next = chain;
      chain = (p) async => await mw(ctx, p, next);
    }
    return chain(rawParams);
  }

  Future<void> _safeReply(
    BigInt token,
    int status,
    String errorMsg,
    Object? data,
  ) async {
    final id = _instanceId;
    if (id == null) return;
    final Uint8List payload;
    try {
      payload = encodeRpcPayload(data);
    } catch (e) {
      appLogger.w('[PeerRpcRouter] 回包编码失败 token=$token: $e');
      try {
        await appCallReply(
          instanceId: id,
          token: token,
          status: RpcStatus.internalError,
          errorMsg: 'Encode error: $e',
          payload: Uint8List(0),
        );
      } catch (_) {}
      return;
    }
    try {
      await appCallReply(
        instanceId: id,
        token: token,
        status: status,
        errorMsg: errorMsg,
        payload: payload,
      );
    } catch (e) {
      appLogger.w('[PeerRpcRouter] 回包失败 token=$token: $e');
    }
  }
}

/// 内部使用的"已类型擦除的 method entry"。
class _MethodEntry {
  final String channel;
  final Future<Object?> Function(Object? raw, RpcContext ctx) dispatch;
  _MethodEntry({required this.channel, required this.dispatch});
}

/// 已经类型擦除的 binding 基类。业务一般直接用 [`RpcBinding`]；这层抽象的
/// 唯一作用是让 [`PeerRpcRouter.onAll`] 能接收一个泛型不一致的 binding 列表。
abstract class RpcBindingBase {
  /// 把自身挂到 router 上。
  void attach(PeerRpcRouter router);
}

/// 用 [`RpcMethod`] + handler 打包注册项，便于业务把同一类方法集中暴露。
///
/// ```dart
/// router.onAll([
///   RpcBinding(UserRpc.getInfo, _getInfo),
///   RpcBinding(UserRpc.update, _update),
/// ]);
/// ```
class RpcBinding<P, R> implements RpcBindingBase {
  final RpcMethod<P, R> method;
  final RpcHandler<P, R> handler;

  RpcBinding(this.method, this.handler);

  @override
  void attach(PeerRpcRouter router) {
    router.on(method, handler);
  }
}
