part of 'package:astral/ui/pages/dashboard_page.dart';

class _TrafficCard extends StatelessWidget {
  final String instancePath;
  final GlobalP2PStore p2pStore;

  const _TrafficCard({
    super.key,
    required this.instancePath,
    required this.p2pStore,
  });

  String _formatRate(double bytesPerSec) {
    final bitsPerSec = bytesPerSec * 8;
    if (bitsPerSec < 1000) {
      return '${bitsPerSec.toStringAsFixed(0)} bps';
    } else if (bitsPerSec < 1000 * 1000) {
      return '${(bitsPerSec / 1000).toStringAsFixed(1)} Kbps';
    } else if (bitsPerSec < 1000 * 1000 * 1000) {
      return '${(bitsPerSec / (1000 * 1000)).toStringAsFixed(1)} Mbps';
    } else {
      return '${(bitsPerSec / (1000 * 1000 * 1000)).toStringAsFixed(1)} Gbps';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      final traffic = p2pStore.trafficByPath.value[instancePath];
      final rxRate = traffic?.rxRate ?? 0;
      final txRate = traffic?.txRate ?? 0;
      final rxHistory = traffic?.rxHistory ?? [];
      final totalRate = rxRate + txRate;

      return _DashboardCard(
        title: '最近 60 秒流量',
        subtitle: '实时吞吐与波动',
        trailing: Text(
          _formatRate(totalRate),
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        contentPadding: EdgeInsets.zero,
        child: SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrafficPainter(
              data: rxHistory.isNotEmpty ? rxHistory : List.filled(20, 0),
              strokeColor: colorScheme.primary,
              fillColor: colorScheme.primary.withOpacity(0.18),
            ),
          ),
        ),
      );
    });
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
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    const minDistance = 16.0;
    final safeMinDistance = size.height > minDistance * 2 ? minDistance : 0.0;

    final maxValue = data.reduce(max);
    final minValue = data.reduce(min);
    final range = (maxValue - minValue).abs() < 0.001
        ? 1.0
        : maxValue - minValue;

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final normalized = (data[i] - minValue) / range;
      var y = size.height - normalized * size.height;
      if (safeMinDistance > 0) {
        y = y.clamp(safeMinDistance, size.height - safeMinDistance);
      }
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
        colors: [fillColor.withOpacity(0.42), fillColor.withOpacity(0.0)],
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
    return !ListEquality().equals(oldDelegate.data, data);
  }
}
