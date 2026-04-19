import 'package:flutter/material.dart';

import '../../core/localization/app_locale.dart';
import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../l10n/l10n.dart';
import '../home/culinex_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.locale,
    required this.onSelectLocale,
    required this.onSignOut,
    super.key,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Locale locale;
  final ValueChanged<Locale> onSelectLocale;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CulinexBrandHeader(),
            const SizedBox(height: 28),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: GlassPanel(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.settingsTitle,
                            style: textTheme.headlineMedium?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          _SettingsRow(
                            label: l10n.settingsLanguageLabel,
                            control: _SettingsLanguageDropdown(
                              locale: locale,
                              onSelectLocale: onSelectLocale,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SettingsRow(
                            label: l10n.settingsAppearanceLabel,
                            control: CulinexAppearanceToggle(
                              isDarkMode: isDarkMode,
                              onToggleTheme: onToggleTheme,
                              lightLabel: l10n.settingsLightOption,
                              darkLabel: l10n.settingsDarkOption,
                              buttonKey: const ValueKey<String>(
                                'settings-theme-toggle-button',
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Divider(color: colors.border, height: 1),
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            key: const ValueKey<String>(
                              'settings-sign-out-button',
                            ),
                            onPressed: onSignOut,
                            icon: const Icon(Icons.logout_rounded),
                            label: Text(l10n.signOut),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onError,
                              minimumSize: const Size(172, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.control});

  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 20),
        control,
      ],
    );
  }
}

class _SettingsLanguageDropdown extends StatelessWidget {
  const _SettingsLanguageDropdown({
    required this.locale,
    required this.onSelectLocale,
  });

  final Locale locale;
  final ValueChanged<Locale> onSelectLocale;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);
    final Locale selectedLocale = AppLocale.normalize(locale);

    return SizedBox(
      width: 156,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              key: const ValueKey<String>('settings-language-toggle-button'),
              value: selectedLocale,
              isExpanded: true,
              borderRadius: BorderRadius.circular(20),
              dropdownColor: colors.surface,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w700,
              ),
              items: const <DropdownMenuItem<Locale>>[
                DropdownMenuItem<Locale>(
                  value: AppLocale.english,
                  child: Text('English'),
                ),
                DropdownMenuItem<Locale>(
                  value: AppLocale.ukrainian,
                  child: Text('Українська'),
                ),
              ],
              onChanged: (Locale? nextLocale) {
                if (nextLocale == null || nextLocale == selectedLocale) {
                  return;
                }
                onSelectLocale(nextLocale);
              },
            ),
          ),
        ),
      ),
    );
  }
}
