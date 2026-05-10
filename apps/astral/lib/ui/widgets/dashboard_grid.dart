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
  int? _draggingIndex;
  int? _previewIndex;
  bool _hasReordered = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant DashboardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasReordered) {
      _items = List.from(widget.items);
    }
    _hasReordered = false;
  }

  List<DashboardGridItem> get _displayItems {
    if (_draggingIndex == null || _previewIndex == null || _draggingIndex == _previewIndex) {
      return _items;
    }
    final result = List<DashboardGridItem>.from(_items);
    final draggedItem = result.removeAt(_draggingIndex!);
    final insertIndex = _previewIndex! > _draggingIndex! ? _previewIndex! - 1 : _previewIndex!;
    result.insert(insertIndex, draggedItem);
    return result;
  }

  void _onDragStarted(int index) {
    setState(() {
      _draggingIndex = index;
      _previewIndex = index;
    });
  }

  void _onDragEnded() {
    if (_draggingIndex != null && _previewIndex != null && _draggingIndex != _previewIndex) {
      final fromIndex = _draggingIndex!;
      var toIndex = _previewIndex!;
      if (toIndex > fromIndex) toIndex--;
      final item = _items.removeAt(fromIndex);
      _items.insert(toIndex, item);
      _hasReordered = true;
      widget.onReorder?.call(_items.map((e) => e.id).toList());
    }
    _draggingIndex = null;
    _previewIndex = null;
    if (mounted) setState(() {});
  }

  void _onDragHover(int index) {
    if (_previewIndex != index) {
      setState(() => _previewIndex = index);
    }
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

        final displayItems = _displayItems;
        final draggingId = _draggingIndex != null ? _items[_draggingIndex!].id : null;

        return Wrap(
          spacing: widget.spacing,
          runSpacing: widget.spacing,
          children: [
            for (int i = 0; i < displayItems.length; i++)
              _buildItem(
                displayItems[i],
                i,
                columns,
                columnWidth,
                isDragging: displayItems[i].id == draggingId,
                originalIndex: _items.indexWhere((item) => item.id == displayItems[i].id),
              ),
          ],
        );
      },
    );
  }

  Widget _buildItem(
    DashboardGridItem item,
    int displayIndex,
    int columns,
    double columnWidth, {
    required bool isDragging,
    required int originalIndex,
  }) {
    final width = _itemWidth(item, columns, columnWidth, widget.spacing);
    final height = _itemHeight(item, widget.unitHeight, widget.spacing);

    if (!widget.isEditing) {
      return SizedBox(
        width: width,
        height: height,
        child: item.child,
      );
    }

    if (isDragging) {
      return _buildPlaceholder(width, height);
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        _onDragHover(displayIndex);
        return true;
      },
      onAcceptWithDetails: (details) {},
      builder: (context, candidateData, rejectedData) {
        final isHoverTarget = candidateData.isNotEmpty && _draggingIndex != null;
        return Draggable<int>(
          data: originalIndex,
          onDragStarted: () => _onDragStarted(originalIndex),
          onDragEnd: (_) => _onDragEnded(),
          onDraggableCanceled: (_, __) => _onDragEnded(),
          onDragCompleted: _onDragEnded,
          feedback: _buildFeedback(item, width, height),
          childWhenDragging: const SizedBox.shrink(),
          child: Container(
            width: width,
            height: height,
            decoration: isHoverTarget
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: Stack(
              children: [
                item.child,
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildHandle(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedback(DashboardGridItem item, double width, double height) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              item.child,
              Positioned(
                top: 8,
                right: 8,
                child: _buildHandle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.drag_handle,
        size: 16,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
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

double _itemHeight(
  DashboardGridItem item,
  double unitHeight,
  double runSpacing,
) {
  final span = item.heightSpan <= 0 ? 1 : item.heightSpan;
  return unitHeight * span + runSpacing * (span - 1);
}
