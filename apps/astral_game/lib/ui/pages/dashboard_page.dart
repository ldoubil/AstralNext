import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:get_it/get_it.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/connection_service.dart';
import 'package:astral_game/data/services/screen_state_service.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:astral_game/data/models/room_mod.dart';
import 'package:astral_game/ui/pages/dashboard_wide_layout.dart';
import 'package:astral_game/ui/pages/dashboard_narrow_layout.dart';
import 'package:astral_game/ui/pages/settings/settings_main_page.dart';
import 'package:astral_game/ui/shell/shell_content_controller.dart';

/// 仪表盘页面
///
/// 显示网络状态、在线用户和房间历史
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final NodeManagementService _nodeManagement = GetIt.I<NodeManagementService>();
  final ConnectionService _connectionService = GetIt.I<ConnectionService>();
  final ScreenStateService _screenStateService = GetIt.I<ScreenStateService>();
  final RoomState _roomState = getIt<RoomState>();
  
  String? _currentRoomUuid;

  /// 处理设置按钮点击
  void _handleSettings() {
    if (mounted) {
      final contentController = getIt<ShellContentController>();
      contentController.showOverlay(
        title: '设置',
        contentBuilder: (_) => const SettingsMainPage(),
      );
    }
  }

  /// 处理分享房间
  Future<void> _handleShareRoom() async {
    if (_currentRoomUuid != null) {
      await Clipboard.setData(ClipboardData(text: _currentRoomUuid!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('房间号已复制到剪贴板')),
        );
      }
    }
  }

  /// 处理断开连接
  Future<void> _handleDisconnect() async {
    await _connectionService.disconnect();
    setState(() {
      _currentRoomUuid = null;
    });
  }

  /// 处理创建房间
  Future<void> _handleCreateRoom() async {
    if (_connectionService.isConnecting) return;

    final room = await _connectionService.createRoom();
    setState(() {
      _currentRoomUuid = room.uuid;
    });

    final success = await _connectionService.connectToRoom(room.roomName, room.password);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('连接失败，请重试')),
      );
    }
  }

  /// 处理加入房间
  Future<void> _handleJoinRoom() async {
    if (_connectionService.isConnecting) return;

    final TextEditingController uuidController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入房间'),
        content: TextField(
          controller: uuidController,
          decoration: const InputDecoration(
            labelText: '房间分享码',
            hintText: '例如：8位指纹-10位房间码（也可只填房间码）',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (uuidController.text.isNotEmpty) {
                Navigator.pop(context, uuidController.text.trim());
              }
            },
            child: const Text('加入'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final room = await _connectionService.joinRoom(result);
      setState(() {
        _currentRoomUuid = result;
      });

      final mismatch = _connectionService.lastServerFingerprintMismatch;
      if (mismatch != null && mismatch.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mismatch)),
        );
      }

      final success = await _connectionService.connectToRoom(room.roomName, room.password);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接失败，请重试')),
        );
      }
    }
  }

  /// 处理从历史记录加入房间
  void _handleJoinHistory(String uuid) async {
    if (uuid.isEmpty || _connectionService.isConnecting) return;
    
    final index = _roomState.rooms.indexWhere((r) => r.uuid == uuid);
    if (index != -1) {
      final room = _roomState.rooms[index];
      setState(() {
        _currentRoomUuid = uuid;
      });
      
      final success = await _connectionService.connectToRoom(room.roomName, room.password);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接失败，请重试')),
        );
      }
    }
  }

  /// 处理移除房间
  void _handleRemoveRoom(RoomMod room) {
    _connectionService.removeRoom(room.id);
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isNarrow = _screenStateService.isNarrow;

      return Scaffold(
        body: isNarrow
            ? DashboardNarrowLayout(
                nodeManagement: _nodeManagement,
                connectionService: _connectionService,
                currentRoomUuid: _currentRoomUuid,
                onSettings: _handleSettings,
                onCreateRoom: _handleCreateRoom,
                onJoinRoom: _handleJoinRoom,
                onShareRoom: _handleShareRoom,
                onDisconnect: _handleDisconnect,
                onRemoveRoom: _handleRemoveRoom,
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: DashboardWideLayout(
                  nodeManagement: _nodeManagement,
                  connectionService: _connectionService,
                  screenStateService: _screenStateService,
                  currentRoomUuid: _currentRoomUuid,
                  onSettings: _handleSettings,
                  onCreateRoom: _handleCreateRoom,
                  onJoinRoom: _handleJoinRoom,
                  onShareRoom: _handleShareRoom,
                  onDisconnect: _handleDisconnect,
                  onJoinHistory: _handleJoinHistory,
                ),
              ),
      );
    });
  }
}
