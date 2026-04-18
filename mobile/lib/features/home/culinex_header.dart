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
        const Expanded(child: _LogoLockup()),
        const SizedBox(width: 12),
        _LanguageToggle(locale: locale, onSelectLocale: onSelectLocale),
        const SizedBox(width: 12),
        _ThemeModeButton(isDarkMode: isDarkMode, onPressed: onToggleTheme),
      ],
    );
  }
}

class _LogoLockup extends StatelessWidget {
  const _LogoLockup();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Culinex',
                style: textTheme.displaySmall?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({required this.isDarkMode, required this.onPressed});

  final bool isDarkMode;
  final VoidCallback onPressed;

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
        key: const ValueKey<String>('theme-toggle-button'),
        tooltip: isDarkMode ? l10n.switchToLightMode : l10n.switchToDarkMode,
        onPressed: onPressed,
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

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.locale, required this.onSelectLocale});

  final Locale locale;
  final ValueChanged<Locale> onSelectLocale;

  @override
  Widget build(BuildContext context) {
    final bool isUkrainian = AppLocale.isUkrainian(locale);
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;

    return Semantics(
      button: true,
      value: isUkrainian
          ? l10n.languageUkrainianShort
          : l10n.languageEnglishShort,
      child: Tooltip(
        message: isUkrainian ? l10n.switchToEnglish : l10n.switchToUkrainian,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey<String>('language-toggle-button'),
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              onSelectLocale(
                isUkrainian ? AppLocale.english : AppLocale.ukrainian,
              );
            },
            child: Ink(
              width: 108,
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
                      alignment: isUkrainian
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
                              l10n.languageEnglishShort,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: isUkrainian
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
                              l10n.languageUkrainianShort,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: isUkrainian
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
        ),
      ),
    );
  }
}
