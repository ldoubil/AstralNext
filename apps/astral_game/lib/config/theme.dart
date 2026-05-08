import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AstralGameTheme {
  static const Color _seedColor = Color(0xFF1B4DD7);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _darkSurface = Color(0xFF0F1115);

  static const _subThemesData = FlexSubThemesData(
    adaptiveRemoveElevationTint: FlexAdaptive.all(),
    adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
    thickBorderWidth: 0,
    thinBorderWidth: 0,
    outlinedButtonBorderWidth: 0,
    outlinedButtonPressedBorderWidth: 0,
    elevatedButtonElevation: 0,
    cardElevation: 0,
    dialogElevation: 0,
    bottomSheetElevation: 0,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorFocusedHasBorder: false,
    inputDecoratorUnfocusedHasBorder: false,
  );

  static ThemeData _applyCommonTheme(ThemeData base, Color surface) {
    final scheme = base.colorScheme;

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      shadowColor: Colors.transparent,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: scheme.surfaceTint.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        surfaceTintColor: scheme.surfaceTint.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: surface,
        surfaceTintColor: scheme.surfaceTint.withValues(alpha: 0.05),
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        selectedLabelTextStyle: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: IconThemeData(
          color: scheme.onPrimaryContainer.withValues(alpha: 0.72),
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onPrimaryContainer.withValues(alpha: 0.72),
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: scheme.primary,
        indicatorShape: const StadiumBorder(),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: scheme.primaryContainer,
        indicatorColor: scheme.primary,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData light() {
    final ThemeData base = FlexColorScheme.light(
      colors: FlexSchemeColor.from(primary: _seedColor),
      usedColors: 1,
      keyColors: const FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
      ),
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.level,
      blendLevel: 0,
      scaffoldBackground: _lightSurface,
      surface: _lightSurface,
      appBarElevation: 0,
      subThemesData: _subThemesData,
    ).toTheme;

    return _applyCommonTheme(base, _lightSurface);
  }

  static ThemeData dark() {
    final ThemeData base = FlexColorScheme.dark(
      colors: FlexSchemeColor.from(primary: _seedColor),
      usedColors: 1,
      keyColors: const FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
      ),
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.level,
      blendLevel: 0,
      scaffoldBackground: _darkSurface,
      surface: _darkSurface,
      appBarElevation: 0,
      subThemesData: _subThemesData,
    ).toTheme;

    return _applyCommonTheme(base, _darkSurface);
  }
}
