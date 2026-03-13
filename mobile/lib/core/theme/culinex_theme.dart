import 'package:flutter/material.dart';

class CulinexColors {
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFF5F5F5);
  static const Color ink = Color(0xFF111111);
  static const Color mutedInk = Color(0xFF666666);
  static const Color accent = Color(0xFF111111);
  static const Color accentDeep = Color(0xFF111111);
  static const Color border = Color(0xFFE5E5E5);
  static const Color subtleInk = Color(0xFF9B9B9B);
  static const Color quantityBlue = Color(0xFF3566B8);
  static const Color confidenceHigh = Color(0xFF2F7A48);
  static const Color confidenceMedium = Color(0xFFB56A1F);
  static const Color confidenceLow = Color(0xFFB34545);
}

ThemeData buildCulinexTheme() {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: CulinexColors.ink,
    surface: CulinexColors.surface,
    primary: CulinexColors.ink,
    onPrimary: Colors.white,
    onSurface: CulinexColors.ink,
  );

  final TextTheme textTheme = Typography.material2021().black.apply(
    bodyColor: CulinexColors.ink,
    displayColor: CulinexColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: CulinexColors.canvas,
    textTheme: textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.04,
        letterSpacing: -1.4,
      ),
      displayMedium: textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.08,
        letterSpacing: -1.1,
      ),
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.08,
        letterSpacing: -0.9,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.6,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        color: CulinexColors.ink,
        height: 1.45,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        color: CulinexColors.mutedInk,
        height: 1.45,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    dividerColor: CulinexColors.border,
    cardColor: CulinexColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: CulinexColors.ink,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CulinexColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CulinexColors.ink,
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: CulinexColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CulinexColors.elevatedSurface,
      selectedColor: CulinexColors.ink,
      disabledColor: CulinexColors.border,
      side: const BorderSide(color: Colors.transparent),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: textTheme.labelMedium?.copyWith(
        color: CulinexColors.ink,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
