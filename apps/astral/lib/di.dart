import 'package:astral/data/services/log_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupDI() {
  // ------- Services: 单例 -------
  getIt.registerLazySingleton<LogService>(() => LogService()); // 日志服务单例
  // ------- Stores: 工厂（每次要新的）-------
}
