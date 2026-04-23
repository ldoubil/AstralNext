import 'dart:io';
import 'package:flutter/material.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/app_settings_service.dart';

class DashboardMainCard extends StatefulWidget {
  final bool isConnected;
  final String username;
  final String virtualIp;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onCreateRoomTap;
  final VoidCallback? onJoinRoomTap;
  final VoidCallback? onConnectTap;

  const DashboardMainCard({
    super.key,
    this.isConnected = false,
    this.username = '玩家',
    this.virtualIp = '10.147.18.24',
    this.onSettingsTap,
    this.onCreateRoomTap,
    this.onJoinRoomTap,
    this.onConnectTap,
  });

  @override
  State<DashboardMainCard> createState() => _DashboardMainCardState();
}

class _DashboardMainCardState extends State<DashboardMainCard> {
  bool _disableP2p = false;
  bool _firewallStatus = false;

  @override
  void initState() {
    super.initState();
    _disableP2p = getIt<AppSettingsService>().isDisableP2p();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
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
                          Text(
                            widget.virtualIp,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: widget.onSettingsTap,
                ),
              ],
            ),
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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _disableP2p
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.route,
                      size: 18,
                      color: _disableP2p
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '禁用P2P直连',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _disableP2p,
                    onChanged: (value) {
                      setState(() {
                        _disableP2p = value;
                      });
                      getIt<AppSettingsService>().setDisableP2p(value);
                    },
                  ),
                ],
              ),
            ),
            if (Platform.isWindows) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _firewallStatus
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shield,
                        size: 18,
                        color: _firewallStatus
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _firewallStatus ? '已启用' : '已禁用',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _firewallStatus,
                      onChanged: (value) {
                        setState(() {
                          _firewallStatus = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],

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
            if (widget.isConnected)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: widget.onConnectTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('断开连接'),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton(
                      onPressed: widget.onCreateRoomTap,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('创建房间'),
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('加入房间'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
