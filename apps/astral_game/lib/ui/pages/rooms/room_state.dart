import 'package:astral_game/data/services/room_persistence_service.dart';

class RoomState {
  static final RoomState instance = RoomState._internal();
  factory RoomState() => instance;
  RoomState._internal();

  RoomPersistenceService? _persistence;
  List<dynamic> _rooms = [];
  int? _selectedRoomId;

  void initPersistence(RoomPersistenceService persistence) {
    _persistence = persistence;
  }

  Future<void> loadFromPersistence() async {
    if (_persistence != null) {
      _rooms = await _persistence!.loadRooms();
    }
  }

  void restoreSelectedRoom(int? roomId) {
    _selectedRoomId = roomId;
  }

  List<dynamic> get rooms => _rooms;
  int? get selectedRoomId => _selectedRoomId;
}

final RoomState roomState = RoomState();