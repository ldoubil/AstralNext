import 'package:signals/signals.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'room_mod.dart';

class RoomState {
  final rooms = signal<List<RoomMod>>([]);
  final selectedRoom = signal<RoomMod?>(null);
  final isConnected = signal<bool>(false);

  RoomPersistenceService? _persistence;

  void initPersistence(RoomPersistenceService service) {
    _persistence = service;
  }

  /// 从持久化存储加载房间
  Future<void> loadFromPersistence() async {
    if (_persistence == null) return;
    final loaded = await _persistence!.loadRooms();
    rooms.value = loaded;
  }

  void setRooms(List<RoomMod> roomList) {
    rooms.value = roomList;
    _persist();
  }

  void selectRoom(RoomMod? room) {
    selectedRoom.value = room;
    _saveSelectedRoomId(room?.id);
  }

  void addRoom(RoomMod room) {
    final list = List<RoomMod>.from(rooms.value);
    list.add(room);
    rooms.value = list;
    _persist();
  }

  void removeRoom(int id) {
    final list = rooms.value.where((r) => r.id != id).toList();
    rooms.value = list;
    if (selectedRoom.value?.id == id) {
      selectedRoom.value = null;
      _saveSelectedRoomId(null);
    }
    _persist();
  }

  void updateRoom(RoomMod updatedRoom) {
    final list = rooms.value.map((r) {
      return r.id == updatedRoom.id ? updatedRoom : r;
    }).toList();
    rooms.value = list;
    _persist();
  }

  void reorderRooms(List<RoomMod> reordered) {
    rooms.value = reordered;
    _persist();
  }

  RoomMod? getRoomById(int id) {
    try {
      return rooms.value.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 恢复上次选中的房间
  void restoreSelectedRoom(int? savedId) {
    if (savedId == null) return;
    final room = getRoomById(savedId);
    if (room != null) {
      selectedRoom.value = room;
    }
  }

  /// 设置连接状态（由 ConnectButton 调用）
  void setConnected(bool value) {
    isConnected.value = value;
  }

  Future<void> _persist() async {
    if (_persistence == null) return;
    await _persistence!.saveRooms(rooms.value);
  }

  void _saveSelectedRoomId(int? id) {
    if (_persistence != null) {
      _persistence!.saveSelectedRoomId(id);
    }
  }
}

final roomState = RoomState();
