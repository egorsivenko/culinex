import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/feedback/app_haptics.dart';
import '../../core/feedback/app_sounds.dart';
import '../../core/theme/culinex_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../home/culinex_header.dart';
import '../session/culinex_models.dart';
import '../session/cook_session_controller.dart';
import '../session/session_localizations.dart';

const int recipeCollectionNameMaxLength = 50;
const double myRecipesHorizontalPadding = 24;

class MyRecipesScreen extends StatelessWidget {
  const MyRecipesScreen({
    required this.status,
    required this.recipes,
    required this.collections,
    required this.isOpeningRecipe,
    required this.selectedRecipeActionId,
    required this.deletingRecipeId,
    required this.favoritingRecipeId,
    required this.movingRecipeId,
    required this.deletingCollectionId,
    required this.onRetry,
    required this.onOpenRecipe,
    required this.onSelectRecipeActions,
    required this.onClearRecipeActions,
    required this.onSetRecipeFavorite,
    required this.onCreateRecipeCollection,
    required this.onRenameRecipeCollection,
    required this.onDeleteRecipeCollection,
    required this.onSetRecipeCollection,
    required this.onDeleteRecipe,
    super.key,
  });

  final RecipeHistoryStatus status;
  final List<RecipeSummary> recipes;
  final List<RecipeCollection> collections;
  final bool isOpeningRecipe;
  final String? selectedRecipeActionId;
  final String? deletingRecipeId;
  final String? favoritingRecipeId;
  final String? movingRecipeId;
  final String? deletingCollectionId;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenRecipe;
  final ValueChanged<String> onSelectRecipeActions;
  final VoidCallback onClearRecipeActions;
  final Future<bool> Function(String id, bool isFavorite) onSetRecipeFavorite;
  final Future<bool> Function(String name) onCreateRecipeCollection;
  final Future<bool> Function(String id, String name) onRenameRecipeCollection;
  final Future<bool> Function(String id) onDeleteRecipeCollection;
  final Future<bool> Function(String id, String? collectionId)
  onSetRecipeCollection;
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
              padding: const EdgeInsets.fromLTRB(
                myRecipesHorizontalPadding,
                24,
                myRecipesHorizontalPadding,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CulinexBrandHeader(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.myRecipesTitle,
                          style: Theme.of(
                            context,
                          ).textTheme.displaySmall?.copyWith(fontSize: 32),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey<String>(
                          'create-recipe-collection-button',
                        ),
                        onPressed: () => _editRecipeCollection(context),
                        icon: const Icon(Icons.create_new_folder_rounded),
                        tooltip: l10n.createRecipeCollectionTooltip,
                      ),
                    ],
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
            AppSounds.click();
            AppHaptics.tap();
            onRetry();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.myRecipesRetry),
        ),
      );
    }

    if (recipes.isEmpty && collections.isEmpty) {
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
    final List<_RecipeCollectionGroup> groups = _buildRecipeGroups(l10n);

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClearRecipeActions,
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final _RecipeCollectionGroup group = groups[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == groups.length - 1 ? 0 : 16,
                  ),
                  child: _RecipeCollectionSection(
                    group: group,
                    isDeleting: deletingCollectionId == group.id,
                    onRename: group.isSystem
                        ? null
                        : () => _editRecipeCollection(
                            context,
                            collection: group.collection,
                          ),
                    onDelete: group.isSystem
                        ? null
                        : () => _confirmAndDeleteCollection(
                            context,
                            group.collection!,
                          ),
                    itemBuilder: (RecipeSummary recipe) {
                      final bool isSelected =
                          selectedRecipeActionId == recipe.id;
                      return _RecipeActionItem(
                        recipe: recipe,
                        isSelected: isSelected,
                        actionLayerLink: isSelected
                            ? selectedRecipeLayerLink
                            : null,
                        enabled:
                            !isOpeningRecipe &&
                            deletingRecipeId == null &&
                            favoritingRecipeId == null &&
                            movingRecipeId == null,
                        onTap: () {
                          AppSounds.click();
                          AppHaptics.tap();
                          onOpenRecipe(recipe.id);
                        },
                        onLongPress: () {
                          AppSounds.click();
                          AppHaptics.selection();
                          onSelectRecipeActions(recipe.id);
                        },
                      );
                    },
                  ),
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
                  child: TapRegion(
                    onTapOutside: (_) => onClearRecipeActions(),
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
                        isMoving: movingRecipeId == selectedRecipe.id,
                        currentCollectionId: selectedRecipe.collectionId,
                        collections: collections,
                        onSetFavorite: () => _setRecipeFavorite(
                          context,
                          selectedRecipe.id,
                          !selectedRecipe.isFavorite,
                        ),
                        onSetCollection: (String? collectionId) =>
                            _setRecipeCollection(
                              context,
                              selectedRecipe.id,
                              collectionId,
                            ),
                        onDelete: () =>
                            _confirmAndDeleteRecipe(context, selectedRecipe),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<_RecipeCollectionGroup> _buildRecipeGroups(AppLocalizations l10n) {
    final Set<String> collectionIds = collections
        .map((collection) => collection.id)
        .toSet();
    final List<_RecipeCollectionGroup> groups = <_RecipeCollectionGroup>[
      for (final RecipeCollection collection in collections)
        _RecipeCollectionGroup(
          id: collection.id,
          name: collection.name,
          recipes: recipes
              .where((recipe) => recipe.collectionId == collection.id)
              .toList(growable: false),
          collection: collection,
        ),
    ];

    final List<RecipeSummary> recentRecipes = recipes
        .where(
          (recipe) =>
              recipe.collectionId == null ||
              !collectionIds.contains(recipe.collectionId),
        )
        .toList(growable: false);
    if (recentRecipes.isNotEmpty) {
      groups.add(
        _RecipeCollectionGroup(
          id: _RecipeCollectionGroup.recentsId,
          name: l10n.recipeCollectionRecents,
          recipes: recentRecipes,
          isSystem: true,
        ),
      );
    }

    return groups;
  }

  Future<void> _editRecipeCollection(
    BuildContext context, {
    RecipeCollection? collection,
  }) async {
    AppSounds.click();
    AppHaptics.tap();

    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _RecipeCollectionNameDialog(
          initialName: collection?.name,
          existingCollections: collections,
          excludedCollectionId: collection?.id,
        );
      },
    );
    if (name == null) {
      return;
    }

    AppSounds.click();
    AppHaptics.commit();

    final bool saved = collection == null
        ? await onCreateRecipeCollection(name)
        : await onRenameRecipeCollection(collection.id, name);
    if (!context.mounted || saved) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            collection == null
                ? context.l10n.recipeCollectionCreateFailed
                : context.l10n.recipeCollectionRenameFailed,
          ),
        ),
      );
  }

  Future<void> _confirmAndDeleteCollection(
    BuildContext context,
    RecipeCollection collection,
  ) async {
    AppSounds.click();
    AppHaptics.tap();

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return const _DeleteRecipeCollectionDialog();
      },
    );
    if (shouldDelete != true) {
      return;
    }

    AppSounds.click();
    AppHaptics.destructive();

    final bool deleted = await onDeleteRecipeCollection(collection.id);
    if (!context.mounted || deleted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.recipeCollectionDeleteFailed)),
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

    AppSounds.click();
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
    AppSounds.click();
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

  Future<void> _setRecipeCollection(
    BuildContext context,
    String id,
    String? collectionId,
  ) async {
    AppSounds.click();
    AppHaptics.commit();

    final bool updated = await onSetRecipeCollection(id, collectionId);
    if (!context.mounted || updated) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.recipeCollectionMoveFailed)),
      );
  }
}

class _RecipeCollectionGroup {
  const _RecipeCollectionGroup({
    required this.id,
    required this.name,
    required this.recipes,
    this.collection,
    this.isSystem = false,
  });

  static const String recentsId = '__recents__';

  final String id;
  final String name;
  final List<RecipeSummary> recipes;
  final RecipeCollection? collection;
  final bool isSystem;
}

class _RecipeCollectionSection extends StatefulWidget {
  _RecipeCollectionSection({
    required this.group,
    required this.isDeleting,
    required this.itemBuilder,
    this.onRename,
    this.onDelete,
  }) : super(key: ValueKey<String>('recipe-collection-section-${group.id}'));

  final _RecipeCollectionGroup group;
  final bool isDeleting;
  final Widget Function(RecipeSummary recipe) itemBuilder;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  State<_RecipeCollectionSection> createState() =>
      _RecipeCollectionSectionState();
}

class _RecipeCollectionSectionState extends State<_RecipeCollectionSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final Color menuColor =
        Color.lerp(colors.elevatedSurface, colors.canvas, 0.55) ??
        colors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colors.elevatedSurface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            key: ValueKey<String>(
              'recipe-collection-header-${widget.group.id}',
            ),
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              AppSounds.click();
              AppHaptics.selection();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.chevron_right_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.recipeCollectionCount(
                            widget.group.recipes.length,
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.mutedInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.group.isSystem)
                    PopupMenuButton<_RecipeCollectionMenuAction>(
                      enabled: !widget.isDeleting,
                      color: menuColor,
                      elevation: 14,
                      shadowColor: theme.colorScheme.shadow.withValues(
                        alpha: theme.brightness == Brightness.dark
                            ? 0.45
                            : 0.18,
                      ),
                      surfaceTintColor: Colors.transparent,
                      position: PopupMenuPosition.under,
                      offset: const Offset(0, 8),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: colors.border.withValues(alpha: 0.95),
                        ),
                      ),
                      onSelected: (action) {
                        switch (action) {
                          case _RecipeCollectionMenuAction.rename:
                            widget.onRename?.call();
                          case _RecipeCollectionMenuAction.delete:
                            widget.onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<_RecipeCollectionMenuAction>(
                          value: _RecipeCollectionMenuAction.rename,
                          child: _RecipeCollectionMenuItem(
                            icon: Icons.edit_outlined,
                            label: l10n.renameRecipeCollection,
                          ),
                        ),
                        PopupMenuItem<_RecipeCollectionMenuAction>(
                          value: _RecipeCollectionMenuAction.delete,
                          child: _RecipeCollectionMenuItem(
                            icon: Icons.delete_outline_rounded,
                            label: l10n.deleteRecipeCollection,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                for (
                  int index = 0;
                  index < widget.group.recipes.length;
                  index++
                ) ...[
                  if (index > 0) const SizedBox(height: 10),
                  widget.itemBuilder(widget.group.recipes[index]),
                ],
              ],
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }
}

enum _RecipeCollectionMenuAction { rename, delete }

class _RecipeCollectionMenuItem extends StatelessWidget {
  const _RecipeCollectionMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);
    final Color foregroundColor = color ?? colors.ink;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: foregroundColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: foregroundColor),
        ),
      ],
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
        enableFeedback: false,
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

enum _RecipeActionMode { actions, collections }

class _RecipeActionBox extends StatefulWidget {
  const _RecipeActionBox({
    required this.isFavorite,
    required this.isFavoriting,
    required this.isDeleting,
    required this.isMoving,
    required this.currentCollectionId,
    required this.collections,
    required this.onSetFavorite,
    required this.onSetCollection,
    required this.onDelete,
  });

  final bool isFavorite;
  final bool isFavoriting;
  final bool isDeleting;
  final bool isMoving;
  final String? currentCollectionId;
  final List<RecipeCollection> collections;
  final VoidCallback onSetFavorite;
  final ValueChanged<String?> onSetCollection;
  final VoidCallback onDelete;

  @override
  State<_RecipeActionBox> createState() => _RecipeActionBoxState();
}

class _RecipeActionBoxState extends State<_RecipeActionBox> {
  _RecipeActionMode _mode = _RecipeActionMode.actions;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final String favoriteLabel = widget.isFavorite
        ? l10n.unfavoriteRecipe
        : l10n.favoriteRecipe;
    final String collectionLabel = l10n.addRecipeToCollection;
    final String moveRecipeLabel = l10n.moveRecipe;
    final String deleteLabel = l10n.deleteRecipe;
    final List<String> widthLabels = _mode == _RecipeActionMode.actions
        ? <String>[favoriteLabel, collectionLabel, deleteLabel]
        : <String>[
            moveRecipeLabel,
            if (widget.currentCollectionId != null) l10n.moveRecipeToRecents,
            ...widget.collections.map((collection) => collection.name),
            if (widget.collections.isEmpty) l10n.noRecipeCollectionsYet,
          ];
    final double contentWidth = _calculateActionContentWidth(
      context,
      widthLabels,
    );

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
          children: _mode == _RecipeActionMode.actions
              ? [
                  _RecipeActionButton(
                    key: const ValueKey<String>('recipe-favorite-button'),
                    onPressed:
                        widget.isFavoriting ||
                            widget.isDeleting ||
                            widget.isMoving
                        ? null
                        : widget.onSetFavorite,
                    icon: widget.isFavoriting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(
                            widget.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                          ),
                    label: favoriteLabel,
                  ),
                  _RecipeActionButton(
                    key: const ValueKey<String>(
                      'recipe-add-to-collection-button',
                    ),
                    onPressed:
                        widget.isFavoriting ||
                            widget.isDeleting ||
                            widget.isMoving
                        ? null
                        : () {
                            AppSounds.click();
                            AppHaptics.selection();
                            setState(() {
                              _mode = _RecipeActionMode.collections;
                            });
                          },
                    icon: widget.isMoving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.folder_copy_outlined),
                    label: collectionLabel,
                  ),
                  _RecipeActionButton(
                    key: const ValueKey<String>('recipe-delete-button'),
                    onPressed:
                        widget.isDeleting ||
                            widget.isFavoriting ||
                            widget.isMoving
                        ? null
                        : widget.onDelete,
                    icon: widget.isDeleting
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
                ]
              : [
                  _RecipeActionButton(
                    key: const ValueKey<String>(
                      'recipe-collection-picker-back-button',
                    ),
                    onPressed: widget.isMoving
                        ? null
                        : () {
                            AppSounds.click();
                            AppHaptics.selection();
                            setState(() {
                              _mode = _RecipeActionMode.actions;
                            });
                          },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: moveRecipeLabel,
                  ),
                  if (widget.currentCollectionId != null)
                    _RecipeActionButton(
                      key: const ValueKey<String>(
                        'recipe-move-to-recents-button',
                      ),
                      onPressed: widget.isMoving
                          ? null
                          : () => widget.onSetCollection(null),
                      icon: const Icon(Icons.history_rounded),
                      label: l10n.moveRecipeToRecents,
                    ),
                  if (widget.collections.isEmpty)
                    _RecipeActionButton(
                      key: const ValueKey<String>(
                        'recipe-collection-empty-row',
                      ),
                      onPressed: null,
                      icon: const Icon(Icons.folder_off_outlined),
                      label: l10n.noRecipeCollectionsYet,
                    )
                  else
                    for (final RecipeCollection collection
                        in widget.collections)
                      _RecipeActionButton(
                        key: ValueKey<String>(
                          'recipe-collection-option-${collection.id}',
                        ),
                        onPressed:
                            widget.isMoving ||
                                collection.id == widget.currentCollectionId
                            ? null
                            : () => widget.onSetCollection(collection.id),
                        icon: Icon(
                          collection.id == widget.currentCollectionId
                              ? Icons.check_rounded
                              : Icons.folder_outlined,
                        ),
                        label: collection.name,
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

class _RecipeCollectionNameDialog extends StatefulWidget {
  const _RecipeCollectionNameDialog({
    required this.initialName,
    required this.existingCollections,
    required this.excludedCollectionId,
  });

  final String? initialName;
  final List<RecipeCollection> existingCollections;
  final String? excludedCollectionId;

  @override
  State<_RecipeCollectionNameDialog> createState() =>
      _RecipeCollectionNameDialogState();
}

class _RecipeCollectionNameDialogState
    extends State<_RecipeCollectionNameDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  bool get _isRenaming => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final double dialogWidth = math.max(
      0,
      MediaQuery.sizeOf(context).width - (myRecipesHorizontalPadding * 2),
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: myRecipesHorizontalPadding,
        vertical: 24,
      ),
      constraints: BoxConstraints.tightFor(width: dialogWidth),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _isRenaming
                  ? l10n.renameRecipeCollectionTitle
                  : l10n.createRecipeCollectionTitle,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const ValueKey<String>('recipe-collection-name-field'),
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          maxLength: recipeCollectionNameMaxLength,
          inputFormatters: [
            LengthLimitingTextInputFormatter(recipeCollectionNameMaxLength),
          ],
          decoration: InputDecoration(
            labelText: l10n.recipeCollectionNameLabel,
            counterText: '',
          ),
          validator: (value) {
            final String name = value?.trim() ?? '';
            if (name.isEmpty) {
              return l10n.recipeCollectionNameRequired;
            }
            if (_hasDuplicateName(name)) {
              return l10n.recipeCollectionNameDuplicate;
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        FilledButton(
          key: const ValueKey<String>('recipe-collection-save-button'),
          onPressed: _submit,
          child: Text(
            _isRenaming
                ? l10n.renameRecipeCollectionAction
                : l10n.createRecipeCollectionAction,
          ),
        ),
      ],
    );
  }

  bool _hasDuplicateName(String name) {
    final String normalizedName = name.trim().toLowerCase();
    return widget.existingCollections.any((collection) {
      if (collection.id == widget.excludedCollectionId) {
        return false;
      }
      return collection.name.trim().toLowerCase() == normalizedName;
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    Navigator.of(context).pop(_controller.text.trim());
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

class _DeleteRecipeCollectionDialog extends StatelessWidget {
  const _DeleteRecipeCollectionDialog();

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
          Expanded(child: Text(l10n.deleteRecipeCollectionDialogTitle)),
          IconButton(
            key: const ValueKey<String>(
              'delete-recipe-collection-close-button',
            ),
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
      content: Text(l10n.deleteRecipeCollectionDialogMessage),
      actions: <Widget>[
        FilledButton(
          key: const ValueKey<String>(
            'delete-recipe-collection-confirm-button',
          ),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: Text(l10n.deleteRecipeCollectionDialogConfirm),
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
