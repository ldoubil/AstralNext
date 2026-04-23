import 'package:flutter/material.dart';
import '../widgets/dashboard_main_card.dart';
import '../widgets/join_room_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isConnected = false;
  final String _username = '玩家';
  final String _virtualIp = '10.147.18.24';

  void _handleCreateRoom() {
    Navigator.pushNamed(context, '/rooms');
  }

  void _handleJoinRoom() {
    JoinRoomDialog.show(context);
  }

  void _handleConnect() {
    setState(() {
      _isConnected = !_isConnected;
    });
  }

  void _handleSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isWideScreen = screenWidth >= 900;

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
        const Expanded(
          child: Center(
            child: Text('未加入房间'),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DashboardMainCard(
              isConnected: _isConnected,
              username: _username,
              roomName: _isConnected ? '测试房间' : '',
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
      child: DashboardMainCard(
        isConnected: _isConnected,
        username: _username,
        roomName: _isConnected ? '测试房间' : '',
        virtualIp: _virtualIp,
        onSettingsTap: _handleSettings,
        onCreateRoomTap: _handleCreateRoom,
        onJoinRoomTap: _handleJoinRoom,
        onConnectTap: _handleConnect,
      ),
    );
  }
}
