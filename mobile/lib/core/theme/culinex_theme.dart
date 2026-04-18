import 'package:flutter/material.dart';

@immutable
class CulinexPalette extends ThemeExtension<CulinexPalette> {
  const CulinexPalette({
    required this.canvas,
    required this.surface,
    required this.elevatedSurface,
    required this.ink,
    required this.mutedInk,
    required this.subtleInk,
    required this.accent,
    required this.onAccent,
    required this.border,
    required this.shadow,
  });

  final Color canvas;
  final Color surface;
  final Color elevatedSurface;
  final Color ink;
  final Color mutedInk;
  final Color subtleInk;
  final Color accent;
  final Color onAccent;
  final Color border;
  final Color shadow;

  static const CulinexPalette light = CulinexPalette(
    canvas: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    elevatedSurface: Color(0xFFF5F5F5),
    ink: Color(0xFF111111),
    mutedInk: Color(0xFF666666),
    subtleInk: Color(0xFF9B9B9B),
    accent: Color(0xFF111111),
    onAccent: Colors.white,
    border: Color(0xFFE5E5E5),
    shadow: Color(0x0D000000),
  );

  static const CulinexPalette dark = CulinexPalette(
    canvas: Color(0xFF0D0F11),
    surface: Color(0xFF16191C),
    elevatedSurface: Color(0xFF21262A),
    ink: Color(0xFFF4F1EA),
    mutedInk: Color(0xFFB3B7BC),
    subtleInk: Color(0xFF8E949A),
    accent: Color(0xFFF4F1EA),
    onAccent: Color(0xFF101214),
    border: Color(0xFF30353A),
    shadow: Color(0x52000000),
  );

  @override
  CulinexPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? elevatedSurface,
    Color? ink,
    Color? mutedInk,
    Color? subtleInk,
    Color? accent,
    Color? onAccent,
    Color? border,
    Color? shadow,
  }) {
    return CulinexPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      ink: ink ?? this.ink,
      mutedInk: mutedInk ?? this.mutedInk,
      subtleInk: subtleInk ?? this.subtleInk,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  CulinexPalette lerp(
    covariant ThemeExtension<CulinexPalette>? other,
    double t,
  ) {
    if (other is! CulinexPalette) {
      return this;
    }

    return CulinexPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
      subtleInk: Color.lerp(subtleInk, other.subtleInk, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

class CulinexColors {
  static const Color quantityBlue = Color(0xFF3566B8);
  static const Color confidenceHigh = Color(0xFF2F7A48);
  static const Color confidenceMedium = Color(0xFFB56A1F);
  static const Color confidenceLow = Color(0xFFB34545);

  static CulinexPalette of(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return theme.extension<CulinexPalette>() ??
        (theme.brightness == Brightness.dark
            ? CulinexPalette.dark
            : CulinexPalette.light);
  }
}

ThemeData buildCulinexTheme({Brightness brightness = Brightness.light}) {
  final CulinexPalette palette = brightness == Brightness.dark
      ? CulinexPalette.dark
      : CulinexPalette.light;
  final ColorScheme seedColorScheme = ColorScheme.fromSeed(
    brightness: brightness,
    seedColor: palette.accent,
  );
  final ColorScheme colorScheme = seedColorScheme.copyWith(
    primary: palette.accent,
    onPrimary: palette.onAccent,
    secondary: palette.accent,
    onSecondary: palette.onAccent,
    surface: palette.surface,
    onSurface: palette.ink,
    outline: palette.border,
    outlineVariant: palette.border,
    shadow: palette.shadow,
    surfaceContainerLowest: palette.canvas,
    surfaceContainerLow: palette.surface,
    surfaceContainer: palette.elevatedSurface,
    surfaceContainerHigh: palette.elevatedSurface,
    surfaceContainerHighest: palette.elevatedSurface,
  );

  final TextTheme baseTextTheme = brightness == Brightness.dark
      ? Typography.material2021().white
      : Typography.material2021().black;
  final TextTheme textTheme = baseTextTheme.apply(
    bodyColor: palette.ink,
    displayColor: palette.ink,
  );
  final OutlineInputBorder inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(22),
    borderSide: BorderSide(color: palette.border),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    extensions: <ThemeExtension<dynamic>>[palette],
    scaffoldBackgroundColor: palette.canvas,
    canvasColor: palette.canvas,
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
        color: palette.ink,
        height: 1.45,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        color: palette.mutedInk,
        height: 1.45,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    dividerColor: palette.border,
    cardColor: palette.surface,
    iconTheme: IconThemeData(color: palette.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: palette.ink,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
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
        foregroundColor: palette.ink,
        minimumSize: const Size.fromHeight(56),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.elevatedSurface,
      selectedColor: palette.accent,
      disabledColor: palette.border,
      side: const BorderSide(color: Colors.transparent),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: textTheme.labelMedium?.copyWith(
        color: palette.ink,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      labelStyle: textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
      hintStyle: textTheme.bodyMedium?.copyWith(color: palette.subtleInk),
      counterStyle: textTheme.bodySmall?.copyWith(color: palette.mutedInk),
      errorMaxLines: 2,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: palette.accent, width: 1.4),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: CulinexColors.confidenceLow),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(
          color: CulinexColors.confidenceLow,
          width: 1.4,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.canvas),
      actionTextColor: palette.canvas,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: palette.border),
    ),
  );
}
