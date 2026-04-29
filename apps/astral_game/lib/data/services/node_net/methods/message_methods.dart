import 'package:astral_game/data/services/node_net/node_net_server.dart';
import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';

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
  void send(dynamic params) {
    if (params is! Map) return;

    final content = params['content'] as String? ?? '';
    final fromPeerId = params['fromPeerId'] as int? ?? 0;

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
  void broadcast(dynamic params) {
    send(params);
  }

  /// 获取所有方法
  Map<String, MethodHandler> get methods => {
        'message.send': send,
        'message.broadcast': broadcast,
      };
}
