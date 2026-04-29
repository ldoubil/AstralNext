import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:signals/signals_core.dart';
import 'package:http/http.dart' as http;
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNetworkStatus;

import '../models/enhanced_node_info.dart';
import 'app_settings_service.dart';

class NodeJoinedEvent {
  final EnhancedNodeInfo node;
  NodeJoinedEvent(this.node);
}

class NodeLeftEvent {
  final int peerId;
  NodeLeftEvent(this.peerId);
}

class NodeIpChangedEvent {
  final EnhancedNodeInfo node;
  final String oldIp;
  final String newIp;
  NodeIpChangedEvent(this.node, this.oldIp, this.newIp);
}

class NodeManagementService {
  final _p2pService = GetIt.I<P2PService>();
  final _eventBus = GetIt.I<EventBus>();
  final _appSettings = GetIt.I<AppSettingsService>();

  final userNodes = signal<List<EnhancedNodeInfo>>([]);
  final enhancedUserNodes = signal<List<EnhancedNodeInfo>>([]);
  final currentInstanceId = signal<String?>(null);
  final networkStatus = signal<KVNetworkStatus?>(null);
  final currentUserAvatar = signal<Uint8List?>(null);
  final currentUsername = signal<String>('');

  Timer? _pollingTimer;
  final Map<int, Timer> _ipReadyTimers = {};

  String? get instanceId => currentInstanceId.value;
  bool get isRunning => currentInstanceId.value != null;

  void start(String instanceId) {
    currentInstanceId.value = instanceId;
    _startPolling(instanceId);
  }

  void stop() {
    _stopPolling();
    _cancelAllIpReadyTimers();
    currentInstanceId.value = null;
    userNodes.value = [];
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

  void _cancelAllIpReadyTimers() {
    for (final timer in _ipReadyTimers.values) {
      timer.cancel();
    }
    _ipReadyTimers.clear();
  }

  void _cancelIpReadyTimer(int peerId) {
    _ipReadyTimers[peerId]?.cancel();
    _ipReadyTimers.remove(peerId);
  }

  Future<void> _pollNetworkStatus(String instanceId) async {
    try {
      final status = await _p2pService.getNetworkStatus(instanceId);

      if (status != null) {
        networkStatus.value = KVNetworkStatus(
          totalNodes: status.totalNodes,
          nodes: List.from(status.nodes),
        );

        final currentNodes = Map<int, EnhancedNodeInfo>.fromEntries(
          userNodes.value.map((node) => MapEntry(node.peerId, node)),
        );

        final newNodes = <int, EnhancedNodeInfo>{};
        for (final node in status.nodes) {
          if (!node.hostname.contains('PublicServer')) {
            final port = _parsePortFromHostname(node.hostname);
            newNodes[node.peerId] = EnhancedNodeInfo(
              baseInfo: node,
              port: port,
            );
          }
        }

        final joinedPeerIds = newNodes.keys.toSet().difference(currentNodes.keys.toSet());
        final leftPeerIds = currentNodes.keys.toSet().difference(newNodes.keys.toSet());
        final existingPeerIds = currentNodes.keys.toSet().intersection(newNodes.keys.toSet());

        for (final peerId in joinedPeerIds) {
          final node = newNodes[peerId]!;
          userNodes.value = List.from(userNodes.value)..add(node);
          _eventBus.fire(NodeJoinedEvent(node));
          _scheduleIpReadyCheck(node);
        }

        for (final peerId in leftPeerIds) {
          userNodes.value = userNodes.value.where((n) => n.peerId != peerId).toList();
          _cancelIpReadyTimer(peerId);
          _eventBus.fire(NodeLeftEvent(peerId));
        }

        for (final peerId in existingPeerIds) {
          final currentNode = currentNodes[peerId]!;
          final newNode = newNodes[peerId]!;

          if (currentNode.ipv4 != newNode.ipv4) {
            _eventBus.fire(NodeIpChangedEvent(newNode, currentNode.ipv4, newNode.ipv4));
            if (newNode.ipv4 != '0.0.0.0') {
              _fetchNodeInfo(newNode);
            }
          }

          userNodes.value = userNodes.value.map((n) {
            if (n.peerId == peerId) {
              return n.copyWith(baseInfo: newNode.baseInfo);
            }
            return n;
          }).toList();
        }

        enhancedUserNodes.value = List.from(userNodes.value);
      } else {
        userNodes.value = [];
        enhancedUserNodes.value = [];
        networkStatus.value = null;
      }
    } catch (e) {
      debugPrint('[NodeManagementService] 轮询网络状态失败: $e');
    }
  }

  int? _parsePortFromHostname(String hostname) {
    try {
      return int.parse(hostname);
    } catch (e) {
      return null;
    }
  }

  void _scheduleIpReadyCheck(EnhancedNodeInfo node) {
    if (node.ipv4 != '0.0.0.0') {
      _fetchNodeInfo(node);
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
        }
      },
    );
  }

  Future<void> _fetchNodeInfo(EnhancedNodeInfo node) async {
    final ip = node.ipv4;
    final port = node.port ?? 4924;

    try {
      final avatarResponse = await http
          .get(Uri.http('$ip:$port', '/api/avatar'))
          .timeout(const Duration(seconds: 3));

      if (avatarResponse.statusCode == 200) {
        _updateNodeAvatar(node.peerId, avatarResponse.bodyBytes);
      }
    } catch (e) {
      debugPrint('[NodeManagementService] 获取头像失败 $ip:$port: $e');
    }

    try {
      final userResponse = await http
          .get(Uri.http('$ip:$port', '/api/user'))
          .timeout(const Duration(seconds: 3));

      if (userResponse.statusCode == 200) {
        final data = jsonDecode(userResponse.body);
        if (data is Map && data.containsKey('name')) {
          _updateNodeCustomName(node.peerId, data['name']);
        }
      }
    } catch (e) {
      debugPrint('[NodeManagementService] 获取昵称失败 $ip:$port: $e');
    }
  }

  void _updateNodeAvatar(int peerId, Uint8List avatar) {
    userNodes.value = userNodes.value.map((n) {
      if (n.peerId == peerId) {
        return n.copyWith(avatar: avatar);
      }
      return n;
    }).toList();
  }

  void _updateNodeCustomName(int peerId, String name) {
    updateNodeCustomName(peerId, name);
  }

  void updateNodeCustomName(int peerId, String name) {
    userNodes.value = userNodes.value.map((n) {
      if (n.peerId == peerId) {
        return n.copyWith(customName: name);
      }
      return n;
    }).toList();
  }

  void initUserInfo() {
    currentUsername.value = _appSettings.getUsername();
    final avatar = _appSettings.getAvatar();
    if (avatar != null) {
      currentUserAvatar.value = avatar;
    }
  }

  void setStarting() {}

  void setRunning(String instanceId) {
    start(instanceId);
  }

  void setStopped() {
    stop();
  }

  bool isValidIp(String ip) {
    return ip != '0.0.0.0';
  }

  bool isServerNode(String hostname) {
    return hostname.contains('PublicServer');
  }

  bool isValidUserNode(String ip, String hostname) {
    return isValidIp(ip) && !isServerNode(hostname);
  }

  String getNodeIpDisplayText(String ip) {
    return ip;
  }

  Future<void> updateCurrentUserAvatar(Uint8List? avatar) async {
    currentUserAvatar.value = avatar;
    if (avatar != null) {
      await _appSettings.setAvatar(avatar);
    } else {
      await _appSettings.clearAvatar();
    }
  }

  Future<void> updateCurrentUsername(String username) async {
    currentUsername.value = username;
    await _appSettings.setUsername(username);
  }

  void dispose() {
    stop();
  }
}