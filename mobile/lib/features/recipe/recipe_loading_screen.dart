import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/photo_backdrop.dart';
import '../../core/widgets/pulse_dots_indicator.dart';

class RecipeLoadingScreen extends StatefulWidget {
  const RecipeLoadingScreen({required this.imagePath, super.key});

  final String? imagePath;

  @override
  State<RecipeLoadingScreen> createState() => _RecipeLoadingScreenState();
}

class _RecipeLoadingScreenState extends State<RecipeLoadingScreen> {
  static const List<String> _milestones = <String>[
    'Analyzing products',
    'Selecting flavor combinations',
    'Calculating cooking time',
    'Estimating calories',
  ];

  Timer? _timer;
  int _visibleMilestones = 0;

  @override
  void initState() {
    super.initState();
    _visibleMilestones = 1;
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted) {
        return;
      }

      if (_visibleMilestones >= _milestones.length) {
        timer.cancel();
        return;
      }

      setState(() {
        _visibleMilestones += 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: PhotoBackdrop(
        imagePath: widget.imagePath,
        blurSigma: 22,
        overlayColor: Colors.black.withValues(alpha: 0.66),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GlassPanel(
                  color: CulinexColors.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CulinexColors.elevatedSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'AI is cooking',
                          style: textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const PulseDotsIndicator(
                        color: CulinexColors.ink,
                        size: 14,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Creating a recipe based on your ingredients...',
                        style: textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'This can take a few moments while the assistant builds a balanced single-serving dish.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: CulinexColors.mutedInk,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ...List<Widget>.generate(_milestones.length, (index) {
                        final bool isVisible = index < _visibleMilestones;
                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 350),
                          opacity: isVisible ? 1 : 0,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  height: 28,
                                  width: 28,
                                  decoration: BoxDecoration(
                                    color: CulinexColors.ink,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _milestones[index],
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: CulinexColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
