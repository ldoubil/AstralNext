import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CloseBehavior {
  minimizeToTray,
  exitApp,
}

enum ConfigEditorDefaultMode {
  visual,
  text,
}

class AppSettingsService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyThemeSeedColor = 'theme_seed_color';
  static const String _keyCloseBehavior = 'close_behavior';
  static const String _keySourceDir = 'source_dir';
  static const String _keyEditorDefaultMode = 'editor_default_mode';

  static const String _keyWebDavUrl = 'webdav_url';
  static const String _keyWebDavUsername = 'webdav_username';
  static const String _keyWebDavPassword = 'webdav_password';
  static const String _keyWebDavRemotePath = 'webdav_remote_path';

  final SharedPreferences _prefs;

  AppSettingsService(this._prefs);

  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    if (value == null) return ThemeMode.dark;
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await _prefs.setString(_keyThemeMode, value);
  }

  Color getThemeSeedColor() {
    final value = _prefs.getInt(_keyThemeSeedColor);
    if (value == null) return const Color(0xFF1B4DD7);
    return Color(value);
  }

  Future<void> setThemeSeedColor(Color color) async {
    await _prefs.setInt(_keyThemeSeedColor, color.value);
  }

  CloseBehavior getCloseBehavior() {
    final value = _prefs.getString(_keyCloseBehavior);
    if (value == null) return CloseBehavior.minimizeToTray;
    switch (value) {
      case 'minimizeToTray':
        return CloseBehavior.minimizeToTray;
      case 'exitApp':
        return CloseBehavior.exitApp;
      default:
        return CloseBehavior.minimizeToTray;
    }
  }

  Future<void> setCloseBehavior(CloseBehavior behavior) async {
    String value;
    switch (behavior) {
      case CloseBehavior.minimizeToTray:
        value = 'minimizeToTray';
        break;
      case CloseBehavior.exitApp:
        value = 'exitApp';
        break;
    }
    await _prefs.setString(_keyCloseBehavior, value);
  }

  String? getSourceDir() {
    return _prefs.getString(_keySourceDir);
  }

  Future<void> setSourceDir(String? path) async {
    if (path == null || path.isEmpty) {
      await _prefs.remove(_keySourceDir);
    } else {
      await _prefs.setString(_keySourceDir, path);
    }
  }

  Future<void> clearSourceDir() async {
    await _prefs.remove(_keySourceDir);
  }

  ConfigEditorDefaultMode getEditorDefaultMode() {
    // 历史版本未写入该配置时，默认回退到可视化编辑模式。
    return _prefs.getString(_keyEditorDefaultMode) == 'text'
        ? ConfigEditorDefaultMode.text
        : ConfigEditorDefaultMode.visual;
  }

  Future<void> setEditorDefaultMode(ConfigEditorDefaultMode mode) async {
    final value = switch (mode) {
      ConfigEditorDefaultMode.visual => 'visual',
      ConfigEditorDefaultMode.text => 'text',
    };
    await _prefs.setString(_keyEditorDefaultMode, value);
  }

  // ---- WebDAV 配置 ----

  String? getWebDavUrl() => _prefs.getString(_keyWebDavUrl);
  Future<void> setWebDavUrl(String url) async =>
      await _prefs.setString(_keyWebDavUrl, url);
  Future<void> clearWebDavUrl() async => await _prefs.remove(_keyWebDavUrl);

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
}
