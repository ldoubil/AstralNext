import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/p2p_config_service.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:astral_game/ui/pages/rooms/room_mod.dart';
import 'package:astral_rust_core/p2p_service.dart';

/// 连接服务
///
/// 负责管理 P2P 网络连接、房间创建和加入等操作
class ConnectionService {
  final P2PService _p2pService = GetIt.I<P2PService>();
  final P2PConfigService _p2pConfig = GetIt.I<P2PConfigService>();
  final NodeManagementService _nodeManagement = GetIt.I<NodeManagementService>();
  final RoomPersistenceService _roomPersistence = GetIt.I<RoomPersistenceService>();

  bool _isConnecting = false;

  bool get isConnecting => _isConnecting;

  /// 连接到指定房间
  ///
  /// [roomName] 房间名称
  /// [roomPassword] 房间密码
  /// 返回连接是否成功
  Future<bool> connectToRoom(String roomName, String roomPassword) async {
    if (_isConnecting) {
      debugPrint('[ConnectionService] 已有连接正在进行中，跳过');
      return false;
    }

    _isConnecting = true;

    try {
      final configToml = _p2pConfig.buildTomlConfig(roomName, roomPassword);
      debugPrint('[ConnectionService] 正在连接房间: $roomName');

      final instanceId = await _p2pService.createServer(
        configToml: configToml,
        watchEvent: true,
      );

      final isRunning = await _p2pService.isEasytierRunning(instanceId);
      if (isRunning) {
        _nodeManagement.setRunning(instanceId);
        roomState.setConnected(true);
        debugPrint('[ConnectionService] 连接成功，实例ID: $instanceId');
        return true;
      } else {
        debugPrint('[ConnectionService] 连接失败：实例启动异常');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[ConnectionService] 连接失败: $e\n$stackTrace');
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  /// 断开当前连接
  Future<void> disconnect() async {
    final instanceId = _nodeManagement.instanceId;
    if (instanceId != null) {
      try {
        await _p2pService.closeServer(instanceId);
        debugPrint('[ConnectionService] 已断开连接，实例ID: $instanceId');
      } catch (e, stackTrace) {
        debugPrint('[ConnectionService] 断开连接时发生错误: $e\n$stackTrace');
      }
    }
    _nodeManagement.setStopped();
    roomState.setConnected(false);
  }

  /// 创建新房间
  ///
  /// 自动生成 UUID 和房间配置，保存到持久化存储
  /// 返回创建的房间信息
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

    try {
      await _roomPersistence.saveRooms([...roomState.rooms, room]);
      await roomState.loadFromPersistence();
      debugPrint('[ConnectionService] 已创建房间: $roomName, UUID: $uuid');
    } catch (e, stackTrace) {
      debugPrint('[ConnectionService] 保存房间失败: $e\n$stackTrace');
    }

    return room;
  }

  /// 加入已有房间
  ///
  /// [uuid] 房间 UUID
  /// 返回房间信息
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

    try {
      await _roomPersistence.saveRooms([...roomState.rooms, room]);
      await roomState.loadFromPersistence();
      debugPrint('[ConnectionService] 已加入房间: $roomName, UUID: $uuid');
    } catch (e, stackTrace) {
      debugPrint('[ConnectionService] 保存房间记录失败: $e\n$stackTrace');
    }

    return room;
  }

  /// 移除房间
  ///
  /// [roomId] 房间 ID
  void removeRoom(int roomId) {
    roomState.removeRoom(roomId);
    debugPrint('[ConnectionService] 已移除房间: $roomId');
  }
}
