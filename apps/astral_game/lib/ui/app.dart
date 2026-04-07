import 'package:astral_game/config/theme.dart';
import 'package:astral_game/ui/shell/shell.dart';
import 'package:flutter/material.dart';

class AstralGameApp extends StatelessWidget {
  const AstralGameApp({super.key});

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
