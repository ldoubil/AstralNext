import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:signals/signals_core.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNetworkStatus, KVNodeInfo;
import '../models/enhanced_node_info.dart';
import 'app_settings_service.dart';

class GlobalP2PStore {
  final _p2pService = GetIt.I<P2PService>();
  final _appSettings = GetIt.I<AppSettingsService>();

  /// 当前连接的 instanceId（astral_game 同时只运行一个实例）
  final currentInstanceId = signal<String?>(null);

  /// 当前网络状态
  final networkStatus = signal<KVNetworkStatus?>(null);

  /// 过滤后的用户节点列表（排除公共服务器节点）
  final userNodes = signal<List<KVNodeInfo>>([]);

  /// 增强的用户节点列表（包含自定义扩展信息）
  final enhancedUserNodes = signal<List<EnhancedNodeInfo>>([]);

  /// 当前用户的头像数据
  final currentUserAvatar = signal<Uint8List?>(null);

  /// 当前用户的名字
  final currentUsername = signal<String>('');

  Timer? _pollingTimer;

  String? get instanceId => currentInstanceId.value;
  bool get isRunning => currentInstanceId.value != null;

  /// 初始化用户信息（从持久化存储加载）
  void initUserInfo() {
    // 加载用户名（如果为空，AppSettingsService 会返回系统用户名或默认值）
    currentUsername.value = _appSettings.getUsername();
    
    // 加载头像
    final avatar = _appSettings.getAvatar();
    if (avatar != null) {
      currentUserAvatar.value = avatar;
    }
    
  }

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
    }
  }

  /// 更新节点的自定义名字
  void updateNodeCustomName(int peerId, String name) {
    final nodes = List<EnhancedNodeInfo>.from(enhancedUserNodes.value);
    final index = nodes.indexWhere((n) => n.peerId == peerId);
    
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(
        customName: name,
        lastNameFetch: DateTime.now(),
      );
      enhancedUserNodes.value = nodes;
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

  /// 更新当前用户的头像
  Future<void> updateCurrentUserAvatar(Uint8List? avatar) async {
    currentUserAvatar.value = avatar;
    
    // 持久化保存
    if (avatar != null) {
      await _appSettings.setAvatar(avatar);
    } else {
      await _appSettings.clearAvatar();
    }
    
  }

  /// 更新当前用户的名字
  Future<void> updateCurrentUsername(String username) async {
    currentUsername.value = username;
    
    // 持久化保存
    await _appSettings.setUsername(username);
    
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
          } else {
            // 新节点，创建新的 EnhancedNodeInfo
            enhancedNode = EnhancedNodeInfo.fromKVNodeInfo(node);
          }
          
          enhancedNodes.add(enhancedNode);
        }
        
        enhancedUserNodes.value = List.from(enhancedNodes);
      } else {
        networkStatus.value = null;
        userNodes.value = [];
        enhancedUserNodes.value = [];
      }
    } catch (e) {
      debugPrint('[P2PStore] 轮询网络状态失败: $e');
    }
  }

  void dispose() {
    _stopPolling();
  }
}
