import 'package:flutter/material.dart';

import '../../core/localization/app_locale.dart';
import '../../core/theme/culinex_theme.dart';
import '../../l10n/l10n.dart';

class CulinexHeader extends StatelessWidget {
  const CulinexHeader({
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.locale,
    required this.onSelectLocale,
    super.key,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Locale locale;
  final ValueChanged<Locale> onSelectLocale;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: CulinexBrandLockup()),
        const SizedBox(width: 12),
        CulinexLanguageToggle(
          locale: locale,
          onSelectLocale: onSelectLocale,
          buttonKey: const ValueKey<String>('language-toggle-button'),
        ),
        const SizedBox(width: 12),
        CulinexThemeIconButton(
          isDarkMode: isDarkMode,
          onPressed: onToggleTheme,
        ),
      ],
    );
  }
}

class CulinexBrandHeader extends StatelessWidget {
  const CulinexBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: CulinexBrandLockup())],
    );
  }
}

class CulinexBrandLockup extends StatelessWidget {
  const CulinexBrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Brightness brightness = Theme.of(context).brightness;
    final CulinexPalette colors = CulinexColors.of(context);
    final String logoAsset = brightness == Brightness.dark
        ? 'assets/icon/icon_transparent_dark.png'
        : 'assets/icon/icon_transparent.png';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: colors.accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Image.asset(
            logoAsset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Culinex',
            style: textTheme.displaySmall?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class CulinexThemeIconButton extends StatelessWidget {
  const CulinexThemeIconButton({
    required this.isDarkMode,
    required this.onPressed,
    super.key,
    this.buttonKey = const ValueKey<String>('theme-toggle-button'),
  });

  final bool isDarkMode;
  final VoidCallback onPressed;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: IconButton(
        key: buttonKey,
        tooltip: isDarkMode ? l10n.switchToLightMode : l10n.switchToDarkMode,
        onPressed: onPressed,
        style: const ButtonStyle(
          overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
        icon: Icon(
          isDarkMode ? Icons.dark_mode_outlined : Icons.wb_sunny_outlined,
          key: ValueKey<String>(
            isDarkMode ? 'theme-icon-dark' : 'theme-icon-light',
          ),
        ),
      ),
    );
  }
}

class CulinexLanguageToggle extends StatelessWidget {
  const CulinexLanguageToggle({
    required this.locale,
    required this.onSelectLocale,
    super.key,
    this.buttonKey,
    this.width = 108,
  });

  final Locale locale;
  final ValueChanged<Locale> onSelectLocale;
  final Key? buttonKey;
  final double width;

  @override
  Widget build(BuildContext context) {
    final bool isUkrainian = AppLocale.isUkrainian(locale);
    final l10n = context.l10n;

    return Semantics(
      button: true,
      value: isUkrainian
          ? l10n.languageUkrainianShort
          : l10n.languageEnglishShort,
      child: CulinexSegmentedToggle(
        leftLabel: l10n.languageEnglishShort,
        rightLabel: l10n.languageUkrainianShort,
        rightSelected: isUkrainian,
        width: width,
        tooltip: isUkrainian ? l10n.switchToEnglish : l10n.switchToUkrainian,
        buttonKey: buttonKey,
        onPressed: () {
          onSelectLocale(isUkrainian ? AppLocale.english : AppLocale.ukrainian);
        },
      ),
    );
  }
}

class CulinexAppearanceToggle extends StatelessWidget {
  const CulinexAppearanceToggle({
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.lightLabel,
    required this.darkLabel,
    super.key,
    this.buttonKey,
    this.width = 156,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final String lightLabel;
  final String darkLabel;
  final Key? buttonKey;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      button: true,
      value: isDarkMode ? darkLabel : lightLabel,
      child: CulinexSegmentedToggle(
        leftLabel: lightLabel,
        rightLabel: darkLabel,
        rightSelected: isDarkMode,
        width: width,
        tooltip: isDarkMode ? l10n.switchToLightMode : l10n.switchToDarkMode,
        buttonKey: buttonKey,
        onPressed: onToggleTheme,
      ),
    );
  }
}

class CulinexSegmentedToggle extends StatelessWidget {
  const CulinexSegmentedToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.rightSelected,
    required this.onPressed,
    required this.width,
    super.key,
    this.tooltip,
    this.buttonKey,
  });

  final String leftLabel;
  final String rightLabel;
  final bool rightSelected;
  final VoidCallback onPressed;
  final double width;
  final String? tooltip;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);
    final Widget toggle = Material(
      color: Colors.transparent,
      child: InkWell(
        key: buttonKey,
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Ink(
          width: width,
          height: 48,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: rightSelected
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.elevatedSurface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          leftLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: rightSelected
                                    ? colors.mutedInk
                                    : colors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          rightLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: rightSelected
                                    ? colors.ink
                                    : colors.mutedInk,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) {
      return toggle;
    }

    return Tooltip(message: tooltip!, child: toggle);
  }
}
