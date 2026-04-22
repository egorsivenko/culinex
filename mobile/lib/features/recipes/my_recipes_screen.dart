import 'package:flutter/material.dart';

import '../../core/theme/culinex_theme.dart';
import '../../l10n/l10n.dart';
import '../home/culinex_header.dart';
import '../session/culinex_models.dart';
import '../session/cook_session_controller.dart';
import '../session/session_localizations.dart';

class MyRecipesScreen extends StatelessWidget {
  const MyRecipesScreen({
    required this.status,
    required this.recipes,
    required this.isOpeningRecipe,
    required this.onRetry,
    required this.onOpenRecipe,
    super.key,
  });

  final RecipeHistoryStatus status;
  final List<RecipeSummary> recipes;
  final bool isOpeningRecipe;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Column(
        children: [
          if (isOpeningRecipe) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CulinexBrandHeader(),
                  const SizedBox(height: 28),
                  Text(
                    l10n.myRecipesTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 18),
                  Expanded(child: _buildBody(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;

    if (status == RecipeHistoryStatus.loading && recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == RecipeHistoryStatus.error && recipes.isEmpty) {
      return _CenteredState(
        icon: Icons.cloud_off_rounded,
        title: l10n.myRecipesLoadFailedTitle,
        message: l10n.myRecipesLoadFailedMessage,
        action: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.myRecipesRetry),
        ),
      );
    }

    if (recipes.isEmpty) {
      return _CenteredState(
        icon: Icons.menu_book_outlined,
        title: l10n.myRecipesEmptyTitle,
        message: l10n.myRecipesEmptyMessage,
      );
    }

    return ListView.separated(
      itemCount: recipes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final RecipeSummary recipe = recipes[index];
        return _RecipeHistoryRow(
          recipe: recipe,
          enabled: !isOpeningRecipe,
          onTap: () => onOpenRecipe(recipe.id),
        );
      },
    );
  }
}

class _RecipeHistoryRow extends StatelessWidget {
  const _RecipeHistoryRow({
    required this.recipe,
    required this.enabled,
    required this.onTap,
  });

  final RecipeSummary recipe;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(24),
            color: colors.surface.withValues(alpha: 0.72),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.dishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.dishDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 88, maxWidth: 116),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _RecipeMetric(
                      icon: Icons.restaurant_menu_rounded,
                      label: recipe.difficulty.label(l10n),
                    ),
                    const SizedBox(height: 8),
                    _RecipeMetric(
                      icon: Icons.schedule_rounded,
                      label: l10n.cookingTimeValue(recipe.cookingTimeMinutes),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeMetric extends StatelessWidget {
  const _RecipeMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.subtleInk),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: colors.subtleInk),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(color: colors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
