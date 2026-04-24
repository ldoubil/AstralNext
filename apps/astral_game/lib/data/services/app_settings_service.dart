import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String _keyWebDavUrl = 'webdav_url';
  static const String _keyWebDavUsername = 'webdav_username';
  static const String _keyWebDavPassword = 'webdav_password';
  static const String _keyWebDavRemotePath = 'webdav_remote_path';
  
  // 用户信息
  static const String _keyUsername = 'username';
  static const String _keyAvatar = 'avatar';

  final SharedPreferences _prefs;

  AppSettingsService(this._prefs);

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
    // TODO: 获取系统用户名作为默认值
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
      print('[AppSettingsService] Failed to decode avatar: $e');
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
}
