import 'package:flutter/material.dart';

import '../theme/culinex_theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
    this.color,
    this.borderColor,
    this.borderWidth = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette palette = CulinexColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? palette.surface,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? palette.border,
          width: borderWidth,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
