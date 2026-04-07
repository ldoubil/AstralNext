
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class DashboardCard extends StatefulWidget {
  final int widthSpan;
  final Widget? child;
  final double? fixedCellHeight;
  final bool? isBorder;

  const DashboardCard({
    super.key,
    required this.widthSpan,
    this.child,
    this.fixedCellHeight,
    this.isBorder = true,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return widget.fixedCellHeight != null
        ? StaggeredGridTile.extent(
            crossAxisCellCount: widget.widthSpan,
            mainAxisExtent: widget.fixedCellHeight!,
            child: _buildContent(theme),
          )
        : StaggeredGridTile.fit(
            crossAxisCellCount: widget.widthSpan,
            child: _buildContent(theme),
          );
  }

  Widget _buildContent(ThemeData theme) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.isBorder ?? true ? 8 : 1),
          side: BorderSide(
            color: isHovered ? theme.colorScheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.all(widget.isBorder ?? true ? 12 : 1.0),
            height: widget.fixedCellHeight,
            width: double.infinity,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

