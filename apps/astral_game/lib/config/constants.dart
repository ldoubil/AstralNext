import 'dart:ui';

/// MD3 设计规范 - 圆角
class AppRadius {
  AppRadius._();
  static const none = Radius.zero;
  static const extraSmall = Radius.circular(4);
  static const small = Radius.circular(8);
  static const medium = Radius.circular(12);
  static const large = Radius.circular(16);
  static const extraLarge = Radius.circular(28);
  static const full = Radius.circular(9999);

  static const brNone = BorderRadius.all(none);
  static const brExtraSmall = BorderRadius.all(extraSmall);
  static const brSmall = BorderRadius.all(small);
  static const brMedium = BorderRadius.all(medium);
  static const brLarge = BorderRadius.all(large);
  static const brExtraLarge = BorderRadius.all(extraLarge);
}

/// MD3 设计规范 - 状态颜色（语义色）
class AppColors {
  AppColors._();
  static const Color online = Color(0xFF4CAF50);
  static const Color onlineLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
}

/// MD3 设计规范 - 交互状态层透明度
class AppStateLayer {
  AppStateLayer._();
  static const double hover = 0.08;
  static const double focus = 0.12;
  static const double pressed = 0.12;
  static const double dragged = 0.16;
}

/// 应用常量定义
class AppConstants {
  AppConstants._();

  // 默认 IP 地址
  static const String defaultVirtualIp = '10.147.18.24';

  // 窗口尺寸
  static const double defaultWindowWidth = 940;
  static const double defaultWindowHeight = 560;

  // 网络相关
  static const int defaultNodePort = 4924;
  static const int defaultRoomPort = 11010;
  static const int maxRetries = 3;
  static const Duration pollingInterval = Duration(seconds: 3);
  static const Duration ipReadyCheckInterval = Duration(seconds: 2);
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration pingTimeout = Duration(seconds: 5);
  static const int maxPingLatencyMs = 800;

  // 屏幕断点
  static const double narrowBreakpoint = 600;

  // UUID 显示长度
  static const int uuidDisplayLength = 8;

  // 主机名过滤
  static const String publicServerHostname = 'PublicServer';

  // 无效 IP
  static const String invalidIp = '0.0.0.0';

  // 实例名称
  static const String instanceName = 'AstralGame';

  // 备份路径
  static const String backupDirectory = 'astral_game/backups';

  // 版本号（TODO: 从 package_info_plus 获取）
  static const String appVersion = '1.0.0';

  // GitHub 更新检测
  static const String githubOwner = 'ldoubil';
  static const String githubRepo = 'astral';
  static const String githubReleasesUrl =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases?per_page=20';
  static const String githubReleasesPage =
      'https://github.com/$githubOwner/$githubRepo/releases';
}
