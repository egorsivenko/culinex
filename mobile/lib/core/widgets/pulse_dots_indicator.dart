import 'dart:math' as math;

import 'package:flutter/material.dart';

class PulseDotsIndicator extends StatefulWidget {
  const PulseDotsIndicator({
    super.key,
    this.color = Colors.white,
    this.size = 12,
  });

  final Color color;
  final double size;

  @override
  State<PulseDotsIndicator> createState() => _PulseDotsIndicatorState();
}

class _PulseDotsIndicatorState extends State<PulseDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (index) {
            final double wave = math.sin(
              (_controller.value * 2 * math.pi) - (index * 0.8),
            );
            final double normalized = (wave + 1) / 2;
            final double scale = 0.85 + (normalized * 0.4);
            final double opacity = 0.35 + (normalized * 0.65);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(dimension: widget.size),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
