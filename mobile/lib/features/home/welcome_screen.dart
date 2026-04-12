import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/localization/app_locale.dart';
import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../l10n/l10n.dart';

const int _culinexWelcomePhraseCount = 11;

final Random _culinexWelcomePhraseRandom = Random();
int _lastCulinexWelcomePhraseIndex = -1;

int _nextWelcomePhraseIndex() {
  final bool hasValidPreviousIndex =
      _lastCulinexWelcomePhraseIndex >= 0 &&
      _lastCulinexWelcomePhraseIndex < _culinexWelcomePhraseCount;

  final int nextIndex;
  if (!hasValidPreviousIndex) {
    nextIndex = _culinexWelcomePhraseRandom.nextInt(_culinexWelcomePhraseCount);
  } else {
    final int rawIndex = _culinexWelcomePhraseRandom.nextInt(
      _culinexWelcomePhraseCount - 1,
    );
    nextIndex = rawIndex >= _lastCulinexWelcomePhraseIndex
        ? rawIndex + 1
        : rawIndex;
  }

  _lastCulinexWelcomePhraseIndex = nextIndex;
  return nextIndex;
}

List<String> localizedCulinexWelcomePhrases(BuildContext context) {
  final l10n = context.l10n;
  return <String>[
    l10n.welcomePhrase1,
    l10n.welcomePhrase2,
    l10n.welcomePhrase3,
    l10n.welcomePhrase4,
    l10n.welcomePhrase5,
    l10n.welcomePhrase6,
    l10n.welcomePhrase7,
    l10n.welcomePhrase8,
    l10n.welcomePhrase9,
    l10n.welcomePhrase10,
    l10n.welcomePhrase11,
  ];
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    required this.onStart,
    required this.onStartManualEntry,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.locale,
    required this.onSelectLocale,
    super.key,
  });

  final VoidCallback onStart;
  final VoidCallback onStartManualEntry;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Locale locale;
  final ValueChanged<Locale> onSelectLocale;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final int _heroPhraseIndex = _nextWelcomePhraseIndex();

  @override
  Widget build(BuildContext context) {
    final List<String> welcomePhrases = localizedCulinexWelcomePhrases(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeHeader(
                isDarkMode: widget.isDarkMode,
                onToggleTheme: widget.onToggleTheme,
                locale: widget.locale,
                onSelectLocale: widget.onSelectLocale,
              ),
              const SizedBox(height: 28),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool isWideLayout =
                        constraints.maxWidth >= 720 ||
                        constraints.maxWidth > constraints.maxHeight;

                    return Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: isWideLayout ? 760 : 392,
                          child: _WelcomeChoiceLayout(
                            isWideLayout: isWideLayout,
                            heroPhrase: welcomePhrases[_heroPhraseIndex],
                            onStart: widget.onStart,
                            onStartManualEntry: widget.onStartManualEntry,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.locale,
    required this.onSelectLocale,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Locale locale;
  final ValueChanged<Locale> onSelectLocale;

  @override
  Widget build(BuildContext context) {
    return Row(
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

class _WelcomeChoiceLayout extends StatelessWidget {
  const _WelcomeChoiceLayout({
    required this.isWideLayout,
    required this.heroPhrase,
    required this.onStart,
    required this.onStartManualEntry,
  });

  final bool isWideLayout;
  final String heroPhrase;
  final VoidCallback onStart;
  final VoidCallback onStartManualEntry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;
    final Widget photoCard = _RecipeModeCard(
      title: l10n.takePhotoTitle,
      description: l10n.takePhotoDescription,
      button: PrimaryActionButton(
        label: l10n.useCamera,
        icon: Icons.camera_alt_rounded,
        onPressed: onStart,
      ),
    );
    final Widget manualCard = _RecipeModeCard(
      title: l10n.enterIngredientsManuallyTitle,
      description: l10n.enterIngredientsManuallyDescription,
      button: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onStartManualEntry,
          icon: const Icon(Icons.edit_note_rounded),
          label: Text(l10n.typeIngredients),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            heroPhrase,
            style: textTheme.displayMedium?.copyWith(fontSize: 36),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              l10n.welcomeDescription,
              style: textTheme.bodyLarge?.copyWith(color: colors.mutedInk),
            ),
          ),
        ),
        const SizedBox(height: 26),
        if (isWideLayout)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: photoCard),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(width: 132, child: _ChoiceSeparator()),
              ),
              Expanded(child: manualCard),
            ],
          )
        else
          Column(
            children: [
              photoCard,
              const SizedBox(height: 12),
              const SizedBox(width: double.infinity, child: _ChoiceSeparator()),
              const SizedBox(height: 12),
              manualCard,
            ],
          ),
      ],
    );
  }
}

class _ChoiceSeparator extends StatelessWidget {
  const _ChoiceSeparator();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.border),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          l10n.choiceSeparatorOr,
          style: textTheme.titleMedium?.copyWith(
            color: colors.subtleInk,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipeModeCard extends StatelessWidget {
  const _RecipeModeCard({
    required this.title,
    required this.description,
    required this.button,
  });

  final String title;
  final String description;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 240),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.mutedInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              button,
            ],
          ),
        ),
      ),
    );
  }
}
