import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

/// 消息事件
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

/// 消息相关方法
class MessageMethods {
  /// 发送消息（通知）
  ///
  /// 此方法不返回响应，仅触发事件
  void send(Parameters params) {
    final content = params['content'].asString;
    final fromPeerId = params['fromPeerId'].exists ? params['fromPeerId'].asInt : 0;

    final eventBus = GetIt.I<EventBus>();
    eventBus.fire(MessageEvent(
      fromPeerId: fromPeerId,
      content: content,
      timestamp: DateTime.now(),
    ));
  }

  /// 广播消息（通知）
  ///
  /// 此方法不返回响应，仅触发事件
  void broadcast(Parameters params) {
    send(params);
  }

  /// 获取所有方法
  Map<String, MethodHandler> get methods => {
        'message.send': send,
        'message.broadcast': broadcast,
      };
}
