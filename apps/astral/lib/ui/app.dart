// lib/ui/app.dart
import 'package:astral/config/theme.dart';
import 'package:astral/data/services/platform_path_service.dart';
import 'package:astral/di.dart';
import 'package:astral/stores/global/theme_store.dart';
import 'package:astral/ui/shell/shell.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class AstralApp extends StatefulWidget {
  const AstralApp({super.key});

  @override
  State<AstralApp> createState() => _AstralAppState();
}

class _AstralAppState extends State<AstralApp> {
  final _themeStore = GetIt.I<ThemeStore>();
  @override
  void initState() {
    super.initState();
    getIt<PlatformPathService>().configDir().then((dir) {
      debugPrint('Config directory: ${dir.path}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeStore.mode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: _themeStore.seedColor,
          builder: (context, seedColor, _) {
            return MaterialApp(
              title: 'Astral',
              debugShowCheckedModeBanner: false,
              theme: AstralTheme.light(seedColor: seedColor),
              darkTheme: AstralTheme.dark(seedColor: seedColor),
              themeMode: mode,
              home: const Shell(),
            );
          },
        );
      },
    );
  }
}
