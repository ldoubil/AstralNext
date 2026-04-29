import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/ui/pages/rooms/room_mod.dart';
import 'package:signals/signals_core.dart';

class RoomState {
  static final RoomState instance = RoomState._internal();
  factory RoomState() => instance;
  RoomState._internal();

  RoomPersistenceService? _persistence;
  final _rooms = signal<List<RoomMod>>([]);
  int? _selectedRoomId;
  
  final selectedRoom = signal<dynamic>(null);
  final isConnected = signal<bool>(false);

  void initPersistence(RoomPersistenceService persistence) {
    _persistence = persistence;
  }

  Future<void> loadFromPersistence() async {
    if (_persistence != null) {
      final loaded = await _persistence!.loadRooms();
      _rooms.value = loaded.cast<RoomMod>();
    }
  }

  void restoreSelectedRoom(int? roomId) {
    _selectedRoomId = roomId;
    if (roomId != null) {
      final index = _rooms.value.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        selectedRoom.value = _rooms.value[index];
      }
    }
  }

  void setConnected(bool value) {
    isConnected.value = value;
  }

  void setSelectedRoom(dynamic room) {
    selectedRoom.value = room;
    if (room != null) {
      _selectedRoomId = room.id;
      _persistence?.saveSelectedRoomId(room.id);
    }
  }

  List<RoomMod> get rooms => _rooms.value;
  int? get selectedRoomId => _selectedRoomId;

  void removeRoom(int roomId) {
    final updated = _rooms.value.where((r) => r.id != roomId).toList();
    _rooms.value = updated;
    _persistence?.saveRooms(updated);
  }
}

final RoomState roomState = RoomState();
