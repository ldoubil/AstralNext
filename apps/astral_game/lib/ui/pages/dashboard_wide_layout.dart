import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/config/constants.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/connection_service.dart';
import 'package:astral_game/data/services/screen_state_service.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:astral_game/ui/widgets/dashboard_main_card.dart';
import 'package:astral_game/ui/widgets/user_list_widget.dart';
import 'package:astral_game/ui/widgets/empty_state_widget.dart';
import 'package:astral_game/ui/pages/dashboard_history_item.dart';

/// 仪表盘宽屏布局
class DashboardWideLayout extends StatelessWidget {
  final NodeManagementService nodeManagement;
  final ConnectionService connectionService;
  final ScreenStateService screenStateService;
  final String? currentRoomShareCode;
  final VoidCallback onSettings;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final VoidCallback onShareRoom;
  final VoidCallback onDisconnect;
  final void Function(String) onJoinHistory;

  const DashboardWideLayout({
    super.key,
    required this.nodeManagement,
    required this.connectionService,
    required this.screenStateService,
    required this.currentRoomShareCode,
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
      final instanceId = nodeManagement.currentInstanceId.value;
      final isRunning = instanceId != null;
      final isNarrow = screenStateService.isNarrow;

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLarge,
           side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
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
                        ? UserListWidget(
                            users: nodeManagement.userNodes.value,
                            shrinkWrap: true,
                          )
                        : _buildJoinHistory(context, shrinkWrap: true))
                  : Expanded(
                      child: isRunning
                          ? UserListWidget(
                              users: nodeManagement.userNodes.value,
                              physics: const AlwaysScrollableScrollPhysics(),
                            )
                          : _buildJoinHistoryScrollable(context),
                    ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRightPanel(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Watch((context) {
                final isConnected = nodeManagement.isRunning;
                final myIp = nodeManagement.myVirtualIpv4.value;
                final virtualIp = myIp.isNotEmpty ? myIp : AppConstants.defaultVirtualIp;
                final username = nodeManagement.currentUsername.value;
                final avatar = nodeManagement.currentUserAvatar.value;

                return DashboardMainCard(
                  isConnected: isConnected,
                  username: username,
                  userAvatar: avatar,
                  virtualIp: virtualIp,
                  roomShareCode: currentRoomShareCode,
                  onSettingsTap: onSettings,
                  onCreateRoomTap: onCreateRoom,
                  onJoinRoomTap: onJoinRoom,
                  onShareRoomTap: onShareRoom,
                  onDisconnectTap: onDisconnect,
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJoinHistory(BuildContext context, {required bool shrinkWrap}) {
    return Watch((context) {
      final history = getIt<RoomState>().rooms;

      if (history.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.history_outlined,
          message: '暂无加入历史',
          subtitle: '创建或加入房间后会显示在这里',
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: history
            .map(
              (room) => DashboardHistoryItem(
                room: room,
                onJoin: () => onJoinHistory(room.shareCode),
              ),
            )
            .toList(),
      );
    });
  }

  Widget _buildJoinHistoryScrollable(BuildContext context) {
    return Watch((context) {
      final history = getIt<RoomState>().rooms;

      if (history.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.history_outlined,
          message: '暂无加入历史',
          subtitle: '创建或加入房间后会显示在这里',
        );
      }

      return ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) => DashboardHistoryItem(
          room: history[index],
          onJoin: () => onJoinHistory(history[index].shareCode),
        ),
      );
    });
  }
}
