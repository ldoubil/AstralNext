part of 'package:astral/ui/pages/dashboard_page.dart';

class _InstanceSnapshot {
  final String name;
  final bool isConnected;
  final String virtualIp;
  final int nodeCount;
  final List<_NodeSnapshot> nodes;
  final int latencyMs;
  final double stability;
  final double throughputGbps;
  final Duration uptime;
  final double dailyTrafficTb;
  List<double> trafficData;

  _InstanceSnapshot({
    required this.name,
    required this.isConnected,
    required this.virtualIp,
    required this.nodeCount,
    required this.nodes,
    required this.latencyMs,
    required this.stability,
    required this.throughputGbps,
    required this.uptime,
    required this.dailyTrafficTb,
    required this.trafficData,
  });
}

class _NodeSnapshot {
  final String name;
  final String ip;
  final _NodeRouteMode route;
  final int latencyMs;
  final double packetLoss;

  const _NodeSnapshot({
    required this.name,
    required this.ip,
    required this.route,
    required this.latencyMs,
    required this.packetLoss,
  });
}

enum _NodeRouteMode { relay, punch }

extension _NodeRouteLabel on _NodeRouteMode {
  String get label => this == _NodeRouteMode.relay ? '中转' : '打洞';
}
