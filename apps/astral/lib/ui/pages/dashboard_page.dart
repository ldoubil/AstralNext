// lib/ui/pages/dashboard_page.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            padding: const EdgeInsets.fromLTRB(56, 44, 56, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroTitle(colorScheme: colorScheme),
                const SizedBox(height: 16),
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
                const Spacer(),
                Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _MetricCard(
                          title: '在线节点',
                          value: '128',
                          accent: Color(0xFF7BD7FF),
                        ),
                        _MetricCard(
                          title: '平均延迟',
                          value: '24ms',
                          accent: Color(0xFFFFD47B),
                        ),
                        _MetricCard(
                          title: '稳定性',
                          value: '99.98%',
                          accent: Color(0xFF98FFA7),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 700.ms, delay: 300.ms)
                    .move(begin: const Offset(0, 12)),
              ],
            ),
          ),
        ],
      ),
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
            duration: const Duration(milliseconds: 2400),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
