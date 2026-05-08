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
