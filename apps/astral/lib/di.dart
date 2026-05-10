import 'package:astral/data/services/app_settings_service.dart';
import 'package:astral/data/services/instance_catalog_service.dart';
import 'package:astral/data/services/log_service.dart';
import 'package:astral/data/services/platform_path_service.dart';
import 'package:astral/data/services/toml_config_service.dart';
import 'package:astral/data/services/tray_service.dart';
import 'package:astral/data/services/webdav_backup_service.dart';
import 'package:astral/stores/global/global_p2p_store.dart';
import 'package:astral/stores/global/theme_store.dart';
import 'package:astral/ui/shell/shell_content_controller.dart';
import 'package:astral/ui/shell/shell_navigation_controller.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show initApp;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<AppSettingsService>(AppSettingsService(prefs));

  getIt.registerLazySingleton<LogService>(() => LogService());
  getIt.registerLazySingleton<P2PService>(() => P2PService());
  getIt.registerLazySingleton<PlatformPathService>(
    () => PlatformPathService(),
  );
  getIt.registerLazySingleton<TomlConfigService>(
    () => TomlConfigService(),
  );
  getIt.registerLazySingleton<InstanceCatalogService>(
    () => InstanceCatalogService(
      getIt<PlatformPathService>(),
      getIt<TomlConfigService>(),
    ),
  );
  getIt.registerLazySingleton<TrayService>(() => TrayService());
  getIt.registerLazySingleton<WebDavBackupService>(
    () => WebDavBackupService(
      getIt<AppSettingsService>(),
      getIt<PlatformPathService>(),
      getIt<InstanceCatalogService>(),
    ),
  );

  await getIt<P2PService>().ensureInitialized();
  await initApp();

  getIt.registerLazySingleton<GlobalP2PStore>(() => GlobalP2PStore());
  getIt.registerLazySingleton<ThemeStore>(() => ThemeStore());
  getIt<ThemeStore>().initialize();
  getIt.registerLazySingleton<ShellNavigationController>(
    () => ShellNavigationController(),
  );
  getIt.registerLazySingleton<ShellContentController>(
    () => ShellContentController(),
  );
}
