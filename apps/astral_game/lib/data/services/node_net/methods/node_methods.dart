import 'package:astral_game/data/services/node_management_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

/// 节点相关方法
class NodeMethods {
  final NodeManagementService _nodeManagement;

  NodeMethods(this._nodeManagement);

  /// 获取节点列表
  List<Map<String, dynamic>> list(Parameters params) {
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
  Map<String, dynamic> getInfo(Parameters params) {
    final peerId = params['peerId'].asInt;

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
