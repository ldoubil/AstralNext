/// peer-RPC 的状态码体系。
///
/// 约定：
/// - `0` 成功（不会以异常形式抛出）。
/// - `> 0` 业务自定义错误（具体语义由 channel 两端约定）。
/// - `< 0` 传输/框架级错误，由底层注入。
///
/// 这里把所有"魔数"集中起来，方便上层以 `RpcStatus.isUnreachable(code)` 等
/// 语义化方法做错误归类，而不是到处写 `e.code == -1 || e.code == -2`。
class RpcStatus {
  RpcStatus._();

  /// 成功
  static const int ok = 0;

  // ---------------- 传输 / 框架层（< 0） ----------------

  /// 对端没有订阅入站事件（EasyTier `astral_app_rpc::status::NO_SUBSCRIBER`）。
  ///
  /// 通常意味着对端没跑 astral_game，或者它的 router 还没 `start`。
  static const int noSubscriber = -1;

  /// 对端业务超时未回复（EasyTier `REPLY_TIMEOUT`）。
  static const int receiverReplyTimeout = -2;

  /// 对端服务在回复前被销毁（EasyTier `SERVICE_DROPPED`）。
  static const int receiverServiceDropped = -3;

  /// 客户端等待响应超时（本端发起方超时）。
  static const int requestTimeout = -32000;

  /// 客户端尚未绑定到任何 instance。
  static const int notBound = -32002;

  /// 收到的请求所指向的 channel 未在本端注册。
  static const int methodNotFound = -32601;

  /// 收端 handler 抛出了非 [`RpcException`] 类型的异常。
  static const int internalError = -32603;

  /// 请求/响应 payload 解析失败。
  static const int parseError = -32700;

  // ---------------- 分类工具 ----------------

  /// 是否传输 / 框架级错误（一般可以静默忽略 / 做退避）。
  static bool isTransport(int code) => code < 0;

  /// 是否业务自定义错误（语义由两端约定）。
  static bool isBusiness(int code) => code > 0;

  /// 是否「对端不可达 / 暂时性失败」——典型场景：邻居刚连上、还没起 router；
  /// 适合在 polling 里降级为 debug 日志。
  static bool isUnreachable(int code) =>
      code == noSubscriber ||
      code == receiverReplyTimeout ||
      code == receiverServiceDropped ||
      code == requestTimeout ||
      code == internalError;

  /// 是否「永久性失败」——重试也不会变好，应当直接放弃。
  static bool isPermanent(int code) =>
      code == methodNotFound || code == parseError || code == notBound;

  /// 是否「本端发起方超时」类（适合 client 端做指数退避）。
  static bool isLocalTimeout(int code) => code == requestTimeout;

  /// 把状态码映射成英文短描述，主要用于无 errorMsg 时兜底展示。
  static String describe(int code) {
    switch (code) {
      case ok:
        return 'ok';
      case noSubscriber:
        return 'No subscriber on receiver';
      case receiverReplyTimeout:
        return 'Receiver application reply timeout';
      case receiverServiceDropped:
        return 'Receiver service dropped before reply';
      case requestTimeout:
        return 'Request timeout';
      case notBound:
        return 'Client not bound to any instance';
      case methodNotFound:
        return 'Method not found';
      case internalError:
        return 'Internal error';
      case parseError:
        return 'Parse error';
      default:
        return 'rpc status=$code';
    }
  }
}
