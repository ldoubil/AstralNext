// lib/ui/pages/dashboard_page.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _random = Random();
  late List<_InstanceSnapshot> _instances;
  int _selectedInstanceIndex = 0;
  late final ValueNotifier<int> _trafficTick;
  Timer? _trafficTimer;

  @override
  void initState() {
    super.initState();
    _trafficTick = ValueNotifier(0);
    _instances = [
      _InstanceSnapshot(
        name: '实例-1',
        isConnected: true,
        nodeCount: 128,
        latencyMs: 24,
        stability: 99.98,
        trafficData: _buildTrafficSeed(),
      ),
      _InstanceSnapshot(
        name: '实例-2',
        isConnected: true,
        nodeCount: 96,
        latencyMs: 31,
        stability: 99.87,
        trafficData: _buildTrafficSeed(),
      ),
      _InstanceSnapshot(
        name: '实例-3',
        isConnected: false,
        nodeCount: 0,
        latencyMs: 0,
        stability: 0,
        trafficData: _buildTrafficSeed(),
      ),
    ];
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        for (final instance in _instances) {
          instance.trafficData = [
            ...instance.trafficData.sublist(1),
            20 + _random.nextDouble() * 40,
          ];
        }
        _trafficTick.value++;
      });
    });
  }

  List<double> _buildTrafficSeed() =>
      List<double>.generate(60, (index) => 20 + _random.nextDouble() * 40);

  @override
  void dispose() {
    _trafficTimer?.cancel();
    _trafficTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeInstance = _instances[_selectedInstanceIndex];
    final connectedCount = _instances
        .where((instance) => instance.isConnected)
        .length;
    return ClipRRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceVariant,
                    colorScheme.surfaceVariant.withOpacity(0.92),
                    const Color(0xFF0E1218),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: CustomPaint(painter: _StarfieldPainter()),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.2,
                child: CustomPaint(painter: _NebulaPainter()),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
          ),
          const Positioned(
            left: -120,
            top: -160,
            child: _GlowOrb(
              size: 320,
              colors: [Color(0xFF6EA8FF), Color(0x00162838)],
            ),
          ),
          const Positioned(
            right: -60,
            bottom: -120,
            child: _GlowOrb(
              size: 260,
              colors: [Color(0xFF9B7CFF), Color(0x001E152C)],
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: const SizedBox(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 12, 56, 48),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _HeroTitle(colorScheme: colorScheme)),
                      const SizedBox(width: 16),
                      _InstanceSwitcher(
                        instances: _instances,
                        selectedIndex: _selectedInstanceIndex,
                        connectedCount: connectedCount,
                        totalCount: _instances.length,
                        onSelected: (index) {
                          setState(() => _selectedInstanceIndex = index);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                        '故事不是人生指南，你喜欢，可能只是你遇过。',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.72),
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .move(begin: const Offset(0, 8)),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child:
                            _TrafficCard(
                                  title: '流量曲线',
                                  subtitle: '近 60 秒',
                                  data: activeInstance.trafficData,
                                  repaint: _trafficTick,
                                )
                                .animate()
                                .fadeIn(duration: 700.ms, delay: 260.ms)
                                .move(begin: const Offset(0, 10)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child:
                            Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _MetricCard(
                                      title: '在线实例',
                                      value: '${activeInstance.nodeCount}',
                                      accent: Color(0xFF7BD7FF),
                                    ),
                                    _MetricCard(
                                      title: '平均延迟',
                                      value: '${activeInstance.latencyMs}ms',
                                      accent: Color(0xFFFFD47B),
                                    ),
                                    _MetricCard(
                                      title: '稳定性',
                                      value:
                                          '${activeInstance.stability.toStringAsFixed(2)}%',
                                      accent: Color(0xFF98FFA7),
                                    ),
                                  ],
                                )
                                .animate()
                                .fadeIn(duration: 700.ms, delay: 320.ms)
                                .move(begin: const Offset(0, 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _ConnectButton(onPressed: () {})
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 420.ms)
                        .move(begin: const Offset(0, 8)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstanceSnapshot {
  _InstanceSnapshot({
    required this.name,
    required this.isConnected,
    required this.nodeCount,
    required this.latencyMs,
    required this.stability,
    required List<double> trafficData,
  }) : trafficData = trafficData;

  final String name;
  final bool isConnected;
  final int nodeCount;
  final int latencyMs;
  final double stability;
  List<double> trafficData;
}

class _InstanceSwitcher extends StatefulWidget {
  final List<_InstanceSnapshot> instances;
  final int selectedIndex;
  final int connectedCount;
  final int totalCount;
  final ValueChanged<int> onSelected;

  const _InstanceSwitcher({
    super.key,
    required this.instances,
    required this.selectedIndex,
    required this.connectedCount,
    required this.totalCount,
    required this.onSelected,
  });

  @override
  State<_InstanceSwitcher> createState() => _InstanceSwitcherState();
}

class _InstanceSwitcherState extends State<_InstanceSwitcher> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Colors.white.withOpacity(0.06)
        : colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : colorScheme.outlineVariant.withOpacity(0.7);
    final activeInstance = widget.instances[widget.selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PopupMenuButton<int>(
              onOpened: () => setState(() => _menuOpen = true),
              onCanceled: () => setState(() => _menuOpen = false),
              onSelected: (index) {
                setState(() => _menuOpen = false);
                widget.onSelected(index);
              },
              position: PopupMenuPosition.under,
              itemBuilder: (context) => [
                for (var i = 0; i < widget.instances.length; i++)
                  PopupMenuItem<int>(
                    value: i,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.instances[i].isConnected
                                ? const Color(0xFF98FFA7)
                                : const Color(0xFFFF8A7B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.instances[i].name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          widget.instances[i].isConnected ? '已连接' : '未连接',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              child: _InstanceSelector(
                name: activeInstance.name,
                isConnected: activeInstance.isConnected,
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                isExpanded: _menuOpen,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.connectedCount}/${widget.totalCount} 已连接',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InstanceSelector extends StatelessWidget {
  final String name;
  final bool isConnected;
  final Color backgroundColor;
  final Color borderColor;
  final bool isExpanded;

  const _InstanceSelector({
    required this.name,
    required this.isConnected,
    required this.backgroundColor,
    required this.borderColor,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = isConnected
        ? const Color(0xFF98FFA7)
        : const Color(0xFFFF8A7B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 16 : 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (isExpanded)
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.18),
              blurRadius: 16,
              spreadRadius: 0.5,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.expand_more,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    )
        .animate(target: isExpanded ? 1 : 0)
        .scaleXY(
          begin: 1,
          end: 1.02,
          duration: 180.ms,
          curve: Curves.easeOut,
        )
        .then()
        .shimmer(
          duration: 600.ms,
          color: colorScheme.primary.withOpacity(0.25),
        );
  }
}

class _HeroTitle extends StatelessWidget {
  final ColorScheme colorScheme;

  const _HeroTitle({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'Astral',
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 88,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.6,
      ),
    );

    return Animate(
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 500)),
        MoveEffect(begin: Offset(0, 12)),
      ],
      child: Animate(
        onPlay: (controller) => controller.repeat(),
        effects: [
          ShimmerEffect(
            duration: Duration(milliseconds: 2400),
            color: Colors.white.withOpacity(0.75),
            angle: 0.6,
          ),
        ],
        child: title,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : colorScheme.outlineVariant.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 18,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrafficCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> data;
  final Listenable repaint;

  const _TrafficCard({
    required this.title,
    required this.subtitle,
    required this.data,
    required this.repaint,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : colorScheme.outlineVariant.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrafficPainter(
                data: data,
                lineColor: const Color(0xFF79D7FF),
                glowColor: const Color(0x5579D7FF),
                repaint: repaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color glowColor;

  _TrafficPainter({
    required this.data,
    required this.lineColor,
    required this.glowColor,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue).abs() < 0.001
        ? 1.0
        : maxValue - minValue;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final normalized = (data[i] - minValue) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrafficPainter oldDelegate) {
    return !listEquals(oldDelegate.data, data);
  }
}

class _ConnectButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ConnectButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.12),
          width: 1,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GlowOrb({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.55);
    const stars = [
      Offset(0.1, 0.2),
      Offset(0.15, 0.35),
      Offset(0.22, 0.12),
      Offset(0.32, 0.28),
      Offset(0.38, 0.18),
      Offset(0.45, 0.42),
      Offset(0.58, 0.26),
      Offset(0.64, 0.12),
      Offset(0.72, 0.34),
      Offset(0.82, 0.18),
      Offset(0.9, 0.3),
      Offset(0.12, 0.72),
      Offset(0.24, 0.62),
      Offset(0.36, 0.76),
      Offset(0.52, 0.64),
      Offset(0.62, 0.78),
      Offset(0.74, 0.68),
      Offset(0.86, 0.74),
      Offset(0.08, 0.48),
      Offset(0.18, 0.52),
      Offset(0.28, 0.46),
      Offset(0.4, 0.56),
      Offset(0.5, 0.5),
      Offset(0.66, 0.46),
      Offset(0.78, 0.52),
      Offset(0.88, 0.44),
      Offset(0.2, 0.88),
      Offset(0.34, 0.9),
      Offset(0.48, 0.86),
      Offset(0.66, 0.9),
    ];

    for (final star in stars) {
      final center = Offset(size.width * star.dx, size.height * star.dy);
      canvas.drawCircle(center, 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x334B78FF),
          Color(0x00000000),
          Color(0x338C6BFF),
          Color(0x00000000),
        ],
        stops: [0, 0.4, 0.7, 1],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 80.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
