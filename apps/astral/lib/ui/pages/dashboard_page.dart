import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _random = Random();
  late final ValueNotifier<int> _chartTick;
  late final List<_InstanceSnapshot> _instances;
  int _selectedIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _chartTick = ValueNotifier<int>(0);
    _instances = [
      _InstanceSnapshot(
        name: '实例-1',
        isConnected: true,
        virtualIp: '10.0.8.21',
        nodeCount: 128,
        latencyMs: 24,
        stability: 99.98,
        throughputGbps: 18.4,
        trafficData: _seedTraffic(),
      ),
      _InstanceSnapshot(
        name: '实例-2',
        isConnected: true,
        virtualIp: '10.0.8.33',
        nodeCount: 96,
        latencyMs: 31,
        stability: 99.87,
        throughputGbps: 14.9,
        trafficData: _seedTraffic(),
      ),
      _InstanceSnapshot(
        name: '实例-3',
        isConnected: false,
        virtualIp: '10.0.8.57',
        nodeCount: 0,
        latencyMs: 0,
        stability: 0,
        throughputGbps: 0,
        trafficData: _seedTraffic(),
      ),
    ];

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      for (final instance in _instances) {
        instance.trafficData = [
          ...instance.trafficData.sublist(1),
          20 + _random.nextDouble() * 40,
        ];
      }
      _chartTick.value++;
    });
  }

  List<double> _seedTraffic() =>
      List<double>.generate(60, (_) => 20 + _random.nextDouble() * 40);

  @override
  void dispose() {
    _timer?.cancel();
    _chartTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = _instances[_selectedIndex];
    final connectedCount = _instances
        .where((instance) => instance.isConnected)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        _PageHeader(
          title: 'Astral 控制台',
          subtitle: '面向多实例的统一控制与观测，遵循 MD3 无阴影色块分层。',
        ),
        const SizedBox(height: 12),
        _InstanceSelector(
          instances: _instances,
          selectedIndex: _selectedIndex,
          onSelected: (index) => setState(() => _selectedIndex = index),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 1000;
            final sideWidth = isWide
                ? min(420.0, constraints.maxWidth * 0.38)
                : constraints.maxWidth;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: _fadeSlide,
                      child: _TrafficCard(
                        key: ValueKey(active.name),
                        instance: active,
                        repaint: _chartTick,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: sideWidth,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: _fadeSlide,
                      child: _SideMetrics(
                        key: ValueKey('${active.name}-metrics'),
                        active: active,
                        connectedCount: connectedCount,
                        totalCount: _instances.length,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: _fadeSlide,
                  child: _TrafficCard(
                    key: ValueKey(active.name),
                    instance: active,
                    repaint: _chartTick,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: _fadeSlide,
                  child: _SideMetrics(
                    key: ValueKey('${active.name}-metrics'),
                    active: active,
                    connectedCount: connectedCount,
                    totalCount: _instances.length,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _InstancesOverview(instances: _instances),
        const SizedBox(height: 8),
        _FootNote(colorScheme: colorScheme),
      ],
    );
  }
}

Widget _fadeSlide(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: animation.drive(
        Tween(begin: const Offset(0, 0.04), end: Offset.zero).chain(
          CurveTween(curve: Curves.easeOut),
        ),
      ),
      child: child,
    ),
  );
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstanceSelector extends StatelessWidget {
  final List<_InstanceSnapshot> instances;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _InstanceSelector({
    required this.instances,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < instances.length; i++)
          ChoiceChip(
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            label: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  instances[i].name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selectedIndex == i
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  instances[i].virtualIp,
                  style: TextStyle(
                    fontSize: 12,
                    color: selectedIndex == i
                        ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            selected: selectedIndex == i,
            onSelected: (_) => onSelected(i),
            selectedColor: colorScheme.primaryContainer,
            backgroundColor: colorScheme.surfaceContainerLow,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
      ],
    );
  }
}

class _TrafficCard extends StatelessWidget {
  final _InstanceSnapshot instance;
  final Listenable repaint;

  const _TrafficCard({super.key, required this.instance, required this.repaint});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _DashboardCard(
      title: '最近 60 秒流量',
      subtitle: '实时吞吐与波动',
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(0, 0.08), end: Offset.zero).chain(
                CurveTween(curve: Curves.easeOut),
              ),
            ),
            child: child,
          ),
        ),
        child: Text(
          '${instance.throughputGbps.toStringAsFixed(1)} Gbps',
          key: ValueKey(instance.throughputGbps),
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      contentPadding: EdgeInsets.zero,
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: CustomPaint(
          painter: _TrafficPainter(
            data: instance.trafficData,
            strokeColor: colorScheme.primary,
            fillColor: colorScheme.primary.withOpacity(0.18),
            repaint: repaint,
          ),
        ),
      ),
    );
  }
}

class _SideMetrics extends StatelessWidget {
  final _InstanceSnapshot active;
  final int connectedCount;
  final int totalCount;

  const _SideMetrics(
      {super.key,
      required this.active,
      required this.connectedCount,
      required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardCard(
          title: '实例状态',
          subtitle: '整体连通性与 SLA',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricRow(
                label: '在线实例',
                value: '$connectedCount / $totalCount',
                accent: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: '当前延迟',
                value: '${active.latencyMs} ms',
                accent: colorScheme.secondary,
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: '稳定性',
                value: '${active.stability.toStringAsFixed(2)} %',
                accent: colorScheme.tertiary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DashboardCard(
          title: '路由摘要',
          subtitle: '虚拟 IP 与节点规模',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Pill(
                label: '节点数 ${active.nodeCount}',
                color: colorScheme.primary.withOpacity(0.15),
                foreground: colorScheme.primary,
              ),
              const SizedBox(height: 10),
              _Pill(
                label: '虚拟 IP ${active.virtualIp}',
                color: colorScheme.secondaryContainer,
                foreground: colorScheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstancesOverview extends StatelessWidget {
  final List<_InstanceSnapshot> instances;

  const _InstancesOverview({required this.instances});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: '实例概览',
      subtitle: '列表视角展示全部实例当前状态',
      child: Column(
        children: [
          for (final instance in instances) ...[
            _InstanceRow(instance: instance),
            if (instance != instances.last) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _InstanceRow extends StatelessWidget {
  final _InstanceSnapshot instance;

  const _InstanceRow({required this.instance});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = instance.isConnected
        ? colorScheme.primary
        : colorScheme.error;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instance.name,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${instance.virtualIp} · 节点 ${instance.nodeCount}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _Pill(
          label: instance.isConnected ? '已连接' : '未连接',
          color: statusColor.withOpacity(0.15),
          foreground: statusColor,
        ),
      ],
    );
  }
}

class _FootNote extends StatelessWidget {
  final ColorScheme colorScheme;

  const _FootNote({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '按 MD3 无阴影、无描边的色块层级进行布局。',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry contentPadding;
  final double contentSpacing;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.padding = EdgeInsets.zero,
    this.headerPadding = const EdgeInsets.all(18),
    this.contentPadding = const EdgeInsets.all(18),
    this.contentSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: headerPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            SizedBox(height: contentSpacing),
            Padding(
              padding: contentPadding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color foreground;

  const _Pill({
    required this.label,
    required this.color,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrafficPainter extends CustomPainter {
  final List<double> data;
  final Color strokeColor;
  final Color fillColor;

  _TrafficPainter({
    required this.data,
    required this.strokeColor,
    required this.fillColor,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxValue = data.reduce(max);
    final minValue = data.reduce(min);
    final range = (maxValue - minValue).abs() < 0.001 ? 1.0 : maxValue - minValue;

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final normalized = (data[i] - minValue) / range;
      final y = size.height - normalized * size.height;
      points.add(Offset(x, y));
    }

    Path buildSmoothPath(List<Offset> pts, {bool closeToBottom = false}) {
      final path = Path();
      if (pts.isEmpty) return path;
      path.moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final prev = pts[i - 1];
        final curr = pts[i];
        final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
        path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      }
      path.lineTo(pts.last.dx, pts.last.dy);
      if (closeToBottom) {
        path.lineTo(pts.last.dx, size.height);
        path.lineTo(pts.first.dx, size.height);
        path.close();
      }
      return path;
    }

    final areaPath = buildSmoothPath(points, closeToBottom: true);
    final linePath = buildSmoothPath(points);

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withOpacity(0.42),
          fillColor.withOpacity(0.0),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrafficPainter oldDelegate) {
    return !listEquals(oldDelegate.data, data);
  }
}

class _InstanceSnapshot {
  final String name;
  final bool isConnected;
  final String virtualIp;
  final int nodeCount;
  final int latencyMs;
  final double stability;
  final double throughputGbps;
  List<double> trafficData;

  _InstanceSnapshot(
      {required this.name,
      required this.isConnected,
      required this.virtualIp,
      required this.nodeCount,
      required this.latencyMs,
      required this.stability,
      required this.throughputGbps,
      required this.trafficData});
}
