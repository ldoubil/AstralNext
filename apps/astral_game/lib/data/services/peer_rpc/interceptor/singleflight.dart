import 'dart:async';
import 'dart:convert';

import 'package:astral_rust_core/src/rust/api/p2p.dart' show AppCallResultC;

import '../peer_rpc_client.dart' show RpcCallRequest, RpcClientInterceptor;
import '../peer_rpc_context.dart';

/// 客户端 singleflight 去重拦截器。
///
/// 同一 `(peerId, channel, params)` 在前一次还没回来时，后续相同请求会复用
/// 同一个 Future。仅作用于 [`RpcKind.call`]；ping/notify 直接放行。
///
/// 适合 polling 场景下避免"上一次没回来时又触发了一次同样的拉取"。
RpcClientInterceptor singleflightInterceptor() {
  final inflight = <String, Future<AppCallResultC>>{};
  return (RpcCallRequest req, next) {
    if (req.kind != RpcKind.call) return next(req);
    final key = _keyOf(req);
    final existing = inflight[key];
    if (existing != null) return existing;
    final fut = next(req).whenComplete(() => inflight.remove(key));
    inflight[key] = fut;
    return fut;
  };
}

String _keyOf(RpcCallRequest req) {
  String paramsKey;
  try {
    paramsKey = jsonEncode(req.params);
  } catch (_) {
    paramsKey = req.params.toString();
  }
  return '${req.peerId}|${req.channel}|$paramsKey';
}
