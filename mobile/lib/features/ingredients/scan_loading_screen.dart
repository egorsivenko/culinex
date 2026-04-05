import 'package:flutter/material.dart';

import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/photo_backdrop.dart';
import '../../core/widgets/pulse_dots_indicator.dart';

class ScanLoadingScreen extends StatelessWidget {
  const ScanLoadingScreen({required this.imagePath, super.key});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);

    return Scaffold(
      body: PhotoBackdrop(
        imagePath: imagePath,
        overlayColor: Colors.black.withValues(alpha: 0.56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GlassPanel(
                  color: colors.surface,
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
                          color: colors.elevatedSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Scanning ingredients',
                          style: textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 22),
                      PulseDotsIndicator(color: colors.ink, size: 14),
                      const SizedBox(height: 22),
                      Text(
                        'Recognizing ingredients...',
                        style: textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The app is checking what is visible in the photo and estimating the product quantities before recipe creation.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.mutedInk,
                        ),
                      ),
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
