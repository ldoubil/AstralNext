import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/screen_state_service.dart';
import 'package:astral_game/ui/pages/rooms/room_state.dart';
import 'package:astral_game/ui/widgets/dashboard_main_card.dart';
import 'package:astral_game/ui/pages/dashboard_user_item.dart';
import 'package:astral_game/ui/pages/dashboard_history_item.dart';

class DashboardWideLayout extends StatelessWidget {
  final NodeManagementService p2pStore;
  final ScreenStateService screenStateService;
  final String? currentRoomUuid;
  final VoidCallback onSettings;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final VoidCallback onShareRoom;
  final VoidCallback onDisconnect;
  final void Function(String) onJoinHistory;

  const DashboardWideLayout({
    super.key,
    required this.p2pStore,
    required this.screenStateService,
    required this.currentRoomUuid,
    required this.onSettings,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onShareRoom,
    required this.onDisconnect,
    required this.onJoinHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 6, child: _buildLeftPanel(context)),
        Expanded(flex: 4, child: _buildRightPanel(context)),
      ],
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    return Watch((context) {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;
      final instanceId = p2pStore.currentInstanceId.value;
      final isRunning = instanceId != null;
      final isNarrow = screenStateService.isNarrow;

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withAlpha(50)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    isRunning ? Icons.people_outlined : Icons.history_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRunning ? '在线用户' : '加入历史',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              isNarrow
                  ? (isRunning
                        ? _buildUserListInline(context)
                        : _buildJoinHistory(context))
                  : Expanded(
                      child: isRunning
                          ? _buildUserListScrollable(context)
                          : _buildJoinHistoryScrollable(context),
                    ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRightPanel(BuildContext context) {
    return Watch((context) {
      final isConnected = p2pStore.isRunning;
      final status = p2pStore.networkStatus.value;
      final virtualIp = status?.nodes.firstOrNull?.ipv4 ?? '10.147.18.24';
      final username = p2pStore.currentUsername.value;
      final avatar = p2pStore.currentUserAvatar.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: DashboardMainCard(
                  isConnected: isConnected,
                  username: username,
                  userAvatar: avatar,
                  virtualIp: virtualIp,
                  roomUuid: currentRoomUuid,
                  onSettingsTap: onSettings,
                  onCreateRoomTap: onCreateRoom,
                  onJoinRoomTap: onJoinRoom,
                  onShareRoomTap: onShareRoom,
                  onDisconnectTap: onDisconnect,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildUserListInline(BuildContext context) {
    final enhancedNodes = p2pStore.enhancedUserNodes.value;

    if (enhancedNodes.isEmpty) {
      return _buildEmptyUserState(context);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: enhancedNodes.length,
      itemBuilder: (context, index) {
        return DashboardUserItem(
          node: enhancedNodes[index],
          p2pStore: p2pStore,
        );
      },
    );
  }

  Widget _buildUserListScrollable(BuildContext context) {
    final enhancedNodes = p2pStore.enhancedUserNodes.value;

    if (enhancedNodes.isEmpty) {
      return _buildEmptyUserState(context);
    }

    return ListView.builder(
      itemCount: enhancedNodes.length,
      itemBuilder: (context, index) {
        return DashboardUserItem(
          node: enhancedNodes[index],
          p2pStore: p2pStore,
        );
      },
    );
  }

  Widget _buildEmptyUserState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '暂无在线用户',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinHistory(BuildContext context) {
    return Watch((context) {
      final history = roomState.rooms;

      if (history.isEmpty) {
        return _buildEmptyHistoryState(context);
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: history
            .map(
              (room) => DashboardHistoryItem(
                room: room,
                onJoin: () => onJoinHistory(room.uuid),
              ),
            )
            .toList(),
      );
    });
  }

  Widget _buildJoinHistoryScrollable(BuildContext context) {
    return Watch((context) {
      final history = roomState.rooms;

      if (history.isEmpty) {
        return _buildEmptyHistoryState(context);
      }

      return ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) => DashboardHistoryItem(
          room: history[index],
          onJoin: () => onJoinHistory(history[index].uuid),
        ),
      );
    });
  }

  Widget _buildEmptyHistoryState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '暂无加入历史',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建或加入房间后会显示在这里',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
