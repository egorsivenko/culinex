import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/feedback/app_haptics.dart';
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
    required this.selectedRecipeActionId,
    required this.deletingRecipeId,
    required this.favoritingRecipeId,
    required this.onRetry,
    required this.onOpenRecipe,
    required this.onSelectRecipeActions,
    required this.onClearRecipeActions,
    required this.onSetRecipeFavorite,
    required this.onDeleteRecipe,
    super.key,
  });

  final RecipeHistoryStatus status;
  final List<RecipeSummary> recipes;
  final bool isOpeningRecipe;
  final String? selectedRecipeActionId;
  final String? deletingRecipeId;
  final String? favoritingRecipeId;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenRecipe;
  final ValueChanged<String> onSelectRecipeActions;
  final VoidCallback onClearRecipeActions;
  final Future<bool> Function(String id, bool isFavorite) onSetRecipeFavorite;
  final Future<bool> Function(String id) onDeleteRecipe;

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
          onPressed: () {
            AppHaptics.tap();
            onRetry();
          },
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

    final int selectedRecipeIndex = recipes.indexWhere(
      (recipe) => recipe.id == selectedRecipeActionId,
    );
    final RecipeSummary? selectedRecipe = selectedRecipeIndex == -1
        ? null
        : recipes[selectedRecipeIndex];
    final LayerLink? selectedRecipeLayerLink = selectedRecipe == null
        ? null
        : LayerLink();

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClearRecipeActions,
            child: ListView.separated(
              itemCount: recipes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final RecipeSummary recipe = recipes[index];
                final bool isSelected = selectedRecipeActionId == recipe.id;
                return _RecipeActionItem(
                  recipe: recipe,
                  isSelected: isSelected,
                  actionLayerLink: isSelected ? selectedRecipeLayerLink : null,
                  enabled:
                      !isOpeningRecipe &&
                      deletingRecipeId == null &&
                      favoritingRecipeId == null,
                  onTap: () {
                    AppHaptics.tap();
                    onOpenRecipe(recipe.id);
                  },
                  onLongPress: () {
                    AppHaptics.selection();
                    onSelectRecipeActions(recipe.id);
                  },
                );
              },
            ),
          ),
        ),
        if (selectedRecipe != null && selectedRecipeLayerLink != null)
          Positioned.fill(
            child: CompositedTransformFollower(
              link: selectedRecipeLayerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
              offset: const Offset(0, 8),
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 1,
                widthFactor: 1,
                child: UnconstrainedBox(
                  alignment: Alignment.topCenter,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<String>(selectedRecipe.id),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      final double easedValue = Curves.easeOutBack.transform(
                        value,
                      );
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 6 * (1 - value)),
                          child: Transform.scale(
                            scale: 0.96 + (0.04 * easedValue),
                            alignment: Alignment.topCenter,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _RecipeActionBox(
                      isFavorite: selectedRecipe.isFavorite,
                      isFavoriting: favoritingRecipeId == selectedRecipe.id,
                      isDeleting: deletingRecipeId == selectedRecipe.id,
                      onSetFavorite: () => _setRecipeFavorite(
                        context,
                        selectedRecipe.id,
                        !selectedRecipe.isFavorite,
                      ),
                      onDelete: () =>
                          _confirmAndDeleteRecipe(context, selectedRecipe),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmAndDeleteRecipe(
    BuildContext context,
    RecipeSummary recipe,
  ) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return const _DeleteRecipeDialog();
      },
    );
    if (shouldDelete != true) {
      return;
    }

    AppHaptics.destructive();

    final bool deleted = await onDeleteRecipe(recipe.id);
    if (!context.mounted || deleted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.deleteRecipeFailed)));
  }

  Future<void> _setRecipeFavorite(
    BuildContext context,
    String id,
    bool isFavorite,
  ) async {
    AppHaptics.commit();

    final bool updated = await onSetRecipeFavorite(id, isFavorite);
    if (!context.mounted || updated) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.favoriteRecipeFailed)),
      );
  }
}

class _RecipeActionItem extends StatelessWidget {
  const _RecipeActionItem({
    required this.recipe,
    required this.isSelected,
    required this.actionLayerLink,
    required this.enabled,
    required this.onTap,
    required this.onLongPress,
  });

  final RecipeSummary recipe;
  final bool isSelected;
  final LayerLink? actionLayerLink;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return _RecipeHistoryRow(
      recipe: recipe,
      enabled: enabled,
      isSelected: isSelected,
      actionLayerLink: actionLayerLink,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class _RecipeHistoryRow extends StatelessWidget {
  const _RecipeHistoryRow({
    required this.recipe,
    required this.enabled,
    required this.isSelected,
    required this.actionLayerLink,
    required this.onTap,
    required this.onLongPress,
  });

  final RecipeSummary recipe;
  final bool enabled;
  final bool isSelected;
  final LayerLink? actionLayerLink;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: isSelected ? 1 : 0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        Widget elevatedChild = Material(
          color: Colors.transparent,
          elevation: 11 * value,
          shadowColor: colors.shadow,
          borderRadius: BorderRadius.circular(24),
          child: child,
        );
        final LayerLink? link = actionLayerLink;
        if (link != null) {
          elevatedChild = CompositedTransformTarget(
            link: link,
            child: elevatedChild,
          );
        }

        return Transform.translate(
          offset: Offset(0, -7 * value),
          child: elevatedChild,
        );
      },
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : colors.border,
            ),
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
                    if (recipe.isFavorite) ...[
                      Icon(
                        Icons.favorite_rounded,
                        key: ValueKey<String>(
                          'recipe-favorite-indicator-${recipe.id}',
                        ),
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 6),
                    ],
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

class _RecipeActionBox extends StatelessWidget {
  const _RecipeActionBox({
    required this.isFavorite,
    required this.isFavoriting,
    required this.isDeleting,
    required this.onSetFavorite,
    required this.onDelete,
  });

  final bool isFavorite;
  final bool isFavoriting;
  final bool isDeleting;
  final VoidCallback onSetFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final String favoriteLabel = isFavorite
        ? l10n.unfavoriteRecipe
        : l10n.favoriteRecipe;
    final String deleteLabel = l10n.deleteRecipe;
    final double contentWidth = _calculateActionContentWidth(context, <String>[
      favoriteLabel,
      deleteLabel,
    ]);

    return Container(
      key: const ValueKey<String>('recipe-action-box'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.elevatedSurface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: contentWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RecipeActionButton(
              key: const ValueKey<String>('recipe-favorite-button'),
              onPressed: isFavoriting || isDeleting ? null : onSetFavorite,
              icon: isFavoriting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
              label: favoriteLabel,
            ),
            _RecipeActionButton(
              key: const ValueKey<String>('recipe-delete-button'),
              onPressed: isDeleting || isFavoriting ? null : onDelete,
              icon: isDeleting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.error,
                      ),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: deleteLabel,
              foregroundColor: colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateActionContentWidth(
    BuildContext context,
    List<String> labels,
  ) {
    final TextStyle textStyle =
        Theme.of(context).textButtonTheme.style?.textStyle?.resolve({}) ??
        Theme.of(context).textTheme.labelLarge ??
        const TextStyle(fontSize: 14);
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final TextDirection textDirection = Directionality.of(context);
    double longestLabelWidth = 0;

    for (final String label in labels) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        maxLines: 1,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      longestLabelWidth = math.max(longestLabelWidth, painter.width);
    }

    final double preferredWidth =
        _RecipeActionButton.horizontalPadding +
        _RecipeActionButton.iconSlotWidth +
        _RecipeActionButton.iconGap +
        longestLabelWidth;
    final double maxWidth = math.max(
      _RecipeActionButton.minWidth,
      MediaQuery.sizeOf(context).width - 96,
    );

    return preferredWidth.clamp(_RecipeActionButton.minWidth, maxWidth);
  }
}

class _RecipeActionButton extends StatelessWidget {
  const _RecipeActionButton({
    required super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color? foregroundColor;

  static const double minWidth = 180;
  static const double horizontalPadding = 36;
  static const double iconSlotWidth = 22;
  static const double iconGap = 10;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        minimumSize: const Size(minWidth, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: iconSlotWidth,
            child: Center(child: icon),
          ),
          const SizedBox(width: iconGap),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(label, softWrap: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteRecipeDialog extends StatelessWidget {
  const _DeleteRecipeDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 520),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      title: Row(
        children: <Widget>[
          Expanded(child: Text(l10n.deleteRecipeDialogTitle)),
          IconButton(
            key: const ValueKey<String>('delete-recipe-close-button'),
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
      content: Text(l10n.deleteRecipeDialogMessage),
      actions: <Widget>[
        FilledButton(
          key: const ValueKey<String>('delete-recipe-confirm-button'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: Text(l10n.deleteRecipeDialogConfirm),
        ),
      ],
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
