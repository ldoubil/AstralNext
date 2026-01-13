// lib/ui/app.dart
import 'package:flutter/material.dart';

class AstralApp extends StatelessWidget {
  const AstralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Astral',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('Welcome to Astral App!'))),
    );
  }
}
