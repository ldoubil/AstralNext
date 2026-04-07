import 'dart:async';
import 'package:flutter/material.dart';
import '../pages/rooms/room_mod.dart';
import '../pages/rooms/room_state.dart';

class CanvasJump {
  static void show(
    BuildContext context, {
    required Function(RoomMod) onSelect,
  }) {
    final rooms = roomState.rooms.value;
    if (rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂无可用房间，请先在房间页面创建房间'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => _CanvasDialog(rooms: rooms, onSelect: onSelect),
    );
  }
}

class _CanvasDialog extends StatefulWidget {
  final List<RoomMod> rooms;
  final Function(RoomMod) onSelect;

  const _CanvasDialog({required this.rooms, required this.onSelect});

  @override
  State<_CanvasDialog> createState() => _CanvasDialogState();
}

class _CanvasDialogState extends State<_CanvasDialog> {
  late List<RoomMod> _filteredRooms;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  Timer? _scrollTimer;
  String _currentHoveredRoomName = '';
  RoomMod? _selectedRoom;

  @override
  void initState() {
    super.initState();
    _filteredRooms = widget.rooms;
    _selectedRoom = roomState.selectedRoom.value;
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_isScrolling) {
      setState(() => _isScrolling = true);
    }
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isScrolling = false);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _filterRooms(String query) {
    setState(() {
      _filteredRooms = widget.rooms
          .where((room) => room.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;

    return AlertDialog(
      titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actionsPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.meeting_room, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '选择房间',
            style: TextStyle(fontSize: 18, color: colorScheme.primary),
          ),
        ],
      ),
      content: SizedBox(
        width: screenSize.width / 1.2,
        height: (screenSize.height / 2) + 12,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索房间',
                  prefixIcon: const Icon(Icons.search, size: 24),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _filterRooms,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 115,
              child: _filteredRooms.isEmpty
                  ? Center(
                      child: Text(
                        '没有找到匹配的房间',
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    )
                  : _buildRoomList(colorScheme),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '取消',
            style: TextStyle(fontSize: 16, color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomList(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: _isScrolling ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        trackVisibility: false,
                        thickness: 11,
                        radius: const Radius.circular(16),
                        interactive: true,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = _filteredRooms[index];
                      final isHovered = _currentHoveredRoomName == room.name;
                      final isSelected = _selectedRoom?.id == room.id;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: MouseRegion(
                          onEnter: (_) => setState(() {
                            _currentHoveredRoomName = room.name;
                          }),
                          onExit: (_) => setState(() {
                            _currentHoveredRoomName = '';
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: isHovered
                                  ? colorScheme.primaryContainer
                                      .withValues(alpha: 0.12)
                                  : isSelected
                                      ? colorScheme.primaryContainer
                                          .withValues(alpha: 0.08)
                                      : Theme.of(context).brightness ==
                                              Brightness.light
                                          ? colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.95)
                                          : colorScheme.surfaceContainerHighest
                                              .withValues(alpha: 0.15),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : isHovered
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                width: isSelected ? 1.5 : 1.5,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                widget.onSelect(room);
                                Navigator.pop(context);
                              },
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                leading: Icon(
                                  Icons.meeting_room_outlined,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                title: Text(
                                  room.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  'UUID: ${room.uuid}',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: colorScheme.primary,
                                        size: 20,
                                      )
                                    else
                                      Icon(
                                        Icons.chevron_right,
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.6),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
