import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:get_it/get_it.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/p2p_config_service.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/data/services/screen_state_service.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:astral_game/ui/pages/rooms/room_mod.dart';
import 'package:astral_game/ui/pages/dashboard_wide_layout.dart';
import 'package:astral_game/ui/pages/dashboard_narrow_layout.dart';
import 'package:astral_rust_core/p2p_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final NodeManagementService _p2pStore = GetIt.I<NodeManagementService>();
  final P2PService _p2pService = GetIt.I<P2PService>();
  final P2PConfigService _p2pConfig = GetIt.I<P2PConfigService>();
  final RoomPersistenceService _roomPersistence =
      GetIt.I<RoomPersistenceService>();
  final ScreenStateService _screenStateService = GetIt.I<ScreenStateService>();
  bool _isConnecting = false;
  String? _currentRoomUuid;

  void _handleSettings() {
    if (mounted) {
      Navigator.pushNamed(context, '/settings');
    }
  }

  Future<void> _handleShareRoom() async {
    if (_currentRoomUuid != null) {
      await Clipboard.setData(ClipboardData(text: _currentRoomUuid!));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('房间号已复制到剪贴板')));
      }
    }
  }

  Future<void> _handleDisconnect() async {
    final instanceId = _p2pStore.instanceId;
    if (instanceId != null) {
      try {
        await _p2pService.closeServer(instanceId);
      } catch (_) {}
    }
    _p2pStore.setStopped();
    roomState.setConnected(false);
    setState(() {
      _currentRoomUuid = null;
    });
  }

  Future<void> _connectToRoom(String roomName, String roomPassword) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final configToml = _p2pConfig.buildTomlConfig(roomName, roomPassword);
      debugPrint('连接房间: $roomName');

      final instanceId = await _p2pService.createServer(
        configToml: configToml,
        watchEvent: true,
      );

      final isRunning = await _p2pService.isEasytierRunning(instanceId);
      if (isRunning) {
        _p2pStore.setRunning(instanceId);
        roomState.setConnected(true);
      } else {
        debugPrint('连接失败：实例启动异常');
      }
    } catch (e) {
      debugPrint('连接失败: $e');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _handleCreateRoom() async {
    if (_isConnecting) return;

    final uuid = _p2pConfig.generateUuid();
    final roomName = 'Room_${uuid.substring(0, 8)}';
    final roomPassword = uuid;

    final room = RoomMod(
      id: DateTime.now().millisecondsSinceEpoch,
      name: roomName,
      roomName: roomName,
      host: 'localhost',
      port: 11010,
      password: roomPassword,
      uuid: uuid,
      createdAt: DateTime.now(),
    );

    await _roomPersistence.saveRooms([...roomState.rooms, room]);
    await roomState.loadFromPersistence();

    setState(() {
      _currentRoomUuid = uuid;
    });

    await _connectToRoom(roomName, roomPassword);
  }

  Future<void> _handleJoinRoom() async {
    final TextEditingController uuidController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入房间'),
        content: TextField(
          controller: uuidController,
          decoration: const InputDecoration(
            labelText: '房间UUID',
            hintText: '请输入房间UUID',
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
      final roomName = 'Room_${result.substring(0, 8)}';
      final roomPassword = result;

      final room = RoomMod(
        id: DateTime.now().millisecondsSinceEpoch,
        name: roomName,
        roomName: roomName,
        host: 'localhost',
        port: 11010,
        password: roomPassword,
        uuid: result,
        createdAt: DateTime.now(),
      );

      await _roomPersistence.saveRooms([...roomState.rooms, room]);
      await roomState.loadFromPersistence();

      setState(() {
        _currentRoomUuid = result;
      });

      await _connectToRoom(roomName, roomPassword);
    }
  }

  void _handleJoinHistory(String uuid) async {
    if (uuid.isEmpty) return;
    final index = roomState.rooms.indexWhere((r) => r.uuid == uuid);
    if (index != -1) {
      final room = roomState.rooms[index];
      setState(() {
        _currentRoomUuid = uuid;
      });
      await _connectToRoom(room.roomName, room.password);
    }
  }

  void _handleRemoveRoom(RoomMod room) {
    roomState.removeRoom(room.id);
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isNarrow = _screenStateService.isNarrow;

      return Scaffold(
        body: isNarrow
            ? DashboardNarrowLayout(
                p2pStore: _p2pStore,
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
                  p2pStore: _p2pStore,
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
