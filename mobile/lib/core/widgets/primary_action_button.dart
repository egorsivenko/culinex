import 'package:flutter/material.dart';

import '../feedback/app_haptics.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = onPressed == null
        ? null
        : () {
            AppHaptics.tap();
            onPressed!();
          };

    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? FilledButton(onPressed: effectiveOnPressed, child: Text(label))
          : FilledButton.icon(
              onPressed: effectiveOnPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}
