import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/p2p_config_service.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:astral_game/ui/pages/rooms/room_mod.dart';
import 'package:astral_rust_core/p2p_service.dart';

class ConnectionService {
  final P2PService _p2pService = GetIt.I<P2PService>();
  final P2PConfigService _p2pConfig = GetIt.I<P2PConfigService>();
  final NodeManagementService _nodeManagement = GetIt.I<NodeManagementService>();
  final RoomPersistenceService _roomPersistence = GetIt.I<RoomPersistenceService>();

  bool _isConnecting = false;

  bool get isConnecting => _isConnecting;

  Future<bool> connectToRoom(String roomName, String roomPassword) async {
    if (_isConnecting) return false;

    _isConnecting = true;

    try {
      final configToml = _p2pConfig.buildTomlConfig(roomName, roomPassword);
      debugPrint('连接房间: $roomName');

      final instanceId = await _p2pService.createServer(
        configToml: configToml,
        watchEvent: true,
      );

      final isRunning = await _p2pService.isEasytierRunning(instanceId);
      if (isRunning) {
        _nodeManagement.setRunning(instanceId);
        roomState.setConnected(true);
        return true;
      } else {
        debugPrint('连接失败：实例启动异常');
        return false;
      }
    } catch (e) {
      debugPrint('连接失败: $e');
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    final instanceId = _nodeManagement.instanceId;
    if (instanceId != null) {
      try {
        await _p2pService.closeServer(instanceId);
      } catch (_) {}
    }
    _nodeManagement.setStopped();
    roomState.setConnected(false);
  }

  Future<RoomMod> createRoom() async {
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

    return room;
  }

  Future<RoomMod> joinRoom(String uuid) async {
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

    return room;
  }

  void removeRoom(int roomId) {
    roomState.removeRoom(roomId);
  }
}
