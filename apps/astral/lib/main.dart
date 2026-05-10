import 'dart:io';
import 'dart:ui' as ui;

import 'package:astral/data/services/tray_service.dart';
import 'package:astral/di.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:window_manager/window_manager.dart';

import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ui.DartPluginRegistrant.ensureInitialized();
  
  // Initialize window_manager only on desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(940, 560),
      minimumSize: Size(800, 500),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // 隐藏系统标题栏
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  try {
    await localNotifier.setup(
      appName: 'Astral',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  } catch (e) {
    debugPrint('⚠️ Failed to setup local notifier: $e');
    debugPrint('💡 Notifications will be disabled');
  }

  await setupDI();

  try {
    final trayService = getIt<TrayService>();
    await trayService.initialize();
    
    if (!trayService.isTraySupported) {
      debugPrint('ℹ️ Running without system tray support');
    }
  } catch (e) {
    debugPrint('⚠️ Critical error during initialization: $e');
    // Continue anyway - app can run without tray
  }

  runApp(const AstralApp());
}
