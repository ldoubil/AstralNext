import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/config/constants.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/firewall_service.dart';
import 'package:astral_game/data/state/settings_state.dart';
import 'package:astral_game/ui/widgets/avatar_widget.dart';

/// 仪表盘主卡片公共字段与布局骨架；宽/窄屏子类只覆写 [showNetworkWhenConnected] 与 [buildConnectedActions]。
abstract class DashboardMainCardBase extends StatefulWidget {
  const DashboardMainCardBase({
    super.key,
    this.isConnected = false,
    this.username = '玩家',
    this.userAvatar,
    this.virtualIp = AppConstants.defaultVirtualIp,
    this.roomShareCode,
    this.onSettingsTap,
    this.onCreateRoomTap,
    this.onJoinRoomTap,
    this.onShareRoomTap,
    this.onDisconnectTap,
    this.isCollapsed = false,
    this.showFirewall = true,
  });

  final bool isConnected;
  final String username;
  final Uint8List? userAvatar;
  final String virtualIp;
  final String? roomShareCode;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onCreateRoomTap;
  final VoidCallback? onJoinRoomTap;
  final VoidCallback? onShareRoomTap;
  final VoidCallback? onDisconnectTap;
  final bool isCollapsed;
  final bool showFirewall;

  @override
  State<DashboardMainCardBase> createState();
}

abstract class DashboardMainCardBaseState<W extends DashboardMainCardBase>
    extends State<W> {
  bool _firewallEnabled = false;
  bool _isLoadingFirewall = true;

  /// 已连接时是否仍显示「网络配置」区块（宽屏 true，窄屏 false）。
  bool get showNetworkWhenConnected;

  @override
  void initState() {
    super.initState();
    _loadFirewallStatus();
  }

  Future<void> _loadFirewallStatus() async {
    if (!kIsWeb) {
      try {
        final firewallService = getIt<FirewallService>();
        final status = await firewallService.getPrivateFirewallStatus();
        if (mounted) {
          setState(() {
            _firewallEnabled = status;
            _isLoadingFirewall = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoadingFirewall = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingFirewall = false);
      }
    }
  }

  Future<void> _toggleFirewall(bool enable) async {
    setState(() => _firewallEnabled = enable);
    try {
      final firewallService = getIt<FirewallService>();
      await firewallService.setPrivateFirewallStatus(enable);
    } catch (_) {
      if (mounted) {
        setState(() => _firewallEnabled = !enable);
      }
    }
  }

  @override
  void didUpdateWidget(covariant W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userAvatar != widget.userAvatar) {
      setState(() {});
    }
  }

  Widget buildUserSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        AvatarWidget(
          avatar: widget.userAvatar,
          size: 48,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.username,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.lan_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.virtualIp,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.edit_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: widget.onSettingsTap,
        ),
      ],
    );
  }

  Widget buildNetworkSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsState = getIt<SettingsState>();

    return Watch((context) {
      final disableP2p = settingsState.disableP2p.value;

      return Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.tune, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '网络配置',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: AppRadius.brMedium,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: disableP2p
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.route,
                    size: 18,
                    color: disableP2p
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '强制中转',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '禁用P2P直连',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: disableP2p,
                  onChanged: (value) {
                    settingsState.disableP2p.value = value;
                    settingsState.saveToPersistence();
                  },
                ),
              ],
            ),
          ),
          if (widget.showFirewall && !kIsWeb) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: AppRadius.brMedium,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _firewallEnabled
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shield,
                      size: 18,
                      color: _firewallEnabled
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '防火墙',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _isLoadingFirewall
                              ? '加载中...'
                              : (_firewallEnabled ? '已启用' : '已禁用'),
                          style: textTheme.bodySmall?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingFirewall)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Switch(
                      value: _firewallEnabled,
                      onChanged: _toggleFirewall,
                    ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget buildDisconnectedActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.play_circle_outline, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              '操作',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            onPressed: widget.onCreateRoomTap,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.brMedium,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_box_outlined, size: 18),
                SizedBox(width: 8),
                Text('创建房间'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: widget.onJoinRoomTap,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.brMedium,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login_outlined, size: 18),
                SizedBox(width: 8),
                Text('加入房间'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildConnectedActions(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showNetwork =
        !widget.isConnected || showNetworkWhenConnected;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLarge,
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildUserSection(context),
            ClipRect(
              child: AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    if (showNetwork) buildNetworkSection(context),
                    widget.isConnected
                        ? buildConnectedActions(context)
                        : buildDisconnectedActions(context),
                  ],
                ),
                crossFadeState: widget.isCollapsed
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 300),
                firstCurve: Curves.easeInOut,
                secondCurve: Curves.easeInOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
