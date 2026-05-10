import 'dart:async';
import 'dart:typed_data';

import 'package:astral_game/utils/logger.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart';

import 'peer_rpc_codec.dart';
import 'peer_rpc_context.dart';
import 'peer_rpc_exception.dart';
import 'peer_rpc_method.dart';
import 'peer_rpc_status.dart';

/// 客户端发起的一次 RPC 调用快照。
///
/// 从 client 流入 [`RpcClientInterceptor`] 链；最末端会被映射到底层
/// `appCall` / `appNotify` / `peerPing` FFI。
class RpcCallRequest {
  /// 目标节点 peer_id。
  final int peerId;

  /// 业务 channel；ping 用 `"<ping>"` 占位，正常业务不会撞名。
  final String channel;

  /// 序列化前的参数（任意 JSON-able），ping 时为 `null`。
  final Object? params;

  /// 这次请求的语义类别。
  final RpcKind kind;

  /// 网络层超时（仅作用于本端发起方）。
  final Duration timeout;

  /// 给调用方传透的额外 flags（保留字段，目前未使用）。
  final int flags;

  const RpcCallRequest({
    required this.peerId,
    required this.channel,
    required this.params,
    required this.kind,
    required this.timeout,
    this.flags = 0,
  });

  RpcCallRequest copyWith({
    int? peerId,
    String? channel,
    Object? params,
    RpcKind? kind,
    Duration? timeout,
    int? flags,
  }) {
    return RpcCallRequest(
      peerId: peerId ?? this.peerId,
      channel: channel ?? this.channel,
      params: params ?? this.params,
      kind: kind ?? this.kind,
      timeout: timeout ?? this.timeout,
      flags: flags ?? this.flags,
    );
  }
}

/// 客户端拦截器：在底层 FFI 之外做去重 / 重试 / 限流 / 熔断等。
typedef RpcClientInterceptor = Future<AppCallResultC> Function(
  RpcCallRequest req,
  Future<AppCallResultC> Function(RpcCallRequest req) next,
);

/// 节点级 RPC 客户端：把 `appCall / appNotify / peerPing` 等 FFI 包装成
/// 类型化、可拦截的请求 API。
class PeerRpcClient {
  static const Duration defaultTimeout = Duration(seconds: 5);

  final List<RpcClientInterceptor> _interceptors = [];
  String? _instanceId;

  bool get isBound => _instanceId != null;

  void bindInstance(String? instanceId) {
    _instanceId = (instanceId == null || instanceId.isEmpty) ? null : instanceId;
  }

  void dispose() {
    _instanceId = null;
    _interceptors.clear();
  }

  /// 装上拦截器（按顺序生效）。重复装会按声明顺序串成链。
  PeerRpcClient use(RpcClientInterceptor interceptor) {
    _interceptors.add(interceptor);
    return this;
  }

  // ---------------- 类型化 API ----------------

  /// 类型化的请求-响应调用：把 [P] 编码、底层 FFI 调用、对端回包解码三步串起来。
  ///
  /// 仅在状态码 ≠ 0 时抛 [`RpcException`]，业务可在外层用
  /// `e.isUnreachable` / `e.isPermanent` 决策是否重试 / 静默。
  Future<R> invoke<P, R>(
    int peerId,
    RpcMethod<P, R> method,
    P params, {
    Duration timeout = defaultTimeout,
    int flags = 0,
  }) async {
    final req = RpcCallRequest(
      peerId: peerId,
      channel: method.channel,
      params: method.encodeParams(params),
      kind: RpcKind.call,
      timeout: timeout,
      flags: flags,
    );
    final result = await _runChain(req);
    if (result.status == RpcStatus.ok) {
      try {
        final raw = decodeRpcPayload(result.payload);
        return method.decodeResult(raw);
      } catch (e) {
        throw RpcException.parse('Parse response error: $e');
      }
    }
    throw _toException(result);
  }

  /// 类型化的 fire-and-forget 通知：底层会等到对端 ack（用于检测路由失败）。
  Future<void> notifyMethod<P, R>(
    int peerId,
    RpcMethod<P, R> method,
    P params, {
    Duration timeout = defaultTimeout,
  }) async {
    final req = RpcCallRequest(
      peerId: peerId,
      channel: method.channel,
      params: method.encodeParams(params),
      kind: RpcKind.notify,
      timeout: timeout,
    );
    final result = await _runChain(req);
    if (result.status != RpcStatus.ok) throw _toException(result);
  }

  // ---------------- 低阶 API（不依赖 RpcMethod） ----------------

  /// 不带 method 定义的"原始 channel"调用。仅在调试 / 临时联调时使用，
  /// 业务代码请优先用 [`invoke`]。
  Future<Object?> callRaw(
    int peerId,
    String channel, {
    Object? params,
    Duration timeout = defaultTimeout,
  }) async {
    final req = RpcCallRequest(
      peerId: peerId,
      channel: channel,
      params: params,
      kind: RpcKind.call,
      timeout: timeout,
    );
    final result = await _runChain(req);
    if (result.status == RpcStatus.ok) {
      try {
        return decodeRpcPayload(result.payload);
      } catch (e) {
        throw RpcException.parse('Parse response error: $e');
      }
    }
    throw _toException(result);
  }

  /// 不带 method 定义的"原始 channel"通知。
  Future<void> notifyRaw(
    int peerId,
    String channel, {
    Object? params,
    Duration timeout = defaultTimeout,
  }) async {
    final req = RpcCallRequest(
      peerId: peerId,
      channel: channel,
      params: params,
      kind: RpcKind.notify,
      timeout: timeout,
    );
    final result = await _runChain(req);
    if (result.status != RpcStatus.ok) throw _toException(result);
  }

  /// peer-to-peer ping，返回 RTT（ms）。
  ///
  /// 不依赖业务 channel；底层走 EasyTier 的内置 ping 实现，**不经过拦截器链**
  /// （ping 流量极小、语义独立，没必要被通用 retry/singleflight 套住）。
  Future<int> ping(
    int peerId, {
    Duration timeout = defaultTimeout,
  }) async {
    final id = _ensureBound();
    try {
      final rtt = await peerPing(
        instanceId: id,
        dstPeerId: peerId,
        timeoutMs: timeout.inMilliseconds,
      );
      return rtt.toInt();
    } catch (e) {
      throw RpcException.internal(e);
    }
  }

  // ---------------- 内部链路 ----------------

  Future<AppCallResultC> _runChain(RpcCallRequest req) {
    Future<AppCallResultC> Function(RpcCallRequest) chain = _executeRaw;
    for (final i in _interceptors.reversed) {
      final next = chain;
      chain = (r) => i(r, next);
    }
    return chain(req);
  }

  Future<AppCallResultC> _executeRaw(RpcCallRequest req) async {
    final id = _ensureBound();
    final Uint8List payload;
    try {
      payload = encodeRpcPayload(req.params);
    } catch (e) {
      throw RpcException.parse('Encode params error: $e');
    }

    try {
      if (req.kind == RpcKind.notify) {
        await appNotify(
          instanceId: id,
          dstPeerId: req.peerId,
          channel: req.channel,
          payload: payload,
          timeoutMs: req.timeout.inMilliseconds,
        );
        return AppCallResultC(status: RpcStatus.ok, errorMsg: '', payload: Uint8List(0));
      }
      return await appCall(
        instanceId: id,
        dstPeerId: req.peerId,
        channel: req.channel,
        requestId: BigInt.zero,
        payload: payload,
        flags: req.flags,
        timeoutMs: req.timeout.inMilliseconds,
      );
    } on TimeoutException {
      return AppCallResultC(
        status: RpcStatus.requestTimeout,
        errorMsg: 'Request timeout',
        payload: Uint8List(0),
      );
    } catch (e) {
      // EasyTier 把对端超时以 anyhow 字符串形式传回，识别为本端 timeout。
      final msg = e.toString();
      if (_looksLikeTimeout(msg)) {
        return AppCallResultC(
          status: RpcStatus.requestTimeout,
          errorMsg: 'Request timeout: $msg',
          payload: Uint8List(0),
        );
      }
      appLogger.w(
        '[PeerRpcClient] FFI 调用失败 channel=${req.channel} peer=${req.peerId} err=$e',
      );
      return AppCallResultC(
        status: RpcStatus.internalError,
        errorMsg: 'Internal error: $e',
        payload: Uint8List(0),
      );
    }
  }

  RpcException _toException(AppCallResultC result) {
    final msg = result.errorMsg.isNotEmpty
        ? result.errorMsg
        : RpcStatus.describe(result.status);
    Object? data;
    try {
      data = decodeRpcPayload(result.payload);
    } catch (_) {
      data = null;
    }
    return RpcException(result.status, msg, data: data);
  }

  String _ensureBound() {
    final id = _instanceId;
    if (id == null) throw RpcException.notBound();
    return id;
  }

  bool _looksLikeTimeout(String message) {
    final m = message.toLowerCase();
    return m.contains('timeout') ||
        m.contains('timed out') ||
        m.contains('deadline');
  }
}
