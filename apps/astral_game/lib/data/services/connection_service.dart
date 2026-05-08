import 'package:astral_game/utils/logger.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/p2p_config_service.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/data/services/node_net/node_net_client.dart';
import 'package:astral_game/data/services/node_net/node_net_server.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:astral_game/data/models/room_mod.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:get_it/get_it.dart';

/// 连接服务
///
/// 负责管理 P2P 网络连接、房间创建和加入等操作
class ConnectionService {
  final P2PService _p2pService;
  final P2PConfigService _p2pConfig;
  final NodeManagementService _nodeManagement;
  final RoomPersistenceService _roomPersistence;
  final RoomState _roomState;

  ConnectionService(
    this._p2pService,
    this._p2pConfig,
    this._nodeManagement,
    this._roomPersistence,
    this._roomState,
  );

  bool _isConnecting = false;

  bool get isConnecting => _isConnecting;

  /// 检测分享码中的服务器指纹是否与本地启用服务器一致
  ///
  /// 返回：
  /// - `null`：无指纹/无法比较/一致
  /// - 非空字符串：不一致时给 UI 展示的提示文案
  String? serverFingerprintMismatchMessage(String shareCode) {
    final trimmed = shareCode.trim();
    if (trimmed.isEmpty) return null;

    final parts = _p2pConfig.parseRoomShareCode(trimmed);
    if (parts == null) return null;

    final remoteFp = parts.serverFingerprint;
    if (remoteFp.isEmpty || remoteFp == '00000000') return null;
    final localFp = _p2pConfig.enabledServersFingerprint();
    if (localFp.isEmpty) return null; // 本地没有启用服务器，没法对比

    if (remoteFp != localFp) {
      return '服务器列表与创建方不一致（remote=$remoteFp local=$localFp）';
    }
    return null;
  }

  /// 连接到指定房间
  ///
  /// [roomName] 房间名称
  /// [roomPassword] 房间密码
  /// 返回连接是否成功
  Future<bool> connectToRoom(String roomName, String roomPassword) async {
    if (_isConnecting) {
      appLogger.w('[ConnectionService] 已有连接正在进行中，跳过');
      return false;
    }

    _isConnecting = true;

    try {
      // 连接建立前设置本地 RPC 会话鉴权 token（供其他节点调用）
      GetIt.I<NodeNetServer>().setAuthToken(roomPassword);
      GetIt.I<NodeNetClient>().setAuthToken(roomPassword);

      final configToml = _p2pConfig.buildTomlConfig(roomName, roomPassword);
      appLogger.i('[ConnectionService] 正在连接房间: $roomName');

      final instanceId = await _p2pService.createServer(
        configToml: configToml,
        watchEvent: true,
      );

      final isRunning = await _p2pService.isEasytierRunning(instanceId);
      if (isRunning) {
        _nodeManagement.setRunning(instanceId);
        _roomState.setConnected(true);
        appLogger.i('[ConnectionService] 连接成功，实例ID: $instanceId');
        return true;
      } else {
        appLogger.e('[ConnectionService] 连接失败：实例启动异常');
        return false;
      }
    } catch (e, stackTrace) {
      appLogger.e('[ConnectionService] 连接失败: $e', error: e, stackTrace: stackTrace);
      // 若连接失败，清除 token，避免残留
      GetIt.I<NodeNetServer>().setAuthToken(null);
      GetIt.I<NodeNetClient>().setAuthToken(null);
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
        appLogger.i('[ConnectionService] 已断开连接，实例ID: $instanceId');
      } catch (e, stackTrace) {
        appLogger.e('[ConnectionService] 断开连接时发生错误: $e', error: e, stackTrace: stackTrace);
      }
    }
    _nodeManagement.setStopped();
    _roomState.setConnected(false);
    GetIt.I<NodeNetServer>().setAuthToken(null);
    GetIt.I<NodeNetClient>().setAuthToken(null);
  }

  /// 创建新房间
  ///
  /// 要求传入房间名，并生成会话 token（用于房间密码与 RPC 鉴权）
  /// 返回创建的房间信息
  Future<RoomMod> createRoom({required String roomName}) async {
    final fp = _p2pConfig.shareFingerprint();
    final token = _p2pConfig.generateRoomCode();
    final shareCode = _p2pConfig.buildRoomShareCode(
      roomName: roomName,
      token: token,
      serverFingerprint: fp,
    );
    return await _createAndPersistRoom(
      shareCode: shareCode,
      roomName: roomName,
      token: token,
    );
  }

  /// 加入已有房间
  ///
  /// [shareCode] 房间分享码（推荐：`服务器指纹-房间码`；也兼容只输入房间码）
  /// 返回房间信息
  Future<RoomMod> joinRoom(String shareCode) async {
    final trimmed = shareCode.trim();
    if (trimmed.isEmpty) {
      return await _createAndPersistRoom(shareCode: '', roomName: '', token: '');
    }

    final parts = _p2pConfig.parseRoomShareCode(trimmed);
    if (parts == null) {
      return await _createAndPersistRoom(shareCode: trimmed, roomName: '', token: trimmed);
    }

    return await _createAndPersistRoom(
      shareCode: trimmed,
      roomName: parts.roomName,
      token: parts.token,
    );
  }

  /// 创建并持久化房间
  Future<RoomMod> _createAndPersistRoom({
    required String shareCode,
    required String roomName,
    required String token,
  }) async {
    final safeRoomName = roomName.trim();
    final safeToken = token.trim();
    final safePrefix = safeToken.isEmpty
        ? 'unknown'
        : safeToken.substring(0, safeToken.length < 6 ? safeToken.length : 6);

    final finalRoomName = safeRoomName.isEmpty ? 'Room_$safePrefix' : safeRoomName;
    final roomPassword = safeToken;

    final room = RoomMod(
      id: DateTime.now().millisecondsSinceEpoch,
      name: finalRoomName,
      roomName: finalRoomName,
      host: 'localhost',
      port: 11010,
      password: roomPassword,
      shareCode: shareCode,
      createdAt: DateTime.now(),
    );

    try {
      await _roomPersistence.saveRooms([..._roomState.rooms, room]);
      await _roomState.loadFromPersistence();
      appLogger.i('[ConnectionService] 已创建/加入房间: $roomName, shareCode: $shareCode');
    } catch (e, stackTrace) {
      appLogger.e('[ConnectionService] 保存房间失败: $e', error: e, stackTrace: stackTrace);
    }

    return room;
  }

  /// 移除房间
  ///
  /// [roomId] 房间 ID
  void removeRoom(int roomId) {
    _roomState.removeRoom(roomId);
    appLogger.i('[ConnectionService] 已移除房间: $roomId');
  }
}
