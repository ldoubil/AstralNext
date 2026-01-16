import 'package:flutter/material.dart';

class AstralTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1B4DD7),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFDCE6FF),
      onPrimaryContainer: Color(0xFF0B1A40),
      secondary: Color(0xFF008AA8),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFD3F3FF),
      onSecondaryContainer: Color(0xFF00333D),
      tertiary: Color(0xFF5E5CE6),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE3E1FF),
      onTertiaryContainer: Color(0xFF1A1860),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      background: Color(0xFFF3F5F8),
      onBackground: Color(0xFF0E1116),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF111318),
      surfaceVariant: Color(0xFFE5E9F2),
      onSurfaceVariant: Color(0xFF434A56),
      outline: Color(0xFF8B93A1),
      outlineVariant: Color(0xFFC9CED9),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF1C1F26),
      onInverseSurface: Color(0xFFF4F5F7),
      inversePrimary: Color(0xFFB6C5FF),
      surfaceTint: Color(0xFF1B4DD7),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceVariant,
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme:
            IconThemeData(color: scheme.onSurfaceVariant),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF7AA2FF),
      onPrimary: Color(0xFF0B1430),
      primaryContainer: Color(0xFF203070),
      onPrimaryContainer: Color(0xFFDCE6FF),
      secondary: Color(0xFF6AD7FF),
      onSecondary: Color(0xFF003040),
      secondaryContainer: Color(0xFF0E3A4A),
      onSecondaryContainer: Color(0xFFCFEFFF),
      tertiary: Color(0xFFB8A5FF),
      onTertiary: Color(0xFF1D123C),
      tertiaryContainer: Color(0xFF33255C),
      onTertiaryContainer: Color(0xFFE5DCFF),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFF9DEDC),
      background: Color(0xFF0E1218),
      onBackground: Color(0xFFE6EAF0),
      surface: Color(0xFF0E1218),
      onSurface: Color(0xFFE6EAF0),
      surfaceVariant: Color(0xFF1B2230),
      onSurfaceVariant: Color(0xFFB9C1D4),
      outline: Color(0xFF78819A),
      outlineVariant: Color(0xFF323A4B),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE6EAF0),
      onInverseSurface: Color(0xFF151922),
      inversePrimary: Color(0xFF1B4DD7),
      surfaceTint: Color(0xFF7AA2FF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme:
            IconThemeData(color: scheme.onSurfaceVariant),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
