import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:astral_game/data/services/avatar_port_scanner.dart';
import 'package:astral_game/data/services/client_api_service.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/p2p_config_service.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/data/services/screen_state_service.dart';
import 'package:astral_game/data/services/server_persistence_service.dart';
import 'package:astral_game/data/services/webdav_backup_service.dart';
import 'package:astral_game/ui/shell/shell_content_controller.dart';
import 'package:astral_game/ui/pages/servers/server_state.dart';
import 'package:astral_game/ui/pages/settings/settings_state.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart';
import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<AppSettingsService>(AppSettingsService(prefs));
  getIt.registerSingleton<ShellContentController>(ShellContentController());
  
  // 屏幕状态服务
  getIt.registerSingleton<ScreenStateService>(ScreenStateService());

  // P2P 相关服务
  getIt.registerLazySingleton<P2PService>(() => P2PService());
  await getIt<P2PService>().ensureInitialized();
  await initApp();
  
  // 事件总线
  getIt.registerSingleton<EventBus>(EventBus());
  
  // 节点管理服务
  getIt.registerLazySingleton<NodeManagementService>(() => NodeManagementService());
  
  getIt.registerLazySingleton<P2PConfigService>(
    () => P2PConfigService(
      getIt<AppSettingsService>(),
      getIt<ServerState>(),
    ),
  );
  
  // 客户端 API 服务
  getIt.registerLazySingleton<ClientApiService>(() => ClientApiService());
  
  // 头像端口扫描器
  getIt.registerLazySingleton<AvatarPortScanner>(() => AvatarPortScanner());
  
  // 服务器状态
  getIt.registerLazySingleton<ServerState>(() => ServerState());
  getIt.registerLazySingleton<ServerStatusState>(() => ServerStatusState());
  getIt.registerLazySingleton<ServerPersistenceService>(
    () => ServerPersistenceService(),
  );
  
  // 设置状态
  getIt.registerLazySingleton<SettingsState>(() => SettingsState());
  
  // 初始化服务器持久化
  final serverState = getIt<ServerState>();
  final serverPersistence = getIt<ServerPersistenceService>();
  serverState.setPersistenceCallbacks(
    loadCallback: serverPersistence.loadServers,
    saveCallback: serverPersistence.saveServers,
  );
  await serverState.loadFromPersistence();

  // 持久化与备份
  getIt.registerLazySingleton<RoomPersistenceService>(
    () => RoomPersistenceService(prefs),
  );
  getIt.registerLazySingleton<WebDavBackupService>(
    () => WebDavBackupService(
      getIt<AppSettingsService>(),
      getIt<RoomPersistenceService>(),
    ),
  );
}
