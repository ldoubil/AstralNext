import 'package:flutter/material.dart';
import 'package:astral_game/config/constants.dart';

class DashboardNetworkActions extends StatelessWidget {
  final bool isConnected;
  final String virtualIp;
  final String? roomUuid;
  final bool isConnecting;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final VoidCallback onShareRoom;
  final VoidCallback onDisconnect;
  final VoidCallback onSettings;

  const DashboardNetworkActions({
    super.key,
    required this.isConnected,
    required this.virtualIp,
    required this.roomUuid,
    required this.isConnecting,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onShareRoom,
    required this.onDisconnect,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 24),
        _buildSectionHeader(context, Icons.network_check_outlined, '网络配置'),
        const SizedBox(height: 12),
        _buildNetworkInfoCard(context),
        const Divider(height: 24),
        _buildSectionHeader(context, Icons.settings_outlined, '操作'),
        const SizedBox(height: 12),
        _buildActionButtons(context),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onSettings,
            child: const Text('设置'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildNetworkRow(
            context,
            'IP地址',
            virtualIp,
            Icons.router_outlined,
          ),
          const SizedBox(height: 8),
          _buildNetworkRow(
            context,
            '房间ID',
            (roomUuid != null && roomUuid!.length >= AppConstants.uuidDisplayLength)
                ? roomUuid!.substring(0, AppConstants.uuidDisplayLength)
                : (roomUuid ?? '未连接'),
            Icons.room_outlined,
          ),
          const SizedBox(height: 8),
          _buildNetworkRow(
            context,
            '连接状态',
            isConnected ? '已连接' : '未连接',
            isConnected
                ? Icons.check_circle_outlined
                : Icons.circle_outlined,
            isConnected ? Colors.green[600] : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkRow(BuildContext context, String label, String value,
      IconData icon, [Color? iconColor]) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildActionButton(
          context,
          Icons.add_box_outlined,
          '创建房间',
          onCreateRoom,
          !isConnected && !isConnecting,
        ),
        _buildActionButton(
          context,
          Icons.login_outlined,
          '加入房间',
          onJoinRoom,
          !isConnected && !isConnecting,
        ),
        _buildActionButton(
          context,
          Icons.share_outlined,
          '分享房间',
          onShareRoom,
          isConnected && roomUuid != null,
        ),
        _buildActionButton(
          context,
          Icons.logout_outlined,
          '断开连接',
          onDisconnect,
          isConnected && !isConnecting,
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      VoidCallback onPressed, bool enabled) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: enabled
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(128),
        disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}