import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  bool _isInitialized = false;
  bool _isMinimizedToTray = false;
  bool _isTraySupported = true; // Track if tray is supported on this platform

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if tray is supported on this platform
      if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
        debugPrint('⚠️ System tray not supported on ${Platform.operatingSystem}');
        _isTraySupported = false;
        return;
      }

      await trayManager.setIcon(
        Platform.isWindows ? 'assets/icon.ico' : 'assets/logo.png',
      );

      final menu = Menu(
        items: [
          MenuItem(
            key: 'show',
            label: '显示窗口',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit',
            label: '退出',
          ),
        ],
      );
      await trayManager.setContextMenu(menu);

      await trayManager.setToolTip('Astral');

      trayManager.addListener(this);
      _isInitialized = true;
      debugPrint('✅ System tray initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('⚠️ Failed to initialize system tray: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('💡 App will continue without system tray support');
      _isTraySupported = false;
      // Don't rethrow - allow app to continue without tray
    }
  }

  Future<void> minimizeToTray() async {
    if (!_isTraySupported || !_isInitialized) {
      // Fallback: just minimize the window
      await windowManager.minimize();
      debugPrint('ℹ️ Tray not available, window minimized instead');
      return;
    }
    
    await windowManager.hide();
    _isMinimizedToTray = true;
    await _showMinimizedNotification();
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.restore();
    _isMinimizedToTray = false;
  }

  bool get isMinimizedToTray => _isMinimizedToTray;
  bool get isTraySupported => _isTraySupported;

  Future<void> _showMinimizedNotification() async {
    final notification = LocalNotification(
      title: 'Astral',
      body: '程序已最小化到系统托盘，点击托盘图标可恢复窗口',
    );
    await notification.show();
  }

  @override
  void onTrayIconMouseDown() {
    if (_isTraySupported) {
      showWindow();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    if (_isTraySupported) {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (!_isTraySupported) return;
    
    switch (menuItem.key) {
      case 'show':
        showWindow();
        break;
      case 'exit':
        exitApp();
        break;
    }
  }

  void exitApp() {
    if (_isInitialized) {
      trayManager.removeListener(this);
      trayManager.destroy();
    }
    exit(0);
  }

  Future<void> destroy() async {
    if (_isInitialized) {
      trayManager.removeListener(this);
      await trayManager.destroy();
    }
  }
}
