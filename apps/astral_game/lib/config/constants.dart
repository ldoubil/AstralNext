import 'dart:ui';

import 'package:flutter/painting.dart';

/// MD3 设计规范 - 圆角
class AppRadius {
  AppRadius._();
  static final brSmall = BorderRadius.all(Radius.circular(8));
  static final brMedium = BorderRadius.all(Radius.circular(12));
  static final brLarge = BorderRadius.all(Radius.circular(16));
}

/// MD3 设计规范 - 状态颜色（语义色）
class AppColors {
  AppColors._();
  static const Color online = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF2196F3);
}

/// 应用常量定义
class AppConstants {
  AppConstants._();

  // 默认 IP 地址
  static const String defaultVirtualIp = '10.147.18.24';

  // 网络相关
  static const Duration pollingInterval = Duration(seconds: 3);
  static const Duration pingTimeout = Duration(seconds: 5);
  static const int maxPingLatencyMs = 800;

  // UUID 显示长度
  static const int uuidDisplayLength = 8;

  // 主机名过滤
  static const String publicServerHostname = 'PublicServer';

  // 版本号
  static const String appVersion = '1.0.0';

  // GitHub 更新检测
  static const String githubOwner = 'ldoubil';
  static const String githubRepo = 'astral';
  static const String githubReleasesUrl =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases?per_page=20';
  static const String githubReleasesPage =
      'https://github.com/$githubOwner/$githubRepo/releases';

  // 公共服务器列表
  static const String publicServerListUrl =
      'https://astral.fan/new_server.json';

  // RSA 私钥（用于解密公共服务器 URL）
  static const String rsaPrivateKey =
      'MIICXgIBAAKBgQC5U+V1qzALy81qf9Ug14XgqKphjX15Rq9ufEGm5ZOWzDDgBWhLGKxYrtd9CVbGp+QPATXIS6cQolMm//3VJ90dbqWcH/IjDP7kSkMANjM5YB3qWvODnhRCglng/p+1NmlOP04wAMFn7gR8cHzYaCrK9jC9O+0ro7QwCsMYdmQdFwIDAQABAoGAAP3eEfVBObKR4/St+VHg0tUP2coN/FNfLzdM5+faq7ranhj8OAR4X0FKzCrklHovas/dQTf73l7H/ZRjXQGsduS/uo1qSweXcj5SMgX0/DuxrDPsOQD27TNLvyr7VbMqm2imFNDhVIMxn7JbGE6bpmRbPjjMcM83qD6dyksNe7ECQQDew/qFidtCPyCTAwVhgci/do+U9lrbtwKpVlnVPoKUxETLajdum2pcXdNKUgsM0TmUmX3u6NpJt0LdcRaW98WnAkEA1PoQynfiEs4WPmEClXEX//0BrRcgyqTvYnWib7lL4dO8UQ54SKSXnbI4vjGeSgbpRqXbSvDC0YjInBcK2Nm7EQJBAKH2eVHYDjtXLHbWrnXbZ7qVGAWlLCAtKlk2ODBLt6M0JBSFUHIxux4W9YVGq1QRVr0M8Dvgvrzz6kCYdWUkFmcCQQCARdy3FV1kVhuvll4oA+WgmJHZ3oQxiQVlF9St1byOVyik6UIo/nkS0bS7WMctbtwxYNOjXz73VJr+6CHwWbMBAkEA3psQGdgNQnfUS8AtB7VyobzhjAdK2PVKjlxULtjPhIXSlPwdlKUr1IOqxnUqFH/x0DEXU8SlPDinDQPKeOsZbg==';
}
