import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:astral_game/config/constants.dart';
import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';
import 'package:signals/signals_core.dart';
import 'package:astral_game/utils/logger.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNetworkStatus;

import '../models/enhanced_node_info.dart';
import 'app_settings_service.dart';
import 'node_net/node_net_client.dart';

/// 节点加入事件
class NodeJoinedEvent {
  final EnhancedNodeInfo node;
  NodeJoinedEvent(this.node);
}

/// 节点离开事件
class NodeLeftEvent {
  final int peerId;
  NodeLeftEvent(this.peerId);
}

/// 节点 IP 变更事件
class NodeIpChangedEvent {
  final EnhancedNodeInfo node;
  final String oldIp;
  final String newIp;
  NodeIpChangedEvent(this.node, this.oldIp, this.newIp);
}

/// 节点管理服务
///
/// 负责：
/// - 管理网络中的节点信息
/// - 轮询网络状态
/// - 获取节点头像和昵称
/// - 发送节点事件
class NodeManagementService {
  final _p2pService = GetIt.I<P2PService>();
  final _eventBus = GetIt.I<EventBus>();
  final _appSettings = GetIt.I<AppSettingsService>();

  /// 用户节点列表
  final userNodes = signal<List<EnhancedNodeInfo>>([]);
  
  /// 增强的用户节点列表（包含额外信息）
  final enhancedUserNodes = signal<List<EnhancedNodeInfo>>([]);
  
  /// 当前实例 ID
  final currentInstanceId = signal<String?>(null);
  
  /// 网络状态
  final networkStatus = signal<KVNetworkStatus?>(null);
  
  /// 当前用户头像
  final currentUserAvatar = signal<Uint8List?>(null);
  
  /// 当前用户名
  final currentUsername = signal<String>('');

  Timer? _pollingTimer;
  final Map<int, Timer> _ipReadyTimers = {};

  /// 轮询间隔（优化为 3 秒）
  static const Duration _pollingInterval = Duration(seconds: 3);

  String? get instanceId => currentInstanceId.value;
  bool get isRunning => currentInstanceId.value != null;

  /// 启动节点管理
  void start(String instanceId) {
    currentInstanceId.value = instanceId;
    _startPolling(instanceId);
    appLogger.i('[NodeManagementService] 已启动，实例ID: $instanceId');
  }

  /// 停止节点管理
  void stop() {
    _stopPolling();
    _cancelAllIpReadyTimers();
    currentInstanceId.value = null;
    userNodes.value = [];
    enhancedUserNodes.value = [];
    appLogger.i('[NodeManagementService] 已停止');
  }

  /// 开始轮询网络状态
  void _startPolling(String instanceId) {
    _stopPolling();
    _pollNetworkStatus(instanceId);
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _pollNetworkStatus(instanceId);
    });
  }

  /// 停止轮询
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// 取消所有 IP 就绪定时器
  void _cancelAllIpReadyTimers() {
    for (final timer in _ipReadyTimers.values) {
      timer.cancel();
    }
    _ipReadyTimers.clear();
  }

  /// 取消指定节点的 IP 就绪定时器
  void _cancelIpReadyTimer(int peerId) {
    _ipReadyTimers[peerId]?.cancel();
    _ipReadyTimers.remove(peerId);
  }

  /// 轮询网络状态
  ///
  /// 获取最新的网络状态和节点信息
  Future<void> _pollNetworkStatus(String instanceId) async {
    try {
      final status = await _p2pService.getNetworkStatus(instanceId);

      final newTotalNodes = status.totalNodes;
      final newNodesList = status.nodes;
      final prevStatus = networkStatus.value;
      if (prevStatus == null ||
          prevStatus.totalNodes != newTotalNodes ||
          prevStatus.nodes.length != newNodesList.length) {
        networkStatus.value = KVNetworkStatus(
          totalNodes: newTotalNodes,
          nodes: List.from(newNodesList),
        );
      }

      final currentNodes = Map<int, EnhancedNodeInfo>.fromEntries(
        userNodes.value.map((node) => MapEntry(node.peerId, node)),
      );

      final newNodes = <int, EnhancedNodeInfo>{};
      for (final node in newNodesList) {
        if (!node.hostname.contains(AppConstants.publicServerHostname)) {
          final port = _parsePortFromHostname(node.hostname);
          newNodes[node.peerId] = EnhancedNodeInfo(
            baseInfo: node,
            port: port,
          );
        }
      }

      final changed = _processNodeChanges(currentNodes, newNodes);
      if (changed) {
        enhancedUserNodes.value = List.from(userNodes.value);
      }
    } catch (e, stackTrace) {
      appLogger.e('[NodeManagementService] 轮询网络状态失败: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// 处理节点变化
  ///
  /// 返回 true 表示有实际变化
  bool _processNodeChanges(
    Map<int, EnhancedNodeInfo> currentNodes,
    Map<int, EnhancedNodeInfo> newNodes,
  ) {
    final joinedPeerIds = newNodes.keys.toSet().difference(currentNodes.keys.toSet());
    final leftPeerIds = currentNodes.keys.toSet().difference(newNodes.keys.toSet());
    final existingPeerIds = currentNodes.keys.toSet().intersection(newNodes.keys.toSet());

    if (joinedPeerIds.isEmpty && leftPeerIds.isEmpty && existingPeerIds.isEmpty) {
      return false;
    }

    bool changed = joinedPeerIds.isNotEmpty || leftPeerIds.isNotEmpty;

    // 构建新的节点列表，一次性赋值避免竞态
    final updatedNodes = List<EnhancedNodeInfo>.from(userNodes.value);

    // 处理新加入的节点
    for (final peerId in joinedPeerIds) {
      final node = newNodes[peerId]!;
      updatedNodes.add(node);
      _eventBus.fire(NodeJoinedEvent(node));
      _scheduleIpReadyCheck(node);
      appLogger.i('[NodeManagementService] 节点加入: ${node.hostname} (peerId: $peerId)');
    }

    // 处理离开的节点
    for (final peerId in leftPeerIds) {
      updatedNodes.removeWhere((n) => n.peerId == peerId);
      _cancelIpReadyTimer(peerId);
      _eventBus.fire(NodeLeftEvent(peerId));
      appLogger.i('[NodeManagementService] 节点离开: peerId: $peerId');
    }

    // 处理已存在的节点
    for (final peerId in existingPeerIds) {
      final currentNode = currentNodes[peerId]!;
      final newNode = newNodes[peerId]!;

      if (currentNode.ipv4 != newNode.ipv4) {
        changed = true;
        _eventBus.fire(NodeIpChangedEvent(newNode, currentNode.ipv4, newNode.ipv4));
        appLogger.i('[NodeManagementService] 节点IP变更: ${currentNode.ipv4} -> ${newNode.ipv4}');
        if (newNode.ipv4 != '0.0.0.0') {
          _fetchNodeInfo(newNode);
        }
      }

      final index = updatedNodes.indexWhere((n) => n.peerId == peerId);
      if (index != -1) {
        updatedNodes[index] = updatedNodes[index].copyWith(baseInfo: newNode.baseInfo);
      }
    }

    // 仅在有变化时赋值
    if (changed) {
      userNodes.value = updatedNodes;
    }
    return changed;
  }

  /// 从主机名解析端口号
  int? _parsePortFromHostname(String hostname) {
    try {
      return int.parse(hostname);
    } catch (e) {
      return null;
    }
  }

  /// 调度 IP 就绪检查
  ///
  /// 当节点 IP 为 0.0.0.0 时，等待 IP 分配完成后再获取节点信息
  void _scheduleIpReadyCheck(EnhancedNodeInfo node) {
    if (node.ipv4 != '0.0.0.0') {
      _fetchNodeInfo(node);
      _pushOwnInfoToNode(node);
      return;
    }

    _ipReadyTimers[node.peerId] = Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        final currentNode = userNodes.value.firstWhere(
          (n) => n.peerId == node.peerId,
          orElse: () => node,
        );

        if (currentNode.ipv4 != '0.0.0.0') {
          timer.cancel();
          _ipReadyTimers.remove(node.peerId);
          _fetchNodeInfo(currentNode);
          _pushOwnInfoToNode(currentNode);
        }
      },
    );
  }

  /// 获取节点信息（头像和昵称）
  Future<void> _fetchNodeInfo(EnhancedNodeInfo node) async {
    final ip = node.ipv4;
    final port = node.port ?? 4924;

    try {
      final client = GetIt.I<NodeNetClient>();
      final result = await client.call(ip, port, 'user.getInfo');

      if (result != null) {
        final name = result['name'] as String?;
        final avatarBytes = result['avatar'] != null
            ? base64Decode(result['avatar'] as String)
            : null;

        if (name != null || avatarBytes != null) {
          _updateNodeInfo(node.peerId, name: name, avatar: avatarBytes);
        }
      }
    } catch (e) {
      appLogger.e('[NodeManagementService] 获取节点信息失败 $ip:$port: $e');
    }
  }

  /// 推送自己的用户信息到指定节点
  Future<void> _pushOwnInfoToNode(EnhancedNodeInfo node) async {
    final ip = node.ipv4;
    final port = node.port ?? 4924;

    if (ip == '0.0.0.0') {
      appLogger.w('[NodeManagementService] 节点 ${node.hostname} IP 无效，无法推送用户信息');
      return;
    }

    final ownName = _appSettings.getUsername();
    final ownAvatar = _appSettings.getAvatar();

    final params = {
      'name': ownName,
      if (ownAvatar != null) 'avatar': base64Encode(ownAvatar),
    };

    final client = GetIt.I<NodeNetClient>();

    for (int retry = 0; retry < 3; retry++) {
      try {
        await client.notify(ip, port, 'user.update', params: params);
        appLogger.i('[NodeManagementService] 成功推送用户信息到节点 ${node.hostname} ($ip:$port)');
        return;
      } catch (e) {
        appLogger.w('[NodeManagementService] 推送用户信息到节点 ${node.hostname} 失败 (重试 $retry/3): $e');
        if (retry < 2) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    appLogger.e('[NodeManagementService] 推送用户信息到节点 ${node.hostname} 失败，已达最大重试次数');
  }

  /// 批量更新节点信息（头像和/或昵称），单次 signal 触发
  void _updateNodeInfo(int peerId, {String? name, Uint8List? avatar}) {
    userNodes.value = userNodes.value.map((n) {
      if (n.peerId == peerId) {
        return n.copyWith(
          customName: name ?? n.customName,
          avatar: avatar ?? n.avatar,
        );
      }
      return n;
    }).toList();
  }

  /// 更新节点自定义名称
  void updateNodeCustomName(int peerId, String name) {
    _updateNodeInfo(peerId, name: name);
  }

  /// 初始化用户信息
  ///
  /// 从持久化存储加载用户名和头像
  void initUserInfo() {
    currentUsername.value = _appSettings.getUsername();
    final avatar = _appSettings.getAvatar();
    if (avatar != null) {
      currentUserAvatar.value = avatar;
    }
    appLogger.i('[NodeManagementService] 用户信息已初始化: ${currentUsername.value}');
  }

  /// 设置运行状态
  void setRunning(String instanceId) {
    start(instanceId);
  }

  /// 设置停止状态
  void setStopped() {
    stop();
  }

  /// 检查 IP 是否有效
  bool isValidIp(String ip) {
    return ip != '0.0.0.0';
  }

  /// 检查是否为服务器节点
  bool isServerNode(String hostname) {
    return hostname.contains(AppConstants.publicServerHostname);
  }

  /// 检查是否为有效用户节点
  bool isValidUserNode(String ip, String hostname) {
    return isValidIp(ip) && !isServerNode(hostname);
  }

  /// 更新当前用户头像
  Future<void> updateCurrentUserAvatar(Uint8List? avatar) async {
    currentUserAvatar.value = avatar;
    if (avatar != null) {
      await _appSettings.setAvatar(avatar);
      appLogger.i('[NodeManagementService] 用户头像已更新');
    } else {
      await _appSettings.clearAvatar();
      appLogger.i('[NodeManagementService] 用户头像已清除');
    }
  }

  /// 更新当前用户名
  Future<void> updateCurrentUsername(String username) async {
    currentUsername.value = username;
    await _appSettings.setUsername(username);
    appLogger.i('[NodeManagementService] 用户名已更新: $username');
  }

  /// 释放资源
  void dispose() {
    stop();
    appLogger.i('[NodeManagementService] 资源已释放');
  }
}