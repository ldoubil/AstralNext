import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/ui/widgets/dashboard_main_card.dart';
import 'package:astral_game/data/services/global_p2p_store.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNodeInfo;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalP2PStore _p2pStore = GetIt.I<GlobalP2PStore>();

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

  void _handleJoinHistory(String roomName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在加入房间: $roomName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: _buildLeftPanel(context),
            ),
            Expanded(
              flex: 4,
              child: _buildRightPanel(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: double.infinity,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withAlpha(50)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _p2pStore.isRunning ? Icons.people_outlined : Icons.history_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _p2pStore.isRunning ? '在线用户' : '加入历史',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _p2pStore.isRunning ? _buildUserList(context) : _buildJoinHistory(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context) {
    return Watch((context) {
      final status = _p2pStore.networkStatus.value;
      final nodes = status?.nodes ?? [];

      return nodes.isEmpty
          ? _buildEmptyUserState(context)
          : _buildNodeList(context, nodes);
    });
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

  Widget _buildNodeList(BuildContext context, List<KVNodeInfo> nodes) {
    return SingleChildScrollView(
      child: Column(
        children: nodes.map((node) => _buildUserItem(node)).toList(),
      ),
    );
  }

  Widget _buildJoinHistory(BuildContext context) {
    final history = [
      {'name': '游戏房间A', 'time': '5分钟前'},
      {'name': '测试房间B', 'time': '1小时前'},
      {'name': '好友房间C', 'time': '3小时前'},
    ];

    return SingleChildScrollView(
      child: Column(
        children: history
            .map((item) => _buildHistoryItem(
                  item['name']!,
                  item['time']!,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    return Watch((context) {
      final isConnected = _p2pStore.isRunning;
      final status = _p2pStore.networkStatus.value;
      final virtualIp = status?.nodes.firstOrNull?.ipv4 ?? '10.147.18.24';

      return Container(
        height: double.infinity,
        child: DashboardMainCard(
          isConnected: isConnected,
          username: '玩家',
          virtualIp: virtualIp,
          onSettingsTap: _handleSettings,
          onCreateRoomTap: _handleCreateRoom,
          onJoinRoomTap: _handleJoinRoom,
          onConnectTap: () {},
        ),
      );
    });
  }

  Widget _buildUserItem(KVNodeInfo node) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline,
              color: colorScheme.onPrimaryContainer,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.hostname,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  node.ipv4,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildHistoryItem(String name, String time) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.meeting_room_outlined,
            color: colorScheme.onSurfaceVariant,
            size: 18,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_outlined, size: 16),
        onTap: () => _handleJoinHistory(name),
      ),
    );
  }
}