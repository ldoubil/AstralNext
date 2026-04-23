import 'package:flutter/material.dart';
import '../pages/rooms/room_state.dart';

class UserInfoCard extends StatefulWidget {
  final VoidCallback? onSettingsTap;

  const UserInfoCard({
    super.key,
    this.onSettingsTap,
  });

  @override
  State<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<UserInfoCard> {
  final String _username = '玩家';
  final String _virtualIp = '10.147.18.24';
  late final dynamic _disposeSelectedRoom;
  late final dynamic _disposeIsConnected;

  bool get _isConnected => roomState.isConnected.value;

  @override
  void initState() {
    super.initState();
    _disposeSelectedRoom = roomState.selectedRoom.subscribe((_) {
      if (mounted) setState(() {});
    });
    _disposeIsConnected = roomState.isConnected.subscribe((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _disposeSelectedRoom();
    _disposeIsConnected();
    super.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_outline,
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
                        _username,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _isConnected ? '已连接' : '未连接',
                        style: textTheme.bodySmall?.copyWith(
                          color: _isConnected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
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
            Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.apartment_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '当前房间',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  roomState.selectedRoom.value?.name ?? '未选择房间',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lan_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '虚拟 IP',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _virtualIp,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
