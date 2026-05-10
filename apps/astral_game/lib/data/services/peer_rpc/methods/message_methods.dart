import 'package:astral_game/data/services/peer_rpc/peer_rpc_context.dart';
import 'package:astral_game/data/services/peer_rpc/peer_rpc_method.dart';
import 'package:astral_game/data/services/peer_rpc/peer_rpc_router.dart';
import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';

/// 房间内的一条消息（事件总线广播体）。
class MessageEvent {
  final int fromPeerId;
  final String content;
  final DateTime timestamp;

  MessageEvent({
    required this.fromPeerId,
    required this.content,
    required this.timestamp,
  });
}

/// `message.*` RPC 的请求体。
class MessagePayload {
  final String content;
  const MessagePayload({required this.content});

  Map<String, dynamic> toJson() => {'content': content};

  static MessagePayload fromJson(Object? raw) {
    if (raw is! Map) return const MessagePayload(content: '');
    return MessagePayload(content: raw['content'] as String? ?? '');
  }
}

class MessageRpc {
  MessageRpc._();

  /// 单播：把消息发给指定 peer。fire-and-forget。
  static final send = RpcMethod.notifyMap('message.send');

  /// 广播（语义上是"群发到 N 个 peer"——具体由调用方依次 notify 每个 peer）。
  static final broadcast = RpcMethod.notifyMap('message.broadcast');

  /// 类型化版（如果业务想直接传 [`MessagePayload`]，可以走这个；
  /// 服务端默认仍按 `Map` 解析，保持与 [`send`] / [`broadcast`] 兼容）。
  static final sendTyped = RpcMethod<MessagePayload, void>(
    channel: 'message.send',
    decodeParams: MessagePayload.fromJson,
    encodeParams: (v) => v.toJson(),
    encodeResult: (_) => null,
    decodeResult: (_) {},
  );
}

class MessageMethods {
  EventBus get _bus => GetIt.I<EventBus>();

  List<RpcBindingBase> bindings() => [
        RpcBinding<Map<String, dynamic>?, void>(MessageRpc.send, _onMessage),
        RpcBinding<Map<String, dynamic>?, void>(MessageRpc.broadcast, _onMessage),
      ];

  void _onMessage(Map<String, dynamic>? params, RpcContext ctx) {
    if (params == null) return;
    final content = params['content'] as String? ?? '';
    _bus.fire(MessageEvent(
      fromPeerId: ctx.fromPeerId,
      content: content,
      timestamp: DateTime.now(),
    ));
  }
}
