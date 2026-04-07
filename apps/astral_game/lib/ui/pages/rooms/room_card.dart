import 'package:flutter/material.dart';
import 'room_mod.dart';
import 'room_state.dart';

class RoomCard extends StatefulWidget {
  final RoomMod room;
  final bool isSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const RoomCard({
    super.key,
    required this.room,
    this.isSelected = false,
    this.onEdit,
    this.onDelete,
    this.onShare,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        color: widget.isSelected
            ? Theme.of(context).brightness == Brightness.dark
                ? HSLColor.fromColor(
                    colorScheme.primary,
                  ).withLightness(0.10).toColor()
                : HSLColor.fromColor(
                    colorScheme.primary,
                  ).withLightness(0.95).toColor()
            : colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: (widget.isSelected || _isHovered)
                ? colorScheme.primary
                : Colors.transparent,
            width: (_isHovered && !widget.isSelected) ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            roomState.selectRoom(room);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (widget.isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              room.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (widget.onShare != null)
                          IconButton(
                            icon: const Icon(Icons.share, size: 20),
                            onPressed: widget.onShare,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: '分享房间',
                          ),
                        if (widget.onShare != null &&
                            (widget.onDelete != null ||
                                widget.onEdit != null))
                          const SizedBox(width: 8),
                        if (widget.onDelete != null)
                          widget.isSelected
                              ? Tooltip(
                                  message: '不能删除正在连接的房间',
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    disabledColor: colorScheme.outline,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('确认删除'),
                                        content:
                                            const Text('确定要删除这个房间吗？'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              widget.onDelete?.call();
                                            },
                                            child: const Text(
                                              '删除',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: '删除房间',
                                ),
                        if (widget.onDelete != null && widget.onEdit != null)
                          const SizedBox(width: 8),
                        if (widget.onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: widget.onEdit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: '编辑房间',
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.fingerprint,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'UUID: ${room.uuid}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
