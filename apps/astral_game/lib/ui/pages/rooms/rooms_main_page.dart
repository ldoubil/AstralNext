import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'room_state.dart';
import 'room_card.dart';
import 'room_dialog.dart';
import 'connected_users_page.dart';

class RoomsMainPage extends StatefulWidget {
  const RoomsMainPage({super.key});

  @override
  State<RoomsMainPage> createState() => _RoomsMainPageState();
}

class _RoomsMainPageState extends State<RoomsMainPage> {
  late final dynamic _disposeRooms;
  late final dynamic _disposeIsConnected;
  late final dynamic _disposeSelectedRoom;
  bool isHovered = false;

  int _getColumnCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _disposeRooms = roomState.rooms.subscribe((_) {
      if (mounted) setState(() {});
    });
    _disposeIsConnected = roomState.isConnected.subscribe((_) {
      if (mounted) setState(() {});
    });
    _disposeSelectedRoom = roomState.selectedRoom.subscribe((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _disposeRooms();
    _disposeIsConnected();
    _disposeSelectedRoom();
    super.dispose();
  }

  Widget _buildRoomsView(BuildContext context, BoxConstraints constraints) {
    final rooms = roomState.rooms.value;
    final selectedRoom = roomState.selectedRoom.value;
    final columnCount = _getColumnCount(constraints.maxWidth);

    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无房间',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => showAddRoomDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('创建房间'),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: columnCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final isSelected = selectedRoom?.id == room.id;
              return RoomCard(
                room: room,
                isSelected: isSelected,
                onEdit: () {
                  showEditRoomDialog(context, room: room);
                },
                onDelete: () {
                  roomState.removeRoom(room.id);
                },
                onShare: () {
                  showShareRoomDialog(context, room: room);
                },
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).padding.bottom + 80,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = roomState.isConnected.value;
    final selectedRoom = roomState.selectedRoom.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('房间'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 连接后显示当前房间信息横幅
          if (selectedRoom != null && isConnected)
            MouseRegion(
              onEnter: (_) => setState(() => isHovered = true),
              onExit: (_) => setState(() => isHovered = false),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isHovered
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: double.infinity,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          // 点击复制房间信息（参考项目行为）
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text('当前房间: ${selectedRoom.name}'),
                          subtitle: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('连接状态: 已连接 (点击分享房间)'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: isConnected
                // 已连接：显示用户列表
                ? const ConnectedUsersPage()
                // 未连接：显示房间列表
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildRoomsView(context, constraints);
                    },
                  ),
          ),
        ],
      ),
      // 连接后不显示 FAB
      floatingActionButton: isConnected
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'paste',
                  onPressed: () => showImportRoomDialog(context),
                  tooltip: '导入房间',
                  child: const Icon(Icons.paste),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: 'add',
                  onPressed: () => showAddRoomDialog(context),
                  tooltip: '创建房间',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
    );
  }
}
