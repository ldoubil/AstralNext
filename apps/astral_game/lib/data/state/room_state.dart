import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/data/models/room_mod.dart';
import 'package:signals/signals_core.dart';

/// 房间状态管理
///
/// 管理房间列表、选中的房间和连接状态
class RoomState {
  RoomPersistenceService? _persistence;

  /// 房间列表
  final _rooms = signal<List<RoomMod>>([]);

  /// 选中的房间 ID
  int? _selectedRoomId;

  /// 选中的房间
  final selectedRoom = signal<RoomMod?>(null);

  /// 连接状态
  final isConnected = signal<bool>(false);

  /// 初始化持久化服务
  void initPersistence(RoomPersistenceService persistence) {
    _persistence = persistence;
  }

  /// 从持久化存储加载房间
  Future<void> loadFromPersistence() async {
    if (_persistence != null) {
      _rooms.value = await _persistence!.loadRooms();
    }
  }

  /// 恢复选中的房间
  void restoreSelectedRoom(int? roomId) {
    _selectedRoomId = roomId;
    if (roomId != null) {
      final index = _rooms.value.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        selectedRoom.value = _rooms.value[index];
      }
    }
  }

  /// 设置连接状态
  void setConnected(bool value) {
    isConnected.value = value;
  }

  /// 设置选中的房间
  void setSelectedRoom(RoomMod? room) {
    selectedRoom.value = room;
    if (room != null) {
      _selectedRoomId = room.id;
      _persistence?.saveSelectedRoomId(room.id);
    }
  }

  /// 获取房间列表
  List<RoomMod> get rooms => _rooms.value;

  /// 获取选中的房间 ID
  int? get selectedRoomId => _selectedRoomId;

  /// 移除房间
  void removeRoom(int roomId) {
    final updated = _rooms.value.where((r) => r.id != roomId).toList();
    _rooms.value = updated;
    _persistence?.saveRooms(updated);
  }
}
