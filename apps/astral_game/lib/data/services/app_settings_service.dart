import 'dart:convert';
import 'dart:typed_data';
import 'package:astral_game/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String _keyWebDavUrl = 'webdav_url';
  static const String _keyWebDavUsername = 'webdav_username';
  static const String _keyWebDavPassword = 'webdav_password';
  static const String _keyWebDavRemotePath = 'webdav_remote_path';
  
  // 用户信息
  static const String _keyUsername = 'username';
  static const String _keyAvatar = 'avatar';

  // 通用设置
  static const String _keyCloseMinimize = 'close_minimize';
  static const String _keyUserListSimple = 'user_list_simple';
  static const String _keyEnableBannerCarousel = 'enable_banner_carousel';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyUseDynamicColor = 'use_dynamic_color';
  static const String _keySeedColor = 'seed_color';

  // 网络设置
  static const String _keyDefaultProtocol = 'default_protocol';
  static const String _keyEnableEncryption = 'enable_encryption';
  static const String _keyLatencyFirst = 'latency_first';
  static const String _keyDataCompressAlgo = 'data_compress_algo';
  static const String _keyListenList = 'listen_list';
  static const String _keyIsDhcp = 'is_dhcp';
  static const String _keyVirtualIp = 'virtual_ip';

  final SharedPreferences _prefs;

  AppSettingsService(this._prefs);

  // ---- 主题/外观 ----

  /// 主题模式：system / light / dark
  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String value) async =>
      await _prefs.setString(_keyThemeMode, value);

  /// 是否启用系统动态取色（Material You）
  bool getUseDynamicColor() => _prefs.getBool(_keyUseDynamicColor) ?? false;
  Future<void> setUseDynamicColor(bool value) async =>
      await _prefs.setBool(_keyUseDynamicColor, value);

  /// 自定义主题主色（ARGB int）。未设置时返回默认值。
  int getSeedColor() => _prefs.getInt(_keySeedColor) ?? 0xFF1B4DD7;
  Future<void> setSeedColor(int argb) async =>
      await _prefs.setInt(_keySeedColor, argb);

  // ---- WebDAV 配置 ----

  String? getWebDavUrl() => _prefs.getString(_keyWebDavUrl);
  Future<void> setWebDavUrl(String url) async =>
      await _prefs.setString(_keyWebDavUrl, url);
  Future<void> clearWebDavUrl() async =>
      await _prefs.remove(_keyWebDavUrl);

  String? getWebDavUsername() => _prefs.getString(_keyWebDavUsername);
  Future<void> setWebDavUsername(String username) async =>
      await _prefs.setString(_keyWebDavUsername, username);
  Future<void> clearWebDavUsername() async =>
      await _prefs.remove(_keyWebDavUsername);

  String? getWebDavPassword() => _prefs.getString(_keyWebDavPassword);
  Future<void> setWebDavPassword(String password) async =>
      await _prefs.setString(_keyWebDavPassword, password);
  Future<void> clearWebDavPassword() async =>
      await _prefs.remove(_keyWebDavPassword);

  String? getWebDavRemotePath() => _prefs.getString(_keyWebDavRemotePath);
  Future<void> setWebDavRemotePath(String path) async =>
      await _prefs.setString(_keyWebDavRemotePath, path);
  Future<void> clearWebDavRemotePath() async =>
      await _prefs.remove(_keyWebDavRemotePath);

  bool isWebDavConfigured() {
    final url = getWebDavUrl();
    return url != null && url.isNotEmpty;
  }

  Future<void> clearAllWebDavSettings() async {
    await Future.wait([
      clearWebDavUrl(),
      clearWebDavUsername(),
      clearWebDavPassword(),
      clearWebDavRemotePath(),
    ]);
  }

  // ---- 网络配置 ----

  static const String _keyDisableP2p = 'disable_p2p';

  bool isDisableP2p() => _prefs.getBool(_keyDisableP2p) ?? false;
  Future<void> setDisableP2p(bool value) async =>
      await _prefs.setBool(_keyDisableP2p, value);

  // ---- 用户信息 ----

  /// 获取用户名，如果为空则返回系统用户名
  String getUsername() {
    final savedUsername = _prefs.getString(_keyUsername);
    if (savedUsername != null && savedUsername.isNotEmpty) {
      return savedUsername;
    }
    return '玩家';
  }

  /// 设置用户名
  Future<void> setUsername(String username) async =>
      await _prefs.setString(_keyUsername, username);

  /// 获取头像数据（Base64 编码）
  Uint8List? getAvatar() {
    final avatarBase64 = _prefs.getString(_keyAvatar);
    if (avatarBase64 == null || avatarBase64.isEmpty) {
      return null;
    }
     try {
      return base64Decode(avatarBase64);
    } catch (e) {
      appLogger.e('[AppSettingsService] Failed to decode avatar: $e');
      return null;
    }
  }

  /// 设置头像数据
  Future<void> setAvatar(Uint8List avatar) async {
    final avatarBase64 = base64Encode(avatar);
    await _prefs.setString(_keyAvatar, avatarBase64);
  }

  /// 清除头像
  Future<void> clearAvatar() async =>
      await _prefs.remove(_keyAvatar);

  // ---- 通用设置 ----

  /// 获取关闭时最小化设置
  bool getCloseMinimize() => _prefs.getBool(_keyCloseMinimize) ?? true;
  Future<void> setCloseMinimize(bool value) async =>
      await _prefs.setBool(_keyCloseMinimize, value);

  /// 获取用户列表简化模式
  bool getUserListSimple() => _prefs.getBool(_keyUserListSimple) ?? true;
  Future<void> setUserListSimple(bool value) async =>
      await _prefs.setBool(_keyUserListSimple, value);

  /// 获取启用横幅轮播
  bool getEnableBannerCarousel() => _prefs.getBool(_keyEnableBannerCarousel) ?? true;
  Future<void> setEnableBannerCarousel(bool value) async =>
      await _prefs.setBool(_keyEnableBannerCarousel, value);

  // ---- 网络设置 ----

  /// 获取默认协议
  String getDefaultProtocol() => _prefs.getString(_keyDefaultProtocol) ?? 'tcp';
  Future<void> setDefaultProtocol(String value) async =>
      await _prefs.setString(_keyDefaultProtocol, value);

  /// 获取启用加密
  bool getEnableEncryption() => _prefs.getBool(_keyEnableEncryption) ?? true;
  Future<void> setEnableEncryption(bool value) async =>
      await _prefs.setBool(_keyEnableEncryption, value);

  /// 获取延迟优先
  bool getLatencyFirst() => _prefs.getBool(_keyLatencyFirst) ?? false;
  Future<void> setLatencyFirst(bool value) async =>
      await _prefs.setBool(_keyLatencyFirst, value);

  /// 获取数据压缩算法
  int getDataCompressAlgo() => _prefs.getInt(_keyDataCompressAlgo) ?? 1;
  Future<void> setDataCompressAlgo(int value) async =>
      await _prefs.setInt(_keyDataCompressAlgo, value);

  /// 获取监听列表
  List<String> getListenList() => _prefs.getStringList(_keyListenList) ?? [
        'tcp://0.0.0.0:0',
        'udp://0.0.0.0:0',
      ];
  Future<void> setListenList(List<String> value) async =>
      await _prefs.setStringList(_keyListenList, value);

  /// 获取是否使用 DHCP
  bool getIsDhcp() => _prefs.getBool(_keyIsDhcp) ?? true;
  Future<void> setIsDhcp(bool value) async =>
      await _prefs.setBool(_keyIsDhcp, value);

  /// 获取虚拟 IP
  String getVirtualIp() => _prefs.getString(_keyVirtualIp) ?? '10.147.18.24';
  Future<void> setVirtualIp(String value) async =>
      await _prefs.setString(_keyVirtualIp, value);
}
