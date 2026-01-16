// lib/ui/app.dart
import 'package:astral/ui/shell/shell.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AstralApp extends StatefulWidget {
  const AstralApp({super.key});

  @override
  State<AstralApp> createState() => _AstralAppState();
}

class _AstralAppState extends State<AstralApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Astral',
      debugShowCheckedModeBanner: false,
      theme: FlexColorScheme.light(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ).toTheme,
      themeMode: ThemeMode.light,
      home: const Shell(),
    );
  }
}
