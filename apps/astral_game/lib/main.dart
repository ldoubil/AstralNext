import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/client_api_service.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/data/services/global_p2p_store.dart';
import 'package:astral_game/ui/pages/rooms/room_state.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window_manager
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(940, 560),
    minimumSize: Size(800, 500),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // 隐藏系统标题栏
  );

  await setupDI();

  // 初始化用户信息（从持久化存储加载）
  final p2pStore = getIt<GlobalP2PStore>();
  p2pStore.initUserInfo();

  // 启动头像 API 服务器（自动选择 4924-4944 范围内的可用端口）
  final clientApiService = getIt<ClientApiService>();
  await clientApiService.start();

  // 初始化房间持久化
  final roomPersistence = getIt<RoomPersistenceService>();
  roomState.initPersistence(roomPersistence);
  await roomState.loadFromPersistence();
  roomState.restoreSelectedRoom(roomPersistence.loadSelectedRoomId());

  runApp(const AstralGameApp());
  
  // Show window after app is ready
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
