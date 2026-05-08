import 'package:astral_game/config/theme.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/state/settings_state.dart';
import 'package:astral_game/ui/shell/shell.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class AstralGameApp extends StatefulWidget {
  const AstralGameApp({super.key});

  @override
  State<AstralGameApp> createState() => _AstralGameAppState();
}

class _AstralGameAppState extends State<AstralGameApp> with WidgetsBindingObserver {
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _safeDisposeDI();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _safeDisposeDI();
    }
  }

  void _safeDisposeDI() {
    if (!_disposed) {
      _disposed = true;
      disposeDI();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = getIt<SettingsState>();

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return Watch((context) {
          final seed = settingsState.seedColor.value;
          final useDynamic = settingsState.useDynamicColor.value;

          return MaterialApp(
            title: 'Astral Game',
            debugShowCheckedModeBanner: false,
            theme: AstralGameTheme.light(
              seedColor: seed,
              dynamicScheme: useDynamic ? lightDynamic : null,
            ),
            darkTheme: AstralGameTheme.dark(
              seedColor: seed,
              dynamicScheme: useDynamic ? darkDynamic : null,
            ),
            themeMode: settingsState.themeMode.value,
            home: const Shell(),
          );
        });
      },
    );
  }
}
