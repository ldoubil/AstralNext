import 'package:flutter/material.dart';
import '../widgets/dashboard_main_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isConnected = false;
  final String _username = '玩家';
  final String _virtualIp = '10.147.18.24';

  void _handleConnect() {
    setState(() {
      _isConnected = !_isConnected;
    });
  }

  void _handleSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  void _handleCreateRoom() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('创建房间功能开发中')),
    );
  }

  void _handleJoinRoom() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('加入房间功能开发中')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isWideScreen = screenWidth >= 600;

          if (isWideScreen) {
            return _buildWideLayout(context);
          } else {
            return _buildNarrowLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildUserListCard(context),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DashboardMainCard(
              isConnected: _isConnected,
              username: _username,
              virtualIp: _virtualIp,
              onSettingsTap: _handleSettings,
              onCreateRoomTap: _handleCreateRoom,
              onJoinRoomTap: _handleJoinRoom,
              onConnectTap: _handleConnect,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildUserListCard(context),
          const SizedBox(height: 16),
          DashboardMainCard(
            isConnected: _isConnected,
            username: _username,
            virtualIp: _virtualIp,
            onSettingsTap: _handleSettings,
            onCreateRoomTap: _handleCreateRoom,
            onJoinRoomTap: _handleJoinRoom,
            onConnectTap: _handleConnect,
          ),
        ],
      ),
    );
  }

  Widget _buildUserListCard(BuildContext context) {
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
                Icon(Icons.people_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '在线用户',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_isConnected)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.wifi_off_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '未加入网络',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '请先连接或加入房间',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  _buildUserItem('玩家A', '10.147.18.100', true),
                  _buildUserItem('玩家B', '10.147.18.101', false),
                  _buildUserItem('玩家C', '10.147.18.102', true),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(String name, String ip, bool isOnline) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isOnline ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline,
              color: isOnline ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                Text(
                  ip,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isOnline)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
