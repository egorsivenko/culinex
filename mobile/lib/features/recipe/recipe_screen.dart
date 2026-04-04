import 'package:flutter/material.dart';

import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/primary_action_button.dart';
import '../session/culinex_models.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({
    required this.recipe,
    required this.onBackToIngredients,
    required this.onCookAnother,
    super.key,
  });

  final GeneratedRecipe recipe;
  final VoidCallback onBackToIngredients;
  final VoidCallback onCookAnother;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late final List<bool> _checkedIngredients = List<bool>.filled(
    widget.recipe.ingredients.length,
    false,
  );

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final GeneratedRecipe recipe = widget.recipe;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RecipeHeader(
                recipe: recipe,
                onBackToIngredients: widget.onBackToIngredients,
                onCookAnother: widget.onCookAnother,
              ),
              const SizedBox(height: 20),
              Text('Quick metrics', style: textTheme.titleLarge),
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
                          label: 'Difficulty',
                          value: recipe.difficulty.label,
                          icon: Icons.restaurant_menu_rounded,
                        ),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: _MetricCard(
                          label: 'Cooking time',
                          value: '${recipe.cookingTimeMinutes} min',
                          icon: Icons.schedule_rounded,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _NutritionSummaryCard(
                          calories:
                              '${recipe.macros.caloriesKcal.round()} kcal',
                          protein: '${recipe.macros.proteinG.round()}g',
                          carbs: '${recipe.macros.carbsG.round()}g',
                          fat: '${recipe.macros.fatG.round()}g',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Ingredients', style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Check items off as you cook.', style: textTheme.bodyMedium),
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
              Text('Steps', style: textTheme.headlineMedium),
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
                            color: CulinexColors.elevatedSurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: textTheme.titleMedium?.copyWith(
                                color: CulinexColors.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            recipe.steps[index],
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
              const SizedBox(height: 24),
              PrimaryActionButton(
                label: 'Cook another',
                icon: Icons.camera_alt_rounded,
                onPressed: widget.onCookAnother,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeHeader extends StatelessWidget {
  const _RecipeHeader({
    required this.recipe,
    required this.onBackToIngredients,
    required this.onCookAnother,
  });

  final GeneratedRecipe recipe;
  final VoidCallback onBackToIngredients;
  final VoidCallback onCookAnother;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GlassPanel(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(34),
      color: CulinexColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: CulinexColors.ink,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Recipe ready',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _HeaderActionButton(
                tooltip: 'Back to ingredients',
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: onBackToIngredients,
              ),
              const SizedBox(width: 10),
              _HeaderActionButton(
                tooltip: 'Back to home',
                icon: Icons.home_rounded,
                onPressed: onCookAnother,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            recipe.dishName,
            style: textTheme.displaySmall?.copyWith(
              color: CulinexColors.ink,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            recipe.dishDescription,
            style: textTheme.bodyLarge?.copyWith(color: CulinexColors.mutedInk),
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
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CulinexColors.ink),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: CulinexColors.mutedInk),
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

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: CulinexColors.ink,
          ),
          const SizedBox(height: 12),
          Text(
            'Nutrition Summary',
            style: textTheme.labelMedium?.copyWith(
              color: CulinexColors.mutedInk,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: textTheme.bodyLarge?.copyWith(
                color: CulinexColors.mutedInk,
              ),
              children: [
                TextSpan(
                  text: calories,
                  style: textTheme.titleMedium?.copyWith(
                    color: CulinexColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _NutritionDetail(label: 'Protein', value: protein),
              _NutritionDetail(label: 'Carbs', value: carbs),
              _NutritionDetail(label: 'Fat', value: fat),
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

    return Text.rich(
      TextSpan(
        style: textTheme.bodyLarge?.copyWith(color: CulinexColors.mutedInk),
        children: [
          TextSpan(
            text: value,
            style: textTheme.titleMedium?.copyWith(
              color: CulinexColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: ' $label',
            style: textTheme.bodyLarge?.copyWith(
              color: CulinexColors.mutedInk,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: CulinexColors.elevatedSurface,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: CulinexColors.ink),
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
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: CulinexColors.accent,
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
