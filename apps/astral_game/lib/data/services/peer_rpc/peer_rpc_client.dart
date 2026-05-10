import 'dart:async';

import 'package:astral_game/utils/logger.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart';

import 'peer_rpc_codec.dart';
import 'peer_rpc_exception.dart';

/// 替代旧 `NodeNetClient` 的 peer-RPC 客户端封装。
///
/// 用法：
/// ```dart
/// final client = GetIt.I<PeerRpcClient>()..bindInstance(instanceId);
/// final result = await client.call(peerId, 'user.getInfo');
/// ```
///
/// 与 jsonrpc 时代相比，这里的差异：
/// - **不再有 IP/port**：路由由 EasyTier 负责，调用方只关心 `peerId`。
/// - **不再有 token**：网络鉴权已经在 EasyTier 的 `network_secret` 上做了。
/// - **不再有 HTTP**：所有通信走在 EasyTier 的控制面 RPC（`Control` 平面，
///   独立于普通虚拟网数据，且不会被打入流量统计）。
class PeerRpcClient {
  /// 默认 RPC 超时。和旧实现保持一致。
  static const Duration defaultTimeout = Duration(seconds: 5);

  /// 是否打印调用成功日志。频繁场景下默认关闭。
  static const bool _verboseLog = false;

  String? _instanceId;

  /// 是否已经绑定到一个运行中的 instance。
  bool get isBound => _instanceId != null;

  /// 绑定/解绑当前 instance。传 `null` 解绑。
  void bindInstance(String? instanceId) {
    _instanceId = (instanceId == null || instanceId.isEmpty) ? null : instanceId;
  }

  /// 释放资源（兼容旧 `dispose()` 接口）。
  void dispose() {
    _instanceId = null;
  }

  /// 发送请求-响应 RPC，等待对端 handler 回包。
  ///
  /// - [params] 任意 JSON-able 对象（Map/List/null/...）。
  /// - [timeout] 仅作用于网络层；对端 handler 自身的执行时长另由 EasyTier 控制
  ///   （默认 30s 内未 reply 会拿到 `RpcException(-2, ...)`）。
  /// - 返回值：对端 handler 的原始返回（已 JSON 解码）。
  ///
  /// 抛出 [`RpcException`]：见 [`RpcException`] 文档对状态码的约定。
  Future<dynamic> call(
    int peerId,
    String channel, {
    dynamic params,
    Duration timeout = defaultTimeout,
  }) async {
    final id = _ensureBound();
    final sw = Stopwatch()..start();

    final AppCallResultC result;
    try {
      result = await appCall(
        instanceId: id,
        dstPeerId: peerId,
        channel: channel,
        requestId: BigInt.zero,
        payload: encodeRpcPayload(params),
        flags: 0,
        timeoutMs: timeout.inMilliseconds,
      );
    } on TimeoutException {
      throw RpcException(-32000, 'Request timeout');
    } catch (e) {
      // EasyTier 的 RPC 客户端超时（`Timeout: deadline has elapsed`）会以
      // anyhow 字符串透回到 dart 这一层；把它识别成传输级超时(-32000)，
      // 而不是吞进通用的 -32603，便于上层做"静默忽略"的策略。
      final msg = e.toString();
      if (_looksLikeTimeout(msg)) {
        throw RpcException(-32000, 'Request timeout: $msg');
      }
      throw RpcException(-32603, 'Internal error: $e');
    }

    if (_verboseLog) {
      appLogger.d(
        '[PeerRpcClient] <- $channel peer=$peerId status=${result.status} costMs=${sw.elapsedMilliseconds}',
      );
    }

    if (result.status == 0) {
      try {
        return decodeRpcPayload(result.payload);
      } catch (e) {
        throw RpcException(-32700, 'Parse response error: $e');
      }
    }

    // 业务级异常：>0；传输级异常：<0。
    final dynamic data;
    try {
      data = decodeRpcPayload(result.payload);
    } catch (_) {
      throw RpcException(result.status, _resolveErrorMsg(result));
    }
    throw RpcException(result.status, _resolveErrorMsg(result), data: data);
  }

  /// 发送 fire-and-forget 通知。底层 RPC 仍会等到对端 ack（用于检测路由失败），
  /// 但是业务侧不会拿到对端 handler 的返回值。
  Future<void> notify(
    int peerId,
    String channel, {
    dynamic params,
    Duration timeout = defaultTimeout,
  }) async {
    final id = _ensureBound();
    try {
      await appNotify(
        instanceId: id,
        dstPeerId: peerId,
        channel: channel,
        payload: encodeRpcPayload(params),
        timeoutMs: timeout.inMilliseconds,
      );
    } on TimeoutException {
      throw RpcException(-32000, 'Request timeout');
    } catch (e) {
      appLogger.w('[PeerRpcClient] notify 失败 channel=$channel peer=$peerId err=$e');
      rethrow;
    }
  }

  /// peer-to-peer ping（RTT 毫秒）。比 `notify` 多一层 EasyTier 内置实现，
  /// 不需要业务侧注册任何 channel。
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
      throw RpcException(-32603, 'ping error: $e');
    }
  }

  String _ensureBound() {
    final id = _instanceId;
    if (id == null) {
      throw RpcException(
        -32002,
        'PeerRpcClient is not bound to any instance (call bindInstance first)',
      );
    }
    return id;
  }

  bool _looksLikeTimeout(String message) {
    final m = message.toLowerCase();
    return m.contains('timeout') ||
        m.contains('timed out') ||
        m.contains('deadline');
  }

  String _resolveErrorMsg(AppCallResultC result) {
    if (result.errorMsg.isNotEmpty) return result.errorMsg;
    switch (result.status) {
      case -1:
        return 'No subscriber on receiver';
      case -2:
        return 'Receiver application reply timeout';
      case -3:
        return 'Receiver service dropped before reply';
      default:
        return 'rpc status=${result.status}';
    }
  }
}
