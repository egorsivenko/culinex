import 'package:flutter/material.dart';

import '../../core/localization/app_locale.dart';
import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../l10n/l10n.dart';
import '../auth/auth_controller.dart';
import '../home/culinex_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.locale,
    required this.onSelectLocale,
    required this.onSignOut,
    required this.onDeleteAccount,
    required this.isSubmitting,
    required this.errorCode,
    required this.onClearError,
    super.key,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Locale locale;
  final ValueChanged<Locale> onSelectLocale;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onDeleteAccount;
  final bool isSubmitting;
  final AuthErrorCode? errorCode;
  final VoidCallback onClearError;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
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
                          if (errorCode != null) ...<Widget>[
                            const SizedBox(height: 24),
                            _SettingsErrorBanner(
                              message: _errorMessageFor(context, errorCode!),
                              onDismiss: onClearError,
                            ),
                          ],
                          const SizedBox(height: 28),
                          Divider(color: colors.border, height: 1),
                          const SizedBox(height: 22),
                          OutlinedButton.icon(
                            key: const ValueKey<String>(
                              'settings-sign-out-button',
                            ),
                            onPressed: isSubmitting ? null : onSignOut,
                            icon: const Icon(Icons.logout_rounded),
                            label: Text(l10n.signOut),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.ink,
                              side: BorderSide(color: colors.border),
                              minimumSize: const Size(172, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            key: const ValueKey<String>(
                              'settings-delete-account-button',
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () => _confirmDeleteAccount(context),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text(l10n.deleteAccount),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error),
                              minimumSize: const Size(188, 48),
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

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    onClearError();
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return const _DeleteAccountDialog();
      },
    );
    if (shouldDelete != true) {
      return;
    }

    await onDeleteAccount();
  }

  String _errorMessageFor(BuildContext context, AuthErrorCode code) {
    final l10n = context.l10n;

    return switch (code) {
      AuthErrorCode.validationFailed => l10n.authErrorValidationFailed,
      AuthErrorCode.emailAlreadyInUse => l10n.authErrorEmailAlreadyInUse,
      AuthErrorCode.invalidCredentials => l10n.authErrorInvalidCredentials,
      AuthErrorCode.sessionExpired => l10n.authErrorSessionExpired,
      AuthErrorCode.requestTimedOut => l10n.authErrorRequestTimedOut,
      AuthErrorCode.networkUnavailable => l10n.authErrorNetworkUnavailable,
      AuthErrorCode.serverFailure => l10n.authErrorServerFailure,
      AuthErrorCode.unexpectedResponse => l10n.authErrorUnexpectedResponse,
    };
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

class _SettingsErrorBanner extends StatelessWidget {
  const _SettingsErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: colorScheme.onErrorContainer),
              tooltip: l10n.authDismissError,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const String _confirmationValue = 'DELETE';

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final CulinexPalette colors = CulinexColors.of(context);
    final bool canConfirm = _controller.text.trim() == _confirmationValue;

    return AlertDialog(
      alignment: const Alignment(0, 0.40),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 520),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      title: Row(
        children: <Widget>[
          Expanded(child: Text(l10n.deleteAccountDialogTitle)),
          IconButton(
            key: const ValueKey<String>('delete-account-close-button'),
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.deleteAccountDialogMessage),
          const SizedBox(height: 20),
          Text(
            l10n.deleteAccountDialogInstruction,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey<String>('delete-account-confirmation-input'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: _confirmationValue),
            onChanged: (_) {
              setState(() {});
            },
          ),
        ],
      ),
      actions: <Widget>[
        FilledButton(
          key: const ValueKey<String>('delete-account-confirm-button'),
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: Text(l10n.deleteAccountDialogConfirm),
        ),
      ],
    );
  }
}
