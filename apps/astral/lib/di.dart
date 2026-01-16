import 'package:astral/data/services/log_service.dart';
import 'package:astral/stores/global/global_p2p_store.dart';
import 'package:astral/stores/global/theme_store.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupDI() {
  // ------- Services: 单例 -------
  getIt.registerLazySingleton<LogService>(() => LogService()); // 日志服务单例
  getIt.registerLazySingleton<P2PService>(() => P2PService()); // P2P 服务单例
  // ------- Stores（全局和局部不同）-------
  getIt.registerLazySingleton<GlobalP2PStore>(() => GlobalP2PStore());
  getIt.registerLazySingleton<ThemeStore>(() => ThemeStore());
}
