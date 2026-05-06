import 'package:astral_game/config/theme.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/ui/shell/shell.dart';
import 'package:flutter/material.dart';

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
    return MaterialApp(
      title: 'Astral Game',
      debugShowCheckedModeBanner: false,
      theme: AstralGameTheme.light(),
      darkTheme: AstralGameTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Shell(),
    );
  }
}
