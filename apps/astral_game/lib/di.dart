import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:astral_game/data/services/client_api_service.dart';
import 'package:astral_game/data/services/global_p2p_store.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/data/services/server_persistence_service.dart';
import 'package:astral_game/data/services/webdav_backup_service.dart';
import 'package:astral_game/ui/shell/shell_content_controller.dart';
import 'package:astral_game/ui/pages/servers/server_state.dart';
import 'package:astral_game/ui/pages/settings/settings_state.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show initApp;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<AppSettingsService>(AppSettingsService(prefs));
  getIt.registerSingleton<ShellContentController>(ShellContentController());

  // P2P 相关服务
  getIt.registerLazySingleton<P2PService>(() => P2PService());
  await getIt<P2PService>().ensureInitialized();
  await initApp();
  getIt.registerLazySingleton<GlobalP2PStore>(() => GlobalP2PStore());
  
  // 客户端 API 服务
  getIt.registerLazySingleton<ClientApiService>(() => ClientApiService());
  
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
