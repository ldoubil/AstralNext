import 'package:astral/data/services/app_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ThemeStore {
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.dark);
  final ValueNotifier<Color> seedColor = ValueNotifier(const Color(0xFF1B4DD7));

  void initialize() {
    final settings = GetIt.I<AppSettingsService>();
    mode.value = settings.getThemeMode();
    seedColor.value = settings.getThemeSeedColor();
  }

  void setMode(ThemeMode value) {
    mode.value = value;
    final settings = GetIt.I<AppSettingsService>();
    settings.setThemeMode(value);
  }

  void setSeedColor(Color color) {
    seedColor.value = color;
    final settings = GetIt.I<AppSettingsService>();
    settings.setThemeSeedColor(color);
  }
}
