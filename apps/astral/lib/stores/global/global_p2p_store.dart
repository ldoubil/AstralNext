import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:signals/signals_core.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNetworkStatus;
import 'package:astral/data/services/log_service.dart';

class TrafficData {
  final int rxBytes;
  final int txBytes;
  final double rxRate;
  final double txRate;
  final List<double> rxHistory;
  final List<double> txHistory;
  final DateTime updatedAt;
  final int nodeCount;
  final double avgLatencyMs;
  final double avgLossRate;

  TrafficData({
    this.rxBytes = 0,
    this.txBytes = 0,
    this.rxRate = 0,
    this.txRate = 0,
    this.rxHistory = const [],
    this.txHistory = const [],
    DateTime? updatedAt,
    this.nodeCount = 0,
    this.avgLatencyMs = 0,
    this.avgLossRate = 0,
  }) : updatedAt = updatedAt ?? DateTime.now();

  TrafficData copyWith({
    int? rxBytes,
    int? txBytes,
    double? rxRate,
    double? txRate,
    List<double>? rxHistory,
    List<double>? txHistory,
    DateTime? updatedAt,
    int? nodeCount,
    double? avgLatencyMs,
    double? avgLossRate,
  }) {
    return TrafficData(
      rxBytes: rxBytes ?? this.rxBytes,
      txBytes: txBytes ?? this.txBytes,
      rxRate: rxRate ?? this.rxRate,
      txRate: txRate ?? this.txRate,
      rxHistory: rxHistory ?? this.rxHistory,
      txHistory: txHistory ?? this.txHistory,
      updatedAt: updatedAt ?? this.updatedAt,
      nodeCount: nodeCount ?? this.nodeCount,
      avgLatencyMs: avgLatencyMs ?? this.avgLatencyMs,
      avgLossRate: avgLossRate ?? this.avgLossRate,
    );
  }
}

class GlobalP2PStore {
  final _p2pService = GetIt.I<P2PService>();
  final _logService = GetIt.I<LogService>();
  final version = Signal<String>("");

  final instanceIdByPath = Signal<Map<String, String>>({});
  final pathByInstanceId = Signal<Map<String, String>>({});
  final startTimeByPath = Signal<Map<String, DateTime>>({});
  final startingPaths = Signal<Set<String>>({});
  final trafficByPath = Signal<Map<String, TrafficData>>({});
  final networkStatusByPath = Signal<Map<String, KVNetworkStatus>>({});

  final Map<String, Timer> _pollingTimers = {};
  final Map<String, int> _lastRxBytes = {};
  final Map<String, int> _lastTxBytes = {};
  final Map<String, DateTime> _lastUpdateTime = {};

  RawDatagramSocket? _eventSocket;
  StreamSubscription? _eventSubscription;

  GlobalP2PStore() {
    _p2pService.easytierVersion().then((v) {
      version.value = v;
    });
    _startEventListener();
  }

  void _startEventListener() {
    try {
      RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 9999).then((socket) {
        _eventSocket = socket;
        _eventSubscription = socket.listen(_handleEvent);
        debugPrint('[P2P事件] 开始监听 UDP 端口 9999');
      });
    } catch (e) {
      debugPrint('[P2P事件] 无法绑定 UDP 端口 9999: $e');
    }
  }

  void _handleEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _eventSocket?.receive();
      if (datagram != null) {
        final message = utf8.decode(datagram.data);
        try {
          final decoded = jsonDecode(message);
          if (decoded is Map<String, dynamic>) {
            final instanceId = decoded['instance_id'] as String?;
            final logMessage = decoded['message'] as String?;
            if (instanceId != null && logMessage != null) {
              final instancePath = pathByInstanceId.value[instanceId];
              debugPrint('[P2P事件] [$instanceId] $logMessage');
              _logService.info('P2P', logMessage, instancePath: instancePath);
              return;
            }
          }
        } catch (_) {
          // Fallback: treat as plain text if JSON parse fails
        }
        debugPrint('[P2P事件] $message');
      }
    }
  }

  void setStarting(String path, bool starting) {
    final set = Set<String>.from(startingPaths.value);
    if (starting) {
      set.add(path);
    } else {
      set.remove(path);
    }
    startingPaths.value = set;
  }

  void setRunning(String path, String instanceId) {
    final ids = Map<String, String>.from(instanceIdByPath.value);
    final paths = Map<String, String>.from(pathByInstanceId.value);
    final times = Map<String, DateTime>.from(startTimeByPath.value);
    ids[path] = instanceId;
    paths[instanceId] = path;
    times[path] = DateTime.now();
    instanceIdByPath.value = ids;
    pathByInstanceId.value = paths;
    startTimeByPath.value = times;
    startTrafficPolling(path, instanceId);
  }

  void setStopped(String path) {
    final ids = Map<String, String>.from(instanceIdByPath.value);
    final paths = Map<String, String>.from(pathByInstanceId.value);
    final times = Map<String, DateTime>.from(startTimeByPath.value);
    final removedInstanceId = ids[path];
    ids.remove(path);
    if (removedInstanceId != null) {
      paths.remove(removedInstanceId);
    }
    times.remove(path);
    instanceIdByPath.value = ids;
    pathByInstanceId.value = paths;
    startTimeByPath.value = times;
    stopTrafficPolling(path);
    _clearTrafficData(path);
  }

  bool isRunning(String path) {
    return instanceIdByPath.value.containsKey(path);
  }

  String? getInstanceId(String path) {
    return instanceIdByPath.value[path];
  }

  DateTime? getStartTime(String path) {
    return startTimeByPath.value[path];
  }

  bool isStarting(String path) {
    return startingPaths.value.contains(path);
  }

  TrafficData? getTraffic(String path) {
    return trafficByPath.value[path];
  }

  void startTrafficPolling(String path, String instanceId) {
    stopTrafficPolling(path);
    _lastRxBytes[path] = 0;
    _lastTxBytes[path] = 0;
    _lastUpdateTime[path] = DateTime.now();

    _pollTraffic(path, instanceId);
    _pollingTimers[path] = Timer.periodic(const Duration(seconds: 1), (_) {
      _pollTraffic(path, instanceId);
    });
  }

  void stopTrafficPolling(String path) {
    _pollingTimers[path]?.cancel();
    _pollingTimers.remove(path);
    _lastRxBytes.remove(path);
    _lastTxBytes.remove(path);
    _lastUpdateTime.remove(path);
  }

  Future<void> _pollTraffic(String path, String instanceId) async {
    try {
      final status = await _p2pService.getNetworkStatus(instanceId);
      final nodes = status.nodes;

      final statusMap = Map<String, KVNetworkStatus>.from(networkStatusByPath.value);
      statusMap[path] = status;
      networkStatusByPath.value = statusMap;

      int totalRx = 0;
      int totalTx = 0;
      double totalLatency = 0;
      double totalLoss = 0;
      int latencyCount = 0;

      for (final node in nodes) {
        totalRx += node.rxBytes.toInt();
        totalTx += node.txBytes.toInt();
        if (node.latencyMs > 0) {
          totalLatency += node.latencyMs;
          latencyCount++;
        }
        totalLoss += node.lossRate;
      }

      final now = DateTime.now();
      final lastRx = _lastRxBytes[path] ?? 0;
      final lastTx = _lastTxBytes[path] ?? 0;
      final lastTime = _lastUpdateTime[path] ?? now;
      final elapsed = now.difference(lastTime).inMilliseconds;

      double rxRate = 0;
      double txRate = 0;
      if (elapsed > 0) {
        rxRate = ((totalRx - lastRx) / elapsed * 1000).clamp(0, double.infinity);
        txRate = ((totalTx - lastTx) / elapsed * 1000).clamp(0, double.infinity);
      }

      _lastRxBytes[path] = totalRx;
      _lastTxBytes[path] = totalTx;
      _lastUpdateTime[path] = now;

      final current = trafficByPath.value[path] ?? TrafficData();
      final rxHistory = [...current.rxHistory, rxRate];
      final txHistory = [...current.txHistory, txRate];
      if (rxHistory.length > 60) rxHistory.removeAt(0);
      if (txHistory.length > 60) txHistory.removeAt(0);

      final newData = TrafficData(
        rxBytes: totalRx,
        txBytes: totalTx,
        rxRate: rxRate,
        txRate: txRate,
        rxHistory: rxHistory,
        txHistory: txHistory,
        updatedAt: now,
        nodeCount: nodes.length,
        avgLatencyMs: latencyCount > 0 ? totalLatency / latencyCount : 0,
        avgLossRate: nodes.isNotEmpty ? totalLoss / nodes.length : 0,
      );

      final map = Map<String, TrafficData>.from(trafficByPath.value);
      map[path] = newData;
      trafficByPath.value = map;
    } catch (e) {
      // ignore errors during polling
    }
  }

  void _clearTrafficData(String path) {
    final map = Map<String, TrafficData>.from(trafficByPath.value);
    map.remove(path);
    trafficByPath.value = map;

    final statusMap = Map<String, KVNetworkStatus>.from(networkStatusByPath.value);
    statusMap.remove(path);
    networkStatusByPath.value = statusMap;
  }

  void dispose() {
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();
    _eventSubscription?.cancel();
    _eventSocket?.close();
  }
}
