import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AstralTheme {
  static const Color _seedColor = Color(0xFF1B4DD7);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _darkSurface = Color(0xFF0F1115);

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
      subThemesData: const FlexSubThemesData(
        interactionEffects: false,
        splashType: FlexSplashType.noSplash,
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
      ),
    ).toTheme;

    final scheme = base.colorScheme;

    return base.copyWith(
      scaffoldBackgroundColor: _lightSurface,
      shadowColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        selectedLabelTextStyle: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: IconThemeData(
          color: scheme.onPrimaryContainer.withOpacity(0.72),
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onPrimaryContainer.withOpacity(0.72),
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
      subThemesData: const FlexSubThemesData(
        interactionEffects: false,
        splashType: FlexSplashType.noSplash,
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
      ),
    ).toTheme;

    final scheme = base.colorScheme;

    return base.copyWith(
      scaffoldBackgroundColor: _darkSurface,
      shadowColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        selectedLabelTextStyle: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: IconThemeData(
          color: scheme.onPrimaryContainer.withOpacity(0.72),
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onPrimaryContainer.withOpacity(0.72),
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
}
