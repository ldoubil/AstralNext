import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:astral_game/data/services/connection_service.dart';
import 'package:astral_game/data/services/firewall_service.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/peer_rpc/methods/message_methods.dart';
import 'package:astral_game/data/services/peer_rpc/methods/node_methods.dart';
import 'package:astral_game/data/services/peer_rpc/methods/user_methods.dart';
import 'package:astral_game/data/services/peer_rpc/peer_rpc_client.dart';
import 'package:astral_game/data/services/peer_rpc/peer_rpc_router.dart';
import 'package:astral_game/data/services/p2p_config_service.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/data/services/screen_state_service.dart';
import 'package:astral_game/data/services/server_persistence_service.dart';
import 'package:astral_game/data/services/webdav_backup_service.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:astral_game/data/state/server_state.dart';
import 'package:astral_game/data/state/settings_state.dart';
import 'package:astral_game/data/state/update_state.dart';
import 'package:astral_game/data/services/update_service.dart';
import 'package:astral_game/data/services/vpn_manager.dart';
import 'package:astral_game/data/state/vpn_state.dart';
import 'package:astral_game/ui/shell/shell_content_controller.dart';
import 'package:astral_game/utils/logger.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart';
import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

/// 设置依赖注入
Future<void> setupDI() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerLazySingleton<Logger>(
    () => Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: false,
        dateTimeFormat: DateTimeFormat.none,
      ),
    ),
  );
  getIt.registerSingleton<AppSettingsService>(AppSettingsService(prefs));
  getIt.registerSingleton<ShellContentController>(ShellContentController());

  getIt.registerSingleton<ScreenStateService>(ScreenStateService());

  getIt.registerLazySingleton<P2PService>(() => P2PService());
  await getIt<P2PService>().ensureInitialized();
  await initApp();

  getIt.registerSingleton<EventBus>(EventBus());

  getIt.registerLazySingleton<NodeManagementService>(
    () => NodeManagementService(),
  );
  getIt.registerSingleton<VpnState>(VpnState());

  getIt.registerSingleton<PeerRpcRouter>(PeerRpcRouter());
  getIt.registerSingleton<PeerRpcClient>(PeerRpcClient());

  getIt.registerLazySingleton<P2PConfigService>(
    () => P2PConfigService(
      getIt<AppSettingsService>(),
      getIt<ServerState>(),
      getIt<VpnState>(),
    ),
  );

  getIt.registerLazySingleton<ServerState>(() => ServerState());
  getIt.registerLazySingleton<ServerStatusState>(() => ServerStatusState());
  getIt.registerLazySingleton<ServerPersistenceService>(
    () => ServerPersistenceService(),
  );

  getIt.registerLazySingleton<SettingsState>(() => SettingsState());
  getIt<SettingsState>().loadFromPersistence();

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

  getIt.registerLazySingleton<ConnectionService>(
    () => ConnectionService(
      getIt<P2PService>(),
      getIt<P2PConfigService>(),
      getIt<NodeManagementService>(),
      getIt<RoomPersistenceService>(),
      getIt<RoomState>(),
      getIt<VpnManager>(),
    ),
  );

  getIt.registerLazySingleton<FirewallService>(() => FirewallService());

  getIt.registerSingleton<UpdateState>(UpdateState());
  getIt.registerLazySingleton<UpdateService>(
    () => UpdateService(getIt<UpdateState>()),
  );

  getIt.registerLazySingleton<VpnManager>(
    () => VpnManager(getIt<VpnState>(), getIt<P2PService>()),
  );

  await _initPeerRpcRouter();
}

/// 释放所有服务资源
void disposeDI() {
  getIt<NodeManagementService>().dispose();
  getIt<ScreenStateService>().dispose();
  getIt<ServerStatusState>().dispose();
  getIt<PeerRpcClient>().dispose();
  getIt<PeerRpcRouter>().stop();
}

/// 注册 peer-RPC 路由器的方法集合。真正绑定到 EasyTier instance 的动作发生在
/// [`ConnectionService.connectToRoom`] 成功后；这里只完成「注册一次，多次连接复用」
/// 的 handler 装载。
Future<void> _initPeerRpcRouter() async {
  final router = getIt<PeerRpcRouter>();
  final appSettings = getIt<AppSettingsService>();
  final nodeManagement = getIt<NodeManagementService>();

  router.registerAll(UserMethods(appSettings).methods);
  router.registerAll(NodeMethods(nodeManagement).methods);
  router.registerAll(MessageMethods().methods);

  appLogger.i(
    '[PeerRpc] router ready (not yet bound), methods=${router.methodsCount}',
  );
}
