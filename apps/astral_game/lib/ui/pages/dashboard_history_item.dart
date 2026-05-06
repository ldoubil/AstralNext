import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:astral_game/di.dart';
import 'package:astral_game/config/constants.dart';
import 'package:astral_game/data/services/connection_service.dart';
import 'package:astral_game/data/models/room_mod.dart';

class DashboardDismissibleHistoryItem extends StatefulWidget {
  final RoomMod room;
  final VoidCallback onJoin;
  final void Function(RoomMod) onRemove;

  const DashboardDismissibleHistoryItem({
    super.key,
    required this.room,
    required this.onJoin,
    required this.onRemove,
  });

  @override
  State<DashboardDismissibleHistoryItem> createState() =>
      _DashboardDismissibleHistoryItemState();
}

class _DashboardDismissibleHistoryItemState
    extends State<DashboardDismissibleHistoryItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: Key(widget.room.uuid),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outlined, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) {
        widget.onRemove(widget.room);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: StatefulBuilder(
            builder: (context, setState) {
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.room.uuid.isNotEmpty ? widget.onJoin : null,
                onHover: (hovering) {
                  setState(() => isHovered = hovering);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isHovered
                        ? colorScheme.primaryContainer.withValues(alpha: 0.08)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.meeting_room_outlined,
                          color: colorScheme.onPrimaryContainer,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.room.roomName,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.room.uuid.substring(0, 8),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DashboardHistoryItem extends StatefulWidget {
  final RoomMod room;
  final VoidCallback onJoin;

  const DashboardHistoryItem({
    super.key,
    required this.room,
    required this.onJoin,
  });

  @override
  State<DashboardHistoryItem> createState() => _DashboardHistoryItemState();
}

class _DashboardHistoryItemState extends State<DashboardHistoryItem> {
  bool isHovered = false;
  final _connectionService = getIt<ConnectionService>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.room.uuid.isNotEmpty ? widget.onJoin : null,
              onHover: (hovering) {
                setState(() => isHovered = hovering);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isHovered
                       ? colorScheme.primaryContainer.withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.meeting_room_outlined,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.room.name,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                              Text(
                                widget.room.uuid.length >= AppConstants.uuidDisplayLength
                                    ? '${widget.room.uuid.substring(0, AppConstants.uuidDisplayLength)}...'
                                    : (widget.room.uuid.isNotEmpty ? widget.room.uuid : '本地房间'),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: isHovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.copy_outlined,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: widget.room.uuid.isNotEmpty
                                ? () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: widget.room.uuid),
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('房间号已复制'),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outlined,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            onPressed: () async {
                              _connectionService.removeRoom(widget.room.id);
                              if (mounted) {
                                setState(() {});
                              }
                            },
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_outlined,
                      size: 16,
                       color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
