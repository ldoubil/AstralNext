import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/config/constants.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/connection_service.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:astral_game/ui/widgets/dashboard_main_card.dart';
import 'package:astral_game/ui/pages/dashboard_history_item.dart';
import 'package:astral_game/ui/pages/dashboard_user_item.dart';
import 'package:astral_game/data/models/room_mod.dart';

/// 面板状态
enum PanelState {
  expanded,
  collapsed,
  dragging,
}

/// 仪表盘窄屏布局
class DashboardNarrowLayout extends StatefulWidget {
  final NodeManagementService nodeManagement;
  final ConnectionService connectionService;
  final String? currentRoomUuid;
  final VoidCallback onSettings;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final VoidCallback onShareRoom;
  final VoidCallback onDisconnect;
  final void Function(RoomMod) onRemoveRoom;

  const DashboardNarrowLayout({
    super.key,
    required this.nodeManagement,
    required this.connectionService,
    required this.currentRoomUuid,
    required this.onSettings,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onShareRoom,
    required this.onDisconnect,
    required this.onRemoveRoom,
  });

  @override
  State<DashboardNarrowLayout> createState() => _DashboardNarrowLayoutState();
}

class _DashboardNarrowLayoutState extends State<DashboardNarrowLayout> with SingleTickerProviderStateMixin {
  PanelState _panelState = PanelState.expanded;
  double _dividerPosition = 0.95;
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const double _collapsedHeight = 100;
  static const double _collapseThreshold = 0.6;
  static const double _dividerHeight = 20.0;
  static const double _minHeightRatio = 0.05;
  static const double _maxHeightRatio = 0.95;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(() {
      setState(() {
        _dividerPosition = _animation.value;
      });
    });

    effect(() {
      final isConnected = widget.nodeManagement.isRunning;
      if (isConnected && _panelState == PanelState.expanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _collapsePanel();
          }
        });
      }
    });
  }

  void _transitionTo(PanelState newState) {
    setState(() {
      _panelState = newState;
    });
  }

  void _collapsePanel() {
    if (_panelState == PanelState.collapsed) return;

    _transitionTo(PanelState.collapsed);

    _animation = Tween<double>(
      begin: _dividerPosition,
      end: _minHeightRatio,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final colorScheme = Theme.of(context).colorScheme;

        final currentTopHeight = totalHeight * _dividerPosition;
        final topHeightValue = _panelState == PanelState.collapsed 
            ? _collapsedHeight 
            : currentTopHeight;
        
        bool showBottomCard;
        if (_panelState == PanelState.dragging) {
          showBottomCard = true;
        } else {
          final bottomHeight = totalHeight - topHeightValue - _dividerHeight;
          showBottomCard = _panelState == PanelState.collapsed && bottomHeight > 0;
        }

        return Column(
          children: [
            ClipRect(
              child: SizedBox(
                height: topHeightValue,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: _buildRightPanelForNarrow(context),
                ),
              ),
            ),
            GestureDetector(
              onVerticalDragStart: (details) {
                setState(() {
                  final wasCollapsed = _panelState == PanelState.collapsed;
                  _transitionTo(PanelState.dragging);
                  if (wasCollapsed) {
                    _dividerPosition = _collapsedHeight / totalHeight;
                  }
                });
              },
              onVerticalDragUpdate: (details) {
                setState(() {
                  final delta = details.delta.dy;
                  _dividerPosition = (_dividerPosition + delta / totalHeight).clamp(_minHeightRatio, _maxHeightRatio);
                });
              },
              onVerticalDragEnd: (details) {
                final velocity = details.velocity.pixelsPerSecond.dy;
                double targetPosition;

                if (velocity < -800) {
                  targetPosition = _minHeightRatio;
                } else if (velocity > 800) {
                  targetPosition = _maxHeightRatio;
                } else {
                  targetPosition = _dividerPosition < _collapseThreshold ? _minHeightRatio : _maxHeightRatio;
                }

                setState(() {
                  if (targetPosition == _minHeightRatio) {
                    _transitionTo(PanelState.collapsed);
                  } else {
                    _transitionTo(PanelState.expanded);
                  }
                });

                _animation = Tween<double>(
                  begin: _dividerPosition,
                  end: targetPosition,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.elasticOut,
                ));

                _animationController.reset();
                _animationController.forward();
              },
              child: Container(
                height: _dividerHeight,
                decoration: BoxDecoration(
                  color: _panelState == PanelState.dragging
                      ? colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            if (showBottomCard)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 0),
                  child: _buildHistoryListForNarrow(context),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRightPanelForNarrow(BuildContext context) {
    return Watch((context) {
      final isConnected = widget.nodeManagement.isRunning;
      final status = widget.nodeManagement.networkStatus.value;
      final virtualIp = status?.nodes.firstOrNull?.ipv4 ?? AppConstants.defaultVirtualIp;
      final username = widget.nodeManagement.currentUsername.value;
      final avatar = widget.nodeManagement.currentUserAvatar.value;

      return DashboardMainCard(
        isConnected: isConnected,
        username: username,
        userAvatar: avatar,
        virtualIp: virtualIp,
        roomUuid: widget.currentRoomUuid,
        onSettingsTap: widget.onSettings,
        onCreateRoomTap: widget.onCreateRoom,
        onJoinRoomTap: widget.onJoinRoom,
        onShareRoomTap: widget.onShareRoom,
        onDisconnectTap: widget.onDisconnect,

      );
    });
  }

  Widget _buildHistoryListForNarrow(BuildContext context) {
    return Watch((context) {
      final isConnected = widget.nodeManagement.isRunning;
      final history = getIt<RoomState>().rooms;
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
           side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.people_outlined : Icons.history_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? '在线用户' : '加入历史',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isConnected) ...[
                        _buildUserListInline(context),
                      ] else if (history.isEmpty) ...[
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '暂无加入历史',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '创建或加入房间后会显示在这里',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ...history.map((room) => DashboardDismissibleHistoryItem(
                          room: room,
                          onJoin: () {},
                          onRemove: widget.onRemoveRoom,
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildUserListInline(BuildContext context) {
    return Watch((context) {
      final enhancedNodes = widget.nodeManagement.enhancedUserNodes.value;

      if (enhancedNodes.isEmpty) {
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

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: enhancedNodes.length,
        itemBuilder: (context, index) {
          return DashboardUserItem(
            node: enhancedNodes[index],
            p2pStore: widget.nodeManagement,
          );
        },
      );
    });
  }
}