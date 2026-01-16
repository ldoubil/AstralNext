import 'package:flutter/material.dart';

class ThemeStore {
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.dark);

  void setMode(ThemeMode value) {
    mode.value = value;
  }
}
