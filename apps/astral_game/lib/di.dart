import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:astral_game/data/services/client_api_service.dart';
import 'package:astral_game/data/services/connection_service.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/p2p_config_service.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/data/services/screen_state_service.dart';
import 'package:astral_game/data/services/server_persistence_service.dart';
import 'package:astral_game/data/services/webdav_backup_service.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:astral_game/data/state/server_state.dart';
import 'package:astral_game/data/state/settings_state.dart';
import 'package:astral_game/ui/shell/shell_content_controller.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart';
import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

/// 设置依赖注入
Future<void> setupDI() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<AppSettingsService>(AppSettingsService(prefs));
  getIt.registerSingleton<ShellContentController>(ShellContentController());
  
  getIt.registerSingleton<ScreenStateService>(ScreenStateService());

  getIt.registerLazySingleton<P2PService>(() => P2PService());
  await getIt<P2PService>().ensureInitialized();
  await initApp();
  
  getIt.registerSingleton<EventBus>(EventBus());
  
  getIt.registerLazySingleton<NodeManagementService>(() => NodeManagementService());
  
  getIt.registerLazySingleton<P2PConfigService>(
    () => P2PConfigService(
      getIt<AppSettingsService>(),
      getIt<ServerState>(),
    ),
  );
  
  getIt.registerLazySingleton<ClientApiService>(() => ClientApiService());
  
  getIt.registerLazySingleton<ServerState>(() => ServerState());
  getIt.registerLazySingleton<ServerStatusState>(() => ServerStatusState());
  getIt.registerLazySingleton<ServerPersistenceService>(
    () => ServerPersistenceService(),
  );
  
  getIt.registerLazySingleton<SettingsState>(() => SettingsState());
  
  getIt.registerLazySingleton<RoomState>(() => RoomState());
  
  final serverState = getIt<ServerState>();
  final serverPersistence = getIt<ServerPersistenceService>();
  serverState.setPersistenceCallbacks(
    loadCallback: serverPersistence.loadServers,
    saveCallback: serverPersistence.saveServers,
  );
  await serverState.loadFromPersistence();

  getIt.registerLazySingleton<RoomPersistenceService>(
    () => RoomPersistenceService(prefs),
  );
  getIt.registerLazySingleton<WebDavBackupService>(
    () => WebDavBackupService(
      getIt<AppSettingsService>(),
      getIt<RoomPersistenceService>(),
    ),
  );

  getIt.registerLazySingleton<ConnectionService>(() => ConnectionService());
}
