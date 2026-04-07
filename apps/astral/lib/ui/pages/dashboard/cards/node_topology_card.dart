part of 'package:astral/ui/pages/dashboard_page.dart';

class _NodeTopologyCard extends StatelessWidget {
  final _InstanceSnapshot active;
  final _NodeSnapshot? selectedNode;

  const _NodeTopologyCard({
    super.key,
    required this.active,
    this.selectedNode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nodes = active.nodes;

    return _DashboardCard(
      title: '节点图',
      subtitle: '点击节点查看详情',
      headerPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      contentSpacing: 8,
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: nodes.isEmpty
            ? Center(
                child: Text(
                  '暂无节点',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              )
            : CustomPaint(
                painter: _NodeTopologyPainter(
                  nodes: nodes,
                  colorScheme: colorScheme,
                  selectedNodeName: selectedNode?.name,
                ),
              ),
      ),
    );
  }
}

class _NodeTopologyPainter extends CustomPainter {
  final List<_NodeSnapshot> nodes;
  final ColorScheme colorScheme;
  final String? selectedNodeName;

  _NodeTopologyPainter({
    required this.nodes,
    required this.colorScheme,
    this.selectedNodeName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final nodeCount = min(nodes.length, 8);
    final radius = min(size.width, size.height) * 0.34;
    final labelRadius = radius + 16;

    final linePaint = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(0.6)
      ..strokeWidth = 1.2;
    final corePaint = Paint()..color = colorScheme.primary;
    final ringPaint = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final offsets = <Offset>[];
    for (var i = 0; i < nodeCount; i++) {
      final angle = (2 * pi * i / nodeCount) - (pi / 2);
      final nodeOffset = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      offsets.add(nodeOffset);
      final node = nodes[i];
      final isSelected = node.name == selectedNodeName;
      final nodeColor = node.route == _NodeRouteMode.relay
          ? colorScheme.tertiary
          : colorScheme.secondary;

      canvas.drawLine(center, nodeOffset, linePaint);

      if (isSelected) {
        canvas.drawCircle(
          nodeOffset,
          14,
          Paint()..color = nodeColor.withOpacity(0.2),
        );
      }

      canvas.drawCircle(nodeOffset, isSelected ? 8 : 6, Paint()..color = nodeColor);
      canvas.drawCircle(
        nodeOffset,
        isSelected ? 12 : 9.5,
        Paint()
          ..color = nodeColor.withOpacity(isSelected ? 0.25 : 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2 : 1.4,
      );

      final label = node.name;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontSize: isSelected ? 11 : 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * 0.4);
      var labelOffset = Offset(
        center.dx + cos(angle) * labelRadius - textPainter.width / 2,
        center.dy + sin(angle) * labelRadius - textPainter.height / 2,
      );
      labelOffset = Offset(
        labelOffset.dx.clamp(0, size.width - textPainter.width),
        labelOffset.dy.clamp(0, size.height - textPainter.height),
      );
      textPainter.paint(canvas, labelOffset);
    }

    if (offsets.length > 1) {
      final ringPath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (var i = 1; i < offsets.length; i++) {
        ringPath.lineTo(offsets[i].dx, offsets[i].dy);
      }
      ringPath.close();
      canvas.drawPath(ringPath, ringPaint);
    }

    canvas.drawCircle(center, 7.5, corePaint);
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..color = colorScheme.primary.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _NodeTopologyPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.selectedNodeName != selectedNodeName;
  }
}
