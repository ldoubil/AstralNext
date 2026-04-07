
import 'dart:math';

import 'package:flutter/material.dart';

class DashboardGridItem {
  final String id;
  final Widget child;
  final int widthSpan;
  final int heightSpan;

  const DashboardGridItem({
    required this.id,
    required this.child,
    this.widthSpan = 1,
    this.heightSpan = 1,
  });
}

class DashboardGrid extends StatefulWidget {
  final List<DashboardGridItem> items;
  final double unitWidth;
  final double unitHeight;
  final double spacing;
  final bool isEditing;
  final void Function(List<String> orderedIds)? onReorder;

  const DashboardGrid({
    super.key,
    required this.items,
    this.unitWidth = 300,
    this.unitHeight = 140,
    this.spacing = 16,
    this.isEditing = false,
    this.onReorder,
  });

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<DashboardGrid> {
  List<DashboardGridItem> _items = [];

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant DashboardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _items = List.from(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : widget.unitWidth;
        final columns = max(
          1,
          ((maxWidth + widget.spacing) / (widget.unitWidth + widget.spacing))
              .floor(),
        );
        final columnWidth =
            (maxWidth - widget.spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: widget.spacing,
          runSpacing: widget.spacing,
          children: [
            for (int i = 0; i < _items.length; i++)
              _buildItem(
                _items[i],
                i,
                columns,
                columnWidth,
              ),
          ],
        );
      },
    );
  }

  Widget _buildItem(
    DashboardGridItem item,
    int index,
    int columns,
    double columnWidth,
  ) {
    final width = _itemWidth(item, columns, columnWidth, widget.spacing);

    return SizedBox(
      width: width,
      child: item.child,
    );
  }
}

double _itemWidth(
  DashboardGridItem item,
  int columns,
  double columnWidth,
  double spacing,
) {
  final span = item.widthSpan <= 0 ? 1 : item.widthSpan;
  final clamped = span > columns ? columns : span;
  return columnWidth * clamped + spacing * (clamped - 1);
}

