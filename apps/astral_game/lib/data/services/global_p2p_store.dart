import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:signals/signals_core.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNetworkStatus, KVNodeInfo;
import '../models/enhanced_node_info.dart';

class GlobalP2PStore {
  final _p2pService = GetIt.I<P2PService>();

  /// 当前连接的 instanceId（astral_game 同时只运行一个实例）
  final currentInstanceId = signal<String?>(null);

  /// 当前网络状态
  final networkStatus = signal<KVNetworkStatus?>(null);

  /// 过滤后的用户节点列表（排除公共服务器节点）
  final userNodes = signal<List<KVNodeInfo>>([]);

  /// 增强的用户节点列表（包含自定义扩展信息）
  final enhancedUserNodes = signal<List<EnhancedNodeInfo>>([]);

  Timer? _pollingTimer;

  String? get instanceId => currentInstanceId.value;
  bool get isRunning => currentInstanceId.value != null;

  /// 标记实例正在启动
  void setStarting() {
    // 连接中状态，不设置 instanceId
  }

  /// 标记实例已运行
  void setRunning(String instanceId) {
    currentInstanceId.value = instanceId;
    _startPolling(instanceId);
  }

  /// 标记实例已停止
  void setStopped() {
    _stopPolling();
    currentInstanceId.value = null;
    networkStatus.value = null;
    userNodes.value = [];  // 清空用户列表
    enhancedUserNodes.value = [];  // 清空增强节点列表
  }

  /// 检查 IP 是否有效（不是 0.0.0.0）
  bool isValidIp(String ip) {
    return ip != '0.0.0.0';
  }

  /// 获取有效的节点列表（排除 IP 为 0.0.0.0 的节点）
  List<KVNodeInfo> getValidNodes() {
    return userNodes.value.where((node) => isValidIp(node.ipv4)).toList();
  }

  /// 获取节点的 IP 显示文本
  String getNodeIpDisplayText(String ip) {
    return isValidIp(ip) ? ip : '获取中...';
  }

  /// 更新节点的头像端口
  void updateNodeAvatarPort(int peerId, int port) {
    final nodes = List<EnhancedNodeInfo>.from(enhancedUserNodes.value);
    final index = nodes.indexWhere((n) => n.peerId == peerId);
    
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(
        avatarPort: port,
        lastAvatarPortScan: DateTime.now(),
      );
      enhancedUserNodes.value = nodes;
      debugPrint('[P2PStore] Updated avatar port for peer $peerId: $port');
    }
  }

  /// 获取节点的头像端口
  int? getNodeAvatarPort(int peerId) {
    try {
      final node = enhancedUserNodes.value
          .firstWhere((n) => n.peerId == peerId);
      return node.avatarPort;
    } catch (e) {
      return null;
    }
  }

  void _startPolling(String instanceId) {
    _stopPolling();
    _pollNetworkStatus(instanceId);
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pollNetworkStatus(instanceId);
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollNetworkStatus(String instanceId) async {
    try {
      final status = await _p2pService.getNetworkStatus(instanceId);
      
      debugPrint('[P2PStore] _pollNetworkStatus - 准备更新 networkStatus');
      if (networkStatus.value != null) {
        debugPrint('[P2PStore]   当前 networkStatus.value: ${networkStatus.value!.nodes.length} 个节点');
      } else {
        debugPrint('[P2PStore]   当前 networkStatus.value: null');
      }
      
      if (status != null) {
        debugPrint('[P2PStore]   新 status.nodes 数量: ${status.nodes.length}');
        for (var node in status.nodes) {
          debugPrint('[P2PStore]     节点: ${node.hostname}, IP: ${node.ipv4}');
        }
      } else {
        debugPrint('[P2PStore]   新 status: null');
      }
      
      // 强制创建新的 KVNetworkStatus 实例以确保 signals 检测到变化
      if (status != null) {
        networkStatus.value = KVNetworkStatus(
          totalNodes: status.totalNodes,
          nodes: List.from(status.nodes), // 创建新的列表副本
        );
        
        // 过滤掉公共服务器节点，只保留普通用户节点
        final userNodesList = status.nodes
            .where((node) => !node.hostname.contains('PublicServer'))
            .toList();
        userNodes.value = userNodesList;
        
        debugPrint('[P2PStore] userNodes 数量: ${userNodesList.length}');
        
        // 构建增强节点信息列表，保留已发现的头像端口
        final enhancedNodes = <EnhancedNodeInfo>[];
        for (final node in userNodesList) {
          // 查找是否已有缓存的增强信息
          EnhancedNodeInfo enhancedNode;
          final existingIndex = enhancedUserNodes.value.indexWhere((n) => n.peerId == node.peerId);
          
          if (existingIndex != -1) {
            // 找到已存在的节点，保留其 avatarPort
            final existingNode = enhancedUserNodes.value[existingIndex];
            enhancedNode = existingNode.copyWith(baseInfo: node);
            debugPrint('[P2PStore] 复用节点 ${node.hostname} 的端口: ${existingNode.avatarPort}');
          } else {
            // 新节点，创建新的 EnhancedNodeInfo
            enhancedNode = EnhancedNodeInfo.fromKVNodeInfo(node);
            debugPrint('[P2PStore] 创建新节点: ${node.hostname}');
          }
          
          enhancedNodes.add(enhancedNode);
        }
        
        debugPrint('[P2PStore] 准备更新 enhancedUserNodes: ${enhancedNodes.length} 个节点');
        enhancedUserNodes.value = List.from(enhancedNodes); // 强制创建新列表实例
        debugPrint('[P2PStore] enhancedUserNodes 已更新');
      } else {
        networkStatus.value = null;
        userNodes.value = [];
        enhancedUserNodes.value = [];
        debugPrint('[P2PStore] status 为 null，清空所有列表');
      }
      
      if (status != null) {
        debugPrint('[P2PStore]   更新后 networkStatus.value: ${status.nodes.length} 个节点');
        debugPrint('[P2PStore] 轮询网络状态: ${status.nodes.length} 个节点');
        for (var node in status.nodes) {
          debugPrint('[P2PStore]   节点: ${node.hostname} - ${node.ipv4}');
        }
      } else {
        debugPrint('[P2PStore]   更新后 networkStatus.value: null');
      }
    } catch (e) {
      debugPrint('[P2PStore] 轮询网络状态失败: $e');
    }
  }

  void dispose() {
    _stopPolling();
  }
}
