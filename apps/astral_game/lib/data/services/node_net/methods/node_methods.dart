import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/node_net/node_net_server.dart';

/// 节点相关方法
class NodeMethods {
  final NodeManagementService _nodeManagement;

  NodeMethods(this._nodeManagement);

  /// 获取节点列表
  List<Map<String, dynamic>> list(dynamic params) {
    return _nodeManagement.userNodes.value.map((node) {
      return {
        'peerId': node.peerId,
        'name': node.customName ?? node.hostname,
        'ip': node.ipv4,
        'port': node.port,
      };
    }).toList();
  }

  /// 获取节点详情
  Map<String, dynamic> getInfo(dynamic params) {
    int peerId = 0;
    if (params is Map && params['peerId'] != null) {
      peerId = params['peerId'] as int;
    }

    final node = _nodeManagement.userNodes.value.firstWhere(
      (n) => n.peerId == peerId,
      orElse: () => throw RpcException(-32001, 'Node not found'),
    );

    return {
      'peerId': node.peerId,
      'name': node.customName ?? node.hostname,
      'ip': node.ipv4,
      'port': node.port,
      'hostname': node.hostname,
    };
  }

  /// 获取所有方法
  Map<String, MethodHandler> get methods => {
        'node.list': list,
        'node.getInfo': getInfo,
      };
}
