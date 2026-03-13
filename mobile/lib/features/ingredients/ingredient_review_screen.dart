import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/primary_action_button.dart';
import '../session/culinex_models.dart';

class IngredientReviewScreen extends StatefulWidget {
  const IngredientReviewScreen({
    required this.imagePath,
    required this.ingredients,
    required this.onBack,
    required this.onProceed,
    this.onOpenRecipe,
    super.key,
  });

  final String? imagePath;
  final List<ExtractedIngredient> ingredients;
  final VoidCallback onBack;
  final Future<void> Function() onProceed;
  final VoidCallback? onOpenRecipe;

  @override
  State<IngredientReviewScreen> createState() => _IngredientReviewScreenState();
}

class _IngredientReviewScreenState extends State<IngredientReviewScreen> {
  bool _isPreviewVisible = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const Spacer(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: CulinexColors.elevatedSurface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: CulinexColors.border),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text('Scan complete'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Here is what I found', style: textTheme.headlineLarge),
                  const SizedBox(height: 10),
                  Text(
                    'Review the recognized products, then continue to recipe generation. Editing comes later; this first version uses the list as-is.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: CulinexColors.mutedInk,
                    ),
                  ),
                  if (widget.imagePath != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showPreview,
                        icon: const Icon(Icons.photo_outlined),
                        label: const Text('View original photo'),
                      ),
                    ),
                  ],
                  if (widget.onOpenRecipe != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.onOpenRecipe,
                        icon: const Icon(Icons.restaurant_menu_rounded),
                        label: const Text('Return to recipe'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: widget.ingredients.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ExtractedIngredient ingredient =
                            widget.ingredients[index];
                        return GlassPanel(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(26),
                          borderColor: _cardBorderColor(ingredient.confidence),
                          borderWidth: _cardBorderWidth(ingredient.confidence),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatIngredientName(ingredient.name),
                                style: textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _DetailChip(
                                    icon: Icons.inventory_2_outlined,
                                    label: ingredient.quantity,
                                    foregroundColor: CulinexColors.quantityBlue,
                                    backgroundColor: CulinexColors.quantityBlue
                                        .withValues(alpha: 0.10),
                                  ),
                                  _DetailChip(
                                    icon: Icons.auto_awesome_rounded,
                                    label: ingredient.confidence.label,
                                    foregroundColor: _confidenceColor(
                                      ingredient.confidence,
                                    ),
                                    backgroundColor: _confidenceColor(
                                      ingredient.confidence,
                                    ).withValues(alpha: 0.10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryActionButton(
                    label: 'Proceed',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () {
                      widget.onProceed();
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isPreviewVisible && widget.imagePath != null)
            _ImagePreviewOverlay(
              imagePath: widget.imagePath!,
              onClose: _hidePreview,
            ),
        ],
      ),
    );
  }

  void _showPreview() {
    setState(() {
      _isPreviewVisible = true;
    });
  }

  void _hidePreview() {
    setState(() {
      _isPreviewVisible = false;
    });
  }

  Color _confidenceColor(IngredientConfidence confidence) {
    return switch (confidence) {
      IngredientConfidence.high => CulinexColors.confidenceHigh,
      IngredientConfidence.medium => CulinexColors.confidenceMedium,
      IngredientConfidence.low => CulinexColors.confidenceLow,
    };
  }

  Color _cardBorderColor(IngredientConfidence confidence) {
    return switch (confidence) {
      IngredientConfidence.high => CulinexColors.border,
      IngredientConfidence.medium => CulinexColors.confidenceMedium.withValues(
        alpha: 0.55,
      ),
      IngredientConfidence.low => CulinexColors.confidenceLow.withValues(
        alpha: 0.60,
      ),
    };
  }

  double _cardBorderWidth(IngredientConfidence confidence) {
    return switch (confidence) {
      IngredientConfidence.high => 1,
      IngredientConfidence.medium => 1.4,
      IngredientConfidence.low => 1.6,
    };
  }

  String _formatIngredientName(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}

class _ImagePreviewOverlay extends StatelessWidget {
  const _ImagePreviewOverlay({required this.imagePath, required this.onClose});

  final String imagePath;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.82),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Expanded(
                  flex: 7,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.white,
                                size: 56,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                    ),
                    child: IconButton(
                      tooltip: 'Close preview',
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: CulinexColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    this.foregroundColor = CulinexColors.ink,
    this.backgroundColor = CulinexColors.elevatedSurface,
  });

  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foregroundColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: foregroundColor),
            ),
          ],
        ),
      ),
    );
  }
}
