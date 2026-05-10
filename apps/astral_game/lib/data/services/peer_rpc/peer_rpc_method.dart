/// 类型化的 RPC 方法定义。
///
/// 同一个 [`RpcMethod`] 既能在服务端 `router.on(method, handler)` 注册
/// 入站 handler，也能在客户端 `client.invoke(peerId, method, params)` 直接调用。
/// 它把 channel + 参数/返回值的编解码"绑成一个静态对象"，避免业务把字符串散
/// 落得到处都是。
///
/// 业务示例：
/// ```dart
/// // 1) 定义（一次）
/// class UserRpc {
///   static final getInfo = RpcMethod<void, UserInfo>(
///     channel: 'user.getInfo',
///     decodeParams: (_) {},
///     encodeParams: (_) => null,
///     encodeResult: (r) => r.toJson(),
///     decodeResult: (raw) => UserInfo.fromJson(raw as Map<String, dynamic>),
///   );
/// }
/// // 2) 注册（服务端）
/// router.on(UserRpc.getInfo, (params, ctx) => myUserInfo);
/// // 3) 调用（客户端）
/// final info = await client.invoke(peerId, UserRpc.getInfo, null);
/// ```
class RpcMethod<P, R> {
  /// peer-rpc envelope 的 `channel` 字段，全局唯一。
  final String channel;

  /// 服务端：把入站的 raw JSON（null/Map/List/...）反序列化成业务参数 [P]。
  final P Function(Object? raw) decodeParams;

  /// 客户端：把业务参数 [P] 序列化成 JSON-able 对象（再交给 codec 编码到字节）。
  /// 返回 `null` 代表"无 payload"。
  final Object? Function(P value) encodeParams;

  /// 服务端：把 handler 的返回值 [R] 序列化成 JSON-able 对象。
  final Object? Function(R value) encodeResult;

  /// 客户端：把对端回包的 raw JSON 反序列化成业务返回值 [R]。
  final R Function(Object? raw) decodeResult;

  const RpcMethod({
    required this.channel,
    required this.decodeParams,
    required this.encodeParams,
    required this.encodeResult,
    required this.decodeResult,
  });

  /// 透传 JSON：参数/返回值都是 `Map<String, dynamic>?`。
  ///
  /// 适合"参数和返回值都是临时的、没必要单独建模"的场景（比如 ping/pong、
  /// 简单的 echo）。
  static RpcMethod<Map<String, dynamic>?, Map<String, dynamic>?> jsonMap(
    String channel,
  ) {
    return RpcMethod<Map<String, dynamic>?, Map<String, dynamic>?>(
      channel: channel,
      decodeParams: _decodeJsonMap,
      encodeParams: _passthrough,
      encodeResult: _passthrough,
      decodeResult: _decodeJsonMap,
    );
  }

  /// 单向通知（无返回值）。用于 fire-and-forget 场景（e.g. 广播消息）。
  static RpcMethod<Map<String, dynamic>?, void> notifyMap(String channel) {
    return RpcMethod<Map<String, dynamic>?, void>(
      channel: channel,
      decodeParams: _decodeJsonMap,
      encodeParams: _passthrough,
      encodeResult: _voidEncode,
      decodeResult: _voidDecode,
    );
  }

  /// 自定义类型版的便捷构造器：服务端 / 客户端各自给一对 `fromJson` / `toJson`。
  ///
  /// 当 [P] 或 [R] 是 `void`/`null` 时，可以直接传 `(_) {}` / `(_) => null`。
  factory RpcMethod.typed({
    required String channel,
    required P Function(Object? raw) paramsFromJson,
    required Object? Function(P value) paramsToJson,
    required Object? Function(R value) resultToJson,
    required R Function(Object? raw) resultFromJson,
  }) {
    return RpcMethod<P, R>(
      channel: channel,
      decodeParams: paramsFromJson,
      encodeParams: paramsToJson,
      encodeResult: resultToJson,
      decodeResult: resultFromJson,
    );
  }
}

Map<String, dynamic>? _decodeJsonMap(Object? raw) {
  if (raw == null) return null;
  if (raw is Map) return raw.cast<String, dynamic>();
  return null;
}

Object? _passthrough(Object? value) => value;
Object? _voidEncode(void _) => null;
void _voidDecode(Object? _) {}
