import 'package:flutter/material.dart';

import '../theme/culinex_theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
    this.color = CulinexColors.surface,
    this.borderColor = CulinexColors.border,
    this.borderWidth = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
