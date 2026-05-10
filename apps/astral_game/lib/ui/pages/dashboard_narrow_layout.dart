import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/config/constants.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/connection_service.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:astral_game/ui/widgets/dashboard_main_card_narrow.dart';
import 'package:astral_game/ui/pages/dashboard_history_item.dart';
import 'package:astral_game/ui/pages/dashboard_user_item.dart';
import 'package:astral_game/data/models/enhanced_node_info.dart';
import 'package:astral_game/data/models/room_mod.dart';

/// 仪表盘窄屏布局：单页纵向滚动（MD3 单列 + 分区）。
///
/// 设计思路（窄屏常见范式）：
/// - **一层滚动**：主卡片与下方列表同一 ScrollView，避免分页跳转感。
/// - **主次分区**：上方「房间 / 网络」主卡片；下方 **次要列表** 独立区块标题 + `surfaceContainerLow` 容器，层次清晰。
/// - **吸顶标题**：列表区标题用 [SliverPersistentHeader] 钉在顶部，长列表时仍能知道当前在看什么。
class DashboardNarrowLayout extends StatelessWidget {
  const DashboardNarrowLayout({
    super.key,
    required this.nodeManagement,
    required this.connectionService,
    required this.currentRoomShareCode,
    required this.onSettings,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onShareRoom,
    required this.onDisconnect,
    required this.onRemoveRoom,
    required this.onJoinHistory,
  });

  final NodeManagementService nodeManagement;
  final ConnectionService connectionService;
  final String? currentRoomShareCode;
  final VoidCallback onSettings;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final VoidCallback onShareRoom;
  final VoidCallback onDisconnect;
  final void Function(RoomMod) onRemoveRoom;
  final void Function(String) onJoinHistory;

  static const double _sectionHeaderHeight = 52;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isConnected = nodeManagement.isRunning;
      final nodes = nodeManagement.userNodes.value;
      final history = getIt<RoomState>().rooms;

      return CustomScrollView(
        key: const PageStorageKey<String>('dashboard_narrow_scroll'),
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _MainCardBlock(
                nodeManagement: nodeManagement,
                currentRoomShareCode: currentRoomShareCode,
                onSettings: onSettings,
                onCreateRoom: onCreateRoom,
                onJoinRoom: onJoinRoom,
                onShareRoom: onShareRoom,
                onDisconnect: onDisconnect,
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SectionHeaderDelegate(
              height: _sectionHeaderHeight,
              child: _SectionTitleBar(
                isConnected: isConnected,
                onlineCount: nodes.length,
                historyCount: history.length,
              ),
            ),
          ),
          if (isConnected)
            _usersSliver(context, nodes)
          else
            _historySliver(context, history),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      );
    });
  }

  Widget _usersSliver(BuildContext context, List<EnhancedNodeInfo> enhancedNodes) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (enhancedNodes.isEmpty) {
      return SliverToBoxAdapter(
        child: _SectionSurface(
          child: _EmptyHint(
            icon: Icons.people_outline,
            primary: '暂无在线用户',
            secondary: null,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList.builder(
        itemCount: enhancedNodes.length,
        itemBuilder: (context, index) {
          final node = enhancedNodes[index];
          return DashboardUserItem(
            key: ValueKey<int>(node.peerId),
            node: node,
          );
        },
      ),
    );
  }

  Widget _historySliver(BuildContext context, List<RoomMod> history) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (history.isEmpty) {
      return SliverToBoxAdapter(
        child: _SectionSurface(
          child: _EmptyHint(
            icon: Icons.history_outlined,
            primary: '暂无加入历史',
            secondary: '创建或加入房间后会显示在这里',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final room = history[index];
          return DashboardDismissibleHistoryItem(
            room: room,
            onJoin: () => onJoinHistory(room.shareCode),
            onRemove: onRemoveRoom,
          );
        },
      ),
    );
  }
}

class _MainCardBlock extends StatelessWidget {
  const _MainCardBlock({
    required this.nodeManagement,
    required this.currentRoomShareCode,
    required this.onSettings,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onShareRoom,
    required this.onDisconnect,
  });

  final NodeManagementService nodeManagement;
  final String? currentRoomShareCode;
  final VoidCallback onSettings;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final VoidCallback onShareRoom;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isConnected = nodeManagement.isRunning;
      final myIp = nodeManagement.myVirtualIpv4.value;
      final virtualIp =
          myIp.isNotEmpty ? myIp : AppConstants.defaultVirtualIp;
      final username = nodeManagement.currentUsername.value;
      final avatar = nodeManagement.currentUserAvatar.value;

      return DashboardMainCardNarrow(
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
    });
  }
}

/// 列表区外包一层 MD3 tonal surface，与主卡片区分层次。
class _SectionSurface extends StatelessWidget {
  const _SectionSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _SectionTitleBar extends StatelessWidget {
  const _SectionTitleBar({
    required this.isConnected,
    required this.onlineCount,
    required this.historyCount,
  });

  final bool isConnected;
  final int onlineCount;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = isConnected ? '在线用户' : '加入历史';
    final badge = isConnected ? onlineCount : historyCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.people_outline : Icons.history_outlined,
            size: 22,
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (badge > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            isConnected ? '本房间成员' : '最近加入的房间',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SectionHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      elevation: overlapsContent ? 1 : 0,
      shadowColor: scheme.shadow,
      child: Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.colorScheme,
    required this.textTheme,
  });

  final IconData icon;
  final String primary;
  final String? secondary;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            primary,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (secondary != null) ...[
            const SizedBox(height: 8),
            Text(
              secondary!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
