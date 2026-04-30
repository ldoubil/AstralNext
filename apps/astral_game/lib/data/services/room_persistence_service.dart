import 'dart:convert';
import 'dart:io';

import 'package:astral_game/data/models/room_mod.dart';
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomPersistenceService {
  static const _fileName = 'rooms.json';
  static const _selectedRoomKey = 'selected_room_id';

  final SharedPreferences _prefs;

  RoomPersistenceService(this._prefs);

  Future<String> get _filePath async {
    final dir = await getApplicationSupportDirectory();
    return path_lib.join(dir.path, _fileName);
  }

  Future<List<RoomMod>> loadRooms() async {
    try {
      final filePath = await _filePath;
      final file = File(filePath);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final list = jsonDecode(content) as List;
      return list
          .map((e) => RoomMod.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveRooms(List<RoomMod> rooms) async {
    try {
      final filePath = await _filePath;
      final file = File(filePath);
      final json = jsonEncode(rooms.map((r) => r.toJson()).toList());
      await file.writeAsString(json);
    } catch (e) {
      // ignore
    }
  }

  int? loadSelectedRoomId() {
    return _prefs.getInt(_selectedRoomKey);
  }

  Future<void> saveSelectedRoomId(int? id) async {
    if (id == null) {
      await _prefs.remove(_selectedRoomKey);
    } else {
      await _prefs.setInt(_selectedRoomKey, id);
    }
  }
}
