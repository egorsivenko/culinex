import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../l10n/l10n.dart';
import '../session/culinex_models.dart';
import '../session/session_localizations.dart';

typedef CookingModeWakeLockSetter = Future<void> Function(bool enable);

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({
    required this.recipe,
    required this.backTooltip,
    required this.onBack,
    required this.onCookAnother,
    super.key,
    this.cookingModeWakeLockSetter,
  });

  final GeneratedRecipe recipe;
  final String backTooltip;
  final VoidCallback onBack;
  final VoidCallback onCookAnother;
  final CookingModeWakeLockSetter? cookingModeWakeLockSetter;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late final List<bool> _checkedIngredients = List<bool>.filled(
    widget.recipe.ingredients.length,
    false,
  );
  late final PageController _cookingPageController = PageController();
  bool _isCookingMode = false;
  int _currentCookingStep = 0;

  @override
  void dispose() {
    if (_isCookingMode) {
      _setCookingModeWakeLock(false);
    }
    _cookingPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isCookingMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isCookingMode) {
          _exitCookingMode();
        }
      },
      child: _isCookingMode
          ? _buildCookingMode(context)
          : _buildRecipe(context),
    );
  }

  Widget _buildRecipe(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);
    final GeneratedRecipe recipe = widget.recipe;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RecipeHeader(
                recipe: recipe,
                backTooltip: widget.backTooltip,
                onBack: widget.onBack,
                onCookAnother: widget.onCookAnother,
              ),
              const SizedBox(height: 20),
              Text(l10n.quickMetrics, style: textTheme.titleLarge),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const double spacing = 12;
                  final double halfWidth = (constraints.maxWidth - spacing) / 2;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: halfWidth,
                        child: _MetricCard(
                          label: l10n.difficultyLabel,
                          value: recipe.difficulty.label(l10n),
                          icon: Icons.restaurant_menu_rounded,
                        ),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: _MetricCard(
                          label: l10n.cookingTimeLabel,
                          value: l10n.cookingTimeValue(
                            recipe.cookingTimeMinutes,
                          ),
                          icon: Icons.schedule_rounded,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _NutritionSummaryCard(
                          calories: l10n.nutritionCaloriesValue(
                            recipe.macros.caloriesKcal.round(),
                          ),
                          protein: l10n.nutritionMacroValue(
                            recipe.macros.proteinG.round(),
                          ),
                          carbs: l10n.nutritionMacroValue(
                            recipe.macros.carbsG.round(),
                          ),
                          fat: l10n.nutritionMacroValue(
                            recipe.macros.fatG.round(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(l10n.ingredientsHeading, style: textTheme.headlineMedium),
              const SizedBox(height: 12),
              GlassPanel(
                child: Column(
                  children: [
                    for (
                      int index = 0;
                      index < recipe.ingredients.length;
                      index++
                    )
                      _IngredientCheckboxTile(
                        ingredient: recipe.ingredients[index],
                        value: _checkedIngredients[index],
                        onChanged: (value) {
                          setState(() {
                            _checkedIngredients[index] = value ?? false;
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(l10n.stepsHeading, style: textTheme.headlineMedium),
              const SizedBox(height: 12),
              ...List<Widget>.generate(recipe.steps.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == recipe.steps.length - 1 ? 0 : 12,
                  ),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(18),
                    borderRadius: BorderRadius.circular(28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: colors.elevatedSurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: textTheme.titleMedium?.copyWith(
                                color: colors.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            recipe.steps[index],
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              PrimaryActionButton(
                label: l10n.startCooking,
                icon: Icons.restaurant_rounded,
                onPressed: recipe.steps.isEmpty ? null : _startCookingMode,
              ),
              const SizedBox(height: 12),
              PrimaryActionButton(
                label: l10n.cookAnother,
                icon: Icons.camera_alt_rounded,
                onPressed: widget.onCookAnother,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCookingMode(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;
    final List<String> steps = widget.recipe.steps;
    final int stepCount = steps.length;
    final int displayStep = _currentCookingStep + 1;
    final bool isFirstStep = _currentCookingStep == 0;
    final bool isLastStep = _currentCookingStep == stepCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: stepCount == 0 ? 0 : displayStep / stepCount,
              minHeight: 6,
              backgroundColor: colors.elevatedSurface,
              color: isLastStep ? CulinexColors.confidenceHigh : colors.accent,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.cookingModeStepProgress(
                              displayStep,
                              stepCount,
                            ),
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.mutedInk,
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.elevatedSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.border),
                          ),
                          child: IconButton(
                            tooltip: l10n.closeCookingModeTooltip,
                            onPressed: _exitCookingMode,
                            icon: Icon(Icons.close_rounded, color: colors.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: PageView.builder(
                        controller: _cookingPageController,
                        itemCount: stepCount,
                        onPageChanged: (index) {
                          setState(() {
                            _currentCookingStep = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return _CookingStepPage(
                            controller: _cookingPageController,
                            pageIndex: index,
                            child: _CookingStepCard(
                              stepNumber: index + 1,
                              stepText: steps[index],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isFirstStep ? null : _goToPreviousStep,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(l10n.cookingModeBack),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _goToNextStepOrFinish,
                            icon: Icon(
                              isLastStep
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                            label: Text(
                              isLastStep
                                  ? l10n.cookingModeFinish
                                  : l10n.cookingModeNext,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCookingMode() {
    if (widget.recipe.steps.isEmpty) {
      return;
    }

    setState(() {
      _isCookingMode = true;
      _currentCookingStep = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isCookingMode && _cookingPageController.hasClients) {
        _cookingPageController.jumpToPage(0);
      }
    });
    _setCookingModeWakeLock(true);
  }

  void _exitCookingMode() {
    if (!_isCookingMode) {
      return;
    }

    setState(() {
      _isCookingMode = false;
    });
    _setCookingModeWakeLock(false);
  }

  void _goToPreviousStep() {
    if (_currentCookingStep == 0) {
      return;
    }

    _goToCookingStep(_currentCookingStep - 1);
  }

  void _goToNextStepOrFinish() {
    if (_currentCookingStep == widget.recipe.steps.length - 1) {
      _exitCookingMode();
      return;
    }

    _goToCookingStep(_currentCookingStep + 1);
  }

  void _goToCookingStep(int index) {
    _cookingPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _setCookingModeWakeLock(bool enable) {
    unawaited(_applyCookingModeWakeLock(enable));
  }

  Future<void> _applyCookingModeWakeLock(bool enable) async {
    try {
      final CookingModeWakeLockSetter? setter =
          widget.cookingModeWakeLockSetter;
      if (setter != null) {
        await setter(enable);
        return;
      }

      await WakelockPlus.toggle(enable: enable);
    } on Object catch (error) {
      debugPrint('Cooking mode wake lock update failed: $error');
    }
  }
}

class _CookingStepPage extends StatelessWidget {
  const _CookingStepPage({
    required this.controller,
    required this.pageIndex,
    required this.child,
  });

  final PageController controller;
  final int pageIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final double currentPage =
            controller.hasClients && controller.position.haveDimensions
            ? controller.page ?? controller.initialPage.toDouble()
            : controller.initialPage.toDouble();
        final double distance = (currentPage - pageIndex).clamp(-1.0, 1.0);
        final double lean = distance * -0.025;
        final double scale = 1 - distance.abs() * 0.025;

        return ClipRect(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Transform.rotate(
              angle: lean,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
    );
  }
}

class _CookingStepCard extends StatelessWidget {
  const _CookingStepCard({required this.stepNumber, required this.stepText});

  final int stepNumber;
  final String stepText;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);

    return GlassPanel(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: colors.elevatedSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: textTheme.titleLarge?.copyWith(color: colors.ink),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                stepText,
                style: textTheme.headlineMedium?.copyWith(
                  color: colors.ink,
                  height: 1.22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeHeader extends StatelessWidget {
  const _RecipeHeader({
    required this.recipe,
    required this.backTooltip,
    required this.onBack,
    required this.onCookAnother,
  });

  final GeneratedRecipe recipe;
  final String backTooltip;
  final VoidCallback onBack;
  final VoidCallback onCookAnother;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;

    return GlassPanel(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(34),
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    l10n.recipeReadyBadge,
                    style: TextStyle(
                      color: colors.onAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _HeaderActionButton(
                tooltip: backTooltip,
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: onBack,
              ),
              const SizedBox(width: 10),
              _HeaderActionButton(
                tooltip: l10n.backToHomeTooltip,
                icon: Icons.home_rounded,
                onPressed: onCookAnother,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            recipe.dishName,
            style: textTheme.displaySmall?.copyWith(
              color: colors.ink,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            recipe.dishDescription,
            style: textTheme.bodyLarge?.copyWith(color: colors.mutedInk),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.ink),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.mutedInk),
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _NutritionSummaryCard extends StatelessWidget {
  const _NutritionSummaryCard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String calories;
  final String protein;
  final String carbs;
  final String fat;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_fire_department_rounded, color: colors.ink),
          const SizedBox(height: 12),
          Text(
            l10n.nutritionSummary,
            style: textTheme.labelMedium?.copyWith(color: colors.mutedInk),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: textTheme.bodyLarge?.copyWith(color: colors.mutedInk),
              children: [
                TextSpan(
                  text: calories,
                  style: textTheme.titleMedium?.copyWith(color: colors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _NutritionDetail(label: l10n.proteinLabel, value: protein),
              _NutritionDetail(label: l10n.carbsLabel, value: carbs),
              _NutritionDetail(label: l10n.fatLabel, value: fat),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionDetail extends StatelessWidget {
  const _NutritionDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);

    return Text.rich(
      TextSpan(
        style: textTheme.bodyLarge?.copyWith(color: colors.mutedInk),
        children: [
          TextSpan(
            text: value,
            style: textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: ' $label',
            style: textTheme.bodyLarge?.copyWith(
              color: colors.mutedInk,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: colors.ink),
      ),
    );
  }
}

class _IngredientCheckboxTile extends StatelessWidget {
  const _IngredientCheckboxTile({
    required this.ingredient,
    required this.value,
    required this.onChanged,
  });

  final RecipeIngredient ingredient;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);

    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: colors.accent,
      contentPadding: EdgeInsets.zero,
      title: Text(
        _formatIngredientName(ingredient.name),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        ingredient.quantity,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

String _formatIngredientName(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}
