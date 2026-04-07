import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String _keyWebDavUrl = 'webdav_url';
  static const String _keyWebDavUsername = 'webdav_username';
  static const String _keyWebDavPassword = 'webdav_password';
  static const String _keyWebDavRemotePath = 'webdav_remote_path';

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
}
