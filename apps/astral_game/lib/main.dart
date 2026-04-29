import 'dart:io';

import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window_manager only on desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(940, 560),
      // minimumSize: Size(800, 500),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await setupDI();

  // 初始化用户信息（从持久化存储加载）
  final nodeManager = getIt<NodeManagementService>();
  nodeManager.initUserInfo();

  // 初始化房间持久化
  final roomPersistence = getIt<RoomPersistenceService>();
  roomState.initPersistence(roomPersistence);
  await roomState.loadFromPersistence();
  roomState.restoreSelectedRoom(roomPersistence.loadSelectedRoomId());

  runApp(const AstralGameApp());
}
