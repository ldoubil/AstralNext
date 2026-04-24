import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:signals/signals_core.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNetworkStatus;

class GlobalP2PStore {
  final _p2pService = GetIt.I<P2PService>();

  /// 当前连接的 instanceId（astral_game 同时只运行一个实例）
  final currentInstanceId = signal<String?>(null);

  /// 当前网络状态
  final networkStatus = signal<KVNetworkStatus?>(null);

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
      networkStatus.value = status;
      if (status != null) {
        debugPrint('[P2PStore] 轮询网络状态: ${status.nodes.length} 个节点');
        for (var node in status.nodes) {
          debugPrint('[P2PStore]   节点: ${node.hostname} - ${node.ipv4}');
        }
      }
    } catch (e) {
      debugPrint('[P2PStore] 轮询网络状态失败: $e');
    }
  }

  void dispose() {
    _stopPolling();
  }
}
