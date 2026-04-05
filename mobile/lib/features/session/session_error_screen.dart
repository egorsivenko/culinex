import 'package:flutter/material.dart';

import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/primary_action_button.dart';

class SessionErrorScreen extends StatelessWidget {
  const SessionErrorScreen({
    required this.title,
    required this.message,
    required this.primaryActionLabel,
    required this.secondaryActionLabel,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
    super.key,
  });

  final String title;
  final String message;
  final String primaryActionLabel;
  final String secondaryActionLabel;
  final Future<void> Function() onPrimaryAction;
  final VoidCallback onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: GlassPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: colors.elevatedSurface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(title, style: textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text(message, style: textTheme.bodyLarge),
                    const SizedBox(height: 24),
                    PrimaryActionButton(
                      label: primaryActionLabel,
                      onPressed: () {
                        onPrimaryAction();
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSecondaryAction,
                        child: Text(secondaryActionLabel),
                      ),
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
