import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/feedback/app_haptics.dart';
import '../../core/feedback/app_sounds.dart';
import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../session/culinex_models.dart';
import '../session/session_localizations.dart';

const int ingredientNameMaxLength = 50;
const int ingredientQuantityMaxLength = 30;

enum IngredientReviewEntryMode { scanned, manual }

extension IngredientReviewEntryModeCopy on IngredientReviewEntryMode {
  String statusLabel(AppLocalizations l10n) => switch (this) {
    IngredientReviewEntryMode.scanned => l10n.ingredientStatusScanned,
    IngredientReviewEntryMode.manual => l10n.ingredientStatusManual,
  };

  String title(AppLocalizations l10n) => switch (this) {
    IngredientReviewEntryMode.scanned => l10n.ingredientReviewScannedTitle,
    IngredientReviewEntryMode.manual => l10n.ingredientReviewManualTitle,
  };

  String description(AppLocalizations l10n) => switch (this) {
    IngredientReviewEntryMode.scanned =>
      l10n.ingredientReviewScannedDescription,
    IngredientReviewEntryMode.manual => l10n.ingredientReviewManualDescription,
  };
}

class IngredientReviewScreen extends StatefulWidget {
  const IngredientReviewScreen({
    required this.imagePath,
    required this.ingredients,
    required this.assumeBasicStaples,
    required this.onBack,
    required this.onProceed,
    this.onOpenRecipe,
    this.entryMode = IngredientReviewEntryMode.scanned,
    super.key,
  });

  final String? imagePath;
  final List<ExtractedIngredient> ingredients;
  final bool assumeBasicStaples;
  final IngredientReviewEntryMode entryMode;
  final VoidCallback onBack;
  final Future<void> Function(
    List<ExtractedIngredient> ingredients,
    bool assumeBasicStaples,
  )
  onProceed;
  final VoidCallback? onOpenRecipe;

  @override
  State<IngredientReviewScreen> createState() => _IngredientReviewScreenState();
}

class _IngredientReviewScreenState extends State<IngredientReviewScreen> {
  static const Duration _deleteAnimationDuration = Duration(milliseconds: 240);
  static const double _basicStaplesTooltipGap = 5;

  bool _isPreviewVisible = false;
  bool _isSubmitting = false;
  bool _isBasicStaplesInfoVisible = false;
  bool _showBasicStaplesTooltipBelow = false;
  bool _assumeBasicStaples = true;
  int _nextIngredientIdSeed = 0;
  BuildContext? _basicStaplesSectionContext;
  final LayerLink _basicStaplesSectionLink = LayerLink();
  final Object _basicStaplesTapRegionId = Object();
  List<_IngredientRowState> _ingredientRows = <_IngredientRowState>[];
  final Set<String> _removingIngredientIds = <String>{};

  bool get _hasUnsavedChanges =>
      !_ingredientsMatch(_currentIngredients, widget.ingredients) ||
      _assumeBasicStaples != widget.assumeBasicStaples;

  bool get _canProceed =>
      !_isSubmitting &&
      _ingredientRows.length >= minRecipeIngredientCount &&
      _ingredientRows.length <= maxRecipeIngredientCount &&
      _ingredientRows.every((row) => _isComplete(row.ingredient));

  bool get _shouldTrackEditedIngredients =>
      widget.entryMode == IngredientReviewEntryMode.scanned ||
      widget.onOpenRecipe != null;

  @override
  void initState() {
    super.initState();
    _assumeBasicStaples = widget.assumeBasicStaples;
    _resetIngredients(widget.ingredients);
  }

  @override
  void didUpdateWidget(covariant IngredientReviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_ingredientsMatch(oldWidget.ingredients, widget.ingredients)) {
      setState(() {
        _resetIngredients(widget.ingredients);
      });
    }

    if (oldWidget.assumeBasicStaples != widget.assumeBasicStaples) {
      _assumeBasicStaples = widget.assumeBasicStaples;
    }
  }

  @override
  Widget build(BuildContext context) {
    _repairIngredientState();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);
    final AppLocalizations l10n = context.l10n;
    final String? footerMessage = _footerMessage(l10n);
    final RenderBox? basicStaplesSectionBox =
        _basicStaplesSectionContext?.findRenderObject() as RenderBox?;
    final double? basicStaplesSectionWidth = basicStaplesSectionBox?.size.width;

    return Scaffold(
      bottomNavigationBar: _isPreviewVisible
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PrimaryActionButton(
                      label: l10n.proceed,
                      icon: Icons.auto_awesome_rounded,
                      onPressed: _canProceed ? _handleProceed : null,
                    ),
                    if (footerMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        footerMessage,
                        style: textTheme.bodySmall?.copyWith(
                          color: CulinexColors.confidenceLow,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                AppSounds.click();
                                widget.onBack();
                              },
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
                            ),
                            const Spacer(),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.elevatedSurface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: colors.border),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(widget.entryMode.statusLabel(l10n)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.entryMode.title(l10n),
                          style: textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.entryMode.description(l10n),
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.mutedInk,
                          ),
                        ),
                        if (widget.onOpenRecipe != null) ...[
                          const SizedBox(height: 20),
                          if (!_hasUnsavedChanges)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: widget.onOpenRecipe,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: CulinexColors.quantityBlue,
                                    width: 1.4,
                                  ),
                                ),
                                icon: const Icon(Icons.restaurant_menu_rounded),
                                label: Text(l10n.returnToRecipe),
                              ),
                            )
                          else
                            Text(
                              l10n.generateAgainHint,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.mutedInk,
                              ),
                            ),
                        ],
                        if (widget.imagePath != null) ...[
                          SizedBox(
                            height: widget.onOpenRecipe != null ? 12 : 20,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showPreview,
                              icon: const Icon(Icons.photo_outlined),
                              label: Text(l10n.viewOriginalPhoto),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TapRegion(
                          groupId: _basicStaplesTapRegionId,
                          onTapOutside: (_) => _hideBasicStaplesInfo(),
                          child: Builder(
                            builder: (sectionContext) {
                              _basicStaplesSectionContext = sectionContext;
                              return CompositedTransformTarget(
                                link: _basicStaplesSectionLink,
                                child: Container(
                                  key: const ValueKey<String>(
                                    'basic-staples-section-panel',
                                  ),
                                  child: GlassPanel(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    child: SwitchListTile.adaptive(
                                      contentPadding: EdgeInsets.zero,
                                      value: _assumeBasicStaples,
                                      onChanged: _isSubmitting
                                          ? null
                                          : (value) {
                                              AppSounds.click();
                                              AppHaptics.selection();
                                              setState(() {
                                                _assumeBasicStaples = value;
                                              });
                                            },
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              l10n.assumeBasicStaplesTitle,
                                              style: textTheme.titleMedium,
                                            ),
                                          ),
                                          _BasicStaplesInfoToggleButton(
                                            isVisible:
                                                _isBasicStaplesInfoVisible,
                                            onPressed: _toggleBasicStaplesInfo,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.elevatedSurface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: colors.border),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  l10n.ingredientCountStatus(
                                    _ingredientRows.length,
                                    maxRecipeIngredientCount,
                                  ),
                                  style: textTheme.labelMedium,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isSubmitting
                                  ? null
                                  : _handleAddIngredient,
                              icon: const Icon(Icons.add_rounded),
                              label: Text(l10n.addIngredient),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colors.border.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  if (_ingredientRows.isEmpty &&
                      widget.entryMode == IngredientReviewEntryMode.manual)
                    SliverToBoxAdapter(
                      child: const _ManualIngredientEmptyState(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final _IngredientRowState ingredientRow =
                              _ingredientRows[index];
                          final ExtractedIngredient ingredient =
                              ingredientRow.ingredient;
                          final String ingredientId = ingredientRow.id;
                          final bool isRemoving = _removingIngredientIds
                              .contains(ingredientId);

                          return KeyedSubtree(
                            key: ValueKey<String>(ingredientId),
                            child: AnimatedSize(
                              duration: _deleteAnimationDuration,
                              curve: Curves.easeInOutCubic,
                              child: ClipRect(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  heightFactor: isRemoving ? 0 : 1,
                                  child: AnimatedOpacity(
                                    duration: _deleteAnimationDuration,
                                    curve: Curves.easeOutCubic,
                                    opacity: isRemoving ? 0 : 1,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            index == _ingredientRows.length - 1
                                            ? 0
                                            : 12,
                                      ),
                                      child: _SwipeRevealDeleteAction(
                                        deleteTooltip: l10n
                                            .deleteIngredientTooltip(
                                              _formatIngredientName(
                                                ingredient.name,
                                              ),
                                            ),
                                        enabled: !_isSubmitting && !isRemoving,
                                        onDeletePressed: () async =>
                                            _handleDeletePressed(ingredientId),
                                        child: GlassPanel(
                                          padding: const EdgeInsets.all(18),
                                          borderRadius: BorderRadius.circular(
                                            26,
                                          ),
                                          borderColor: _cardBorderColor(
                                            ingredient.confidence,
                                          ),
                                          borderWidth: _cardBorderWidth(
                                            ingredient.confidence,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _formatIngredientName(
                                                        ingredient.name,
                                                      ),
                                                      style:
                                                          textTheme.titleLarge,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: l10n
                                                        .editIngredientTooltip(
                                                          _formatIngredientName(
                                                            ingredient.name,
                                                          ),
                                                        ),
                                                    onPressed:
                                                        _isSubmitting ||
                                                            isRemoving
                                                        ? null
                                                        : () =>
                                                              _handleEditIngredient(
                                                                index,
                                                              ),
                                                    icon: const Icon(
                                                      Icons.edit_outlined,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _DetailChip(
                                                    icon: Icons
                                                        .inventory_2_outlined,
                                                    label: ingredient.quantity,
                                                    foregroundColor:
                                                        CulinexColors
                                                            .quantityBlue,
                                                    backgroundColor:
                                                        CulinexColors
                                                            .quantityBlue
                                                            .withValues(
                                                              alpha: 0.10,
                                                            ),
                                                  ),
                                                  if (ingredient.confidence !=
                                                      null)
                                                    _DetailChip(
                                                      icon: Icons
                                                          .auto_awesome_rounded,
                                                      label: ingredient
                                                          .confidence!
                                                          .label(l10n),
                                                      foregroundColor:
                                                          _confidenceColor(
                                                            ingredient
                                                                .confidence!,
                                                          ),
                                                      backgroundColor:
                                                          _confidenceColor(
                                                            ingredient
                                                                .confidence!,
                                                          ).withValues(
                                                            alpha: 0.10,
                                                          ),
                                                    ),
                                                  if (_shouldShowEditedBadge(
                                                    ingredient,
                                                  ))
                                                    _DetailChip(
                                                      icon: Icons.edit_rounded,
                                                      label: l10n.editedBadge,
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _ingredientRows.length,
                        findChildIndexCallback: _findIngredientIndexByKey,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ),
            ),
          ),
          if (_isBasicStaplesInfoVisible && basicStaplesSectionWidth != null)
            TapRegion(
              groupId: _basicStaplesTapRegionId,
              child: CompositedTransformFollower(
                link: _basicStaplesSectionLink,
                showWhenUnlinked: false,
                targetAnchor: _showBasicStaplesTooltipBelow
                    ? Alignment.bottomLeft
                    : Alignment.topLeft,
                followerAnchor: _showBasicStaplesTooltipBelow
                    ? Alignment.topLeft
                    : Alignment.bottomLeft,
                offset: Offset(
                  0,
                  _showBasicStaplesTooltipBelow
                      ? _basicStaplesTooltipGap
                      : -_basicStaplesTooltipGap,
                ),
                child: SizedBox(
                  width: basicStaplesSectionWidth,
                  child: const _BasicStaplesTooltipPanel(),
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

  String? _footerMessage(AppLocalizations l10n) {
    if (_ingredientRows.isEmpty &&
        widget.entryMode == IngredientReviewEntryMode.manual) {
      return null;
    }

    if (_ingredientRows.length < minRecipeIngredientCount) {
      return l10n.addMoreIngredientsToGenerate(
        minRecipeIngredientCount - _ingredientRows.length,
      );
    }

    if (_ingredientRows.length > maxRecipeIngredientCount) {
      return l10n.useNoMoreThanIngredients(maxRecipeIngredientCount);
    }

    return null;
  }

  Future<void> _handleProceed() async {
    final AppLocalizations l10n = context.l10n;
    if (!_canProceed) {
      _showSnack(_footerMessage(l10n) ?? l10n.completeIngredientFields);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onProceed(_currentIngredients, _assumeBasicStaples);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleAddIngredient() async {
    final AppLocalizations l10n = context.l10n;
    if (_ingredientRows.length >= maxRecipeIngredientCount) {
      _showSnack(l10n.addUpToIngredients(maxRecipeIngredientCount));
      return;
    }

    AppSounds.click();
    AppHaptics.tap();

    final _IngredientDraft? draft = await _showIngredientEditor();
    if (draft == null) {
      return;
    }

    AppSounds.click();
    AppHaptics.commit();

    setState(() {
      final ExtractedIngredient ingredient = ExtractedIngredient(
        name: _normalizeIngredientName(draft.name),
        quantity: draft.quantity,
      );
      _ingredientRows = <_IngredientRowState>[
        ..._ingredientRows,
        _createIngredientRow(ingredient),
      ];
    });
  }

  Future<void> _handleEditIngredient(int index) async {
    AppSounds.click();
    AppHaptics.tap();

    final _IngredientRowState ingredientRow = _ingredientRows[index];
    final ExtractedIngredient current = ingredientRow.ingredient;
    final _IngredientDraft? draft = await _showIngredientEditor(
      initialIngredient: current,
    );
    if (draft == null) {
      return;
    }

    final String nextName = _normalizeIngredientName(draft.name);
    final String nextQuantity = draft.quantity.trim();
    final String currentName = _normalizeIngredientName(current.name);
    final String currentQuantity = current.quantity.trim();
    final ExtractedIngredient updatedIngredient = ExtractedIngredient(
      name: nextName,
      quantity: nextQuantity,
      confidence: current.confidence,
    );
    final bool changed =
        currentName != nextName || currentQuantity != nextQuantity;

    if (!changed) {
      return;
    }

    AppSounds.click();
    AppHaptics.commit();

    setState(() {
      _ingredientRows[index] = ingredientRow.copyWith(
        ingredient: updatedIngredient.copyWith(
          isEdited:
              _shouldTrackEditedIngredients &&
              _differsFromBaseline(ingredientRow, updatedIngredient),
        ),
      );
    });
  }

  Future<bool> _handleDeletePressed(String ingredientId) async {
    final AppLocalizations l10n = context.l10n;
    if (_ingredientRows.length <= minRecipeIngredientCount) {
      _showSnack(l10n.keepAtLeastIngredients(minRecipeIngredientCount));
      return false;
    }

    AppSounds.click();
    AppHaptics.destructive();

    setState(() {
      _removingIngredientIds.add(ingredientId);
    });

    await Future<void>.delayed(_deleteAnimationDuration);
    if (!mounted) {
      return true;
    }

    final int index = _findIngredientIndexById(ingredientId);
    if (index == -1) {
      if (mounted) {
        setState(() {
          _removingIngredientIds.remove(ingredientId);
        });
      }
      return true;
    }

    _deleteIngredient(index, ingredientId);
    return true;
  }

  void _deleteIngredient(int index, String ingredientId) {
    if (index < 0 || index >= _ingredientRows.length) {
      return;
    }

    final String removedName = _formatIngredientName(
      _ingredientRows[index].ingredient.name,
    );

    setState(() {
      _ingredientRows.removeAt(index);
      _removingIngredientIds.remove(ingredientId);
    });

    _showSnack(context.l10n.ingredientRemoved(removedName));
  }

  Future<_IngredientDraft?> _showIngredientEditor({
    ExtractedIngredient? initialIngredient,
  }) {
    final AppLocalizations l10n = context.l10n;
    return showModalBottomSheet<_IngredientDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _IngredientEditorSheet(
          title: initialIngredient == null
              ? l10n.ingredientEditorAddTitle
              : l10n.ingredientEditorEditTitle,
          actionLabel: initialIngredient == null
              ? l10n.ingredientEditorAddAction
              : l10n.ingredientEditorSaveAction,
          initialName: _normalizeIngredientName(initialIngredient?.name ?? ''),
          initialQuantity: initialIngredient?.quantity ?? '',
        );
      },
    );
  }

  void _showPreview() {
    AppSounds.click();
    AppHaptics.selection();
    setState(() {
      _isPreviewVisible = true;
    });
  }

  void _toggleBasicStaplesInfo() {
    AppSounds.click();
    AppHaptics.selection();
    if (_isBasicStaplesInfoVisible) {
      _hideBasicStaplesInfo();
      return;
    }

    setState(() {
      _showBasicStaplesTooltipBelow = _shouldShowBasicStaplesTooltipBelow(
        context,
      );
      _isBasicStaplesInfoVisible = true;
    });
  }

  void _hideBasicStaplesInfo() {
    if (!_isBasicStaplesInfoVisible) {
      return;
    }

    setState(() {
      _isBasicStaplesInfoVisible = false;
    });
  }

  void _hidePreview() {
    AppSounds.click();
    AppHaptics.selection();
    setState(() {
      _isPreviewVisible = false;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isComplete(ExtractedIngredient ingredient) {
    return ingredient.name.trim().isNotEmpty &&
        ingredient.quantity.trim().isNotEmpty;
  }

  List<ExtractedIngredient> get _currentIngredients =>
      List<ExtractedIngredient>.unmodifiable(
        _ingredientRows.map((row) => row.ingredient),
      );

  bool _differsFromBaseline(
    _IngredientRowState ingredientRow,
    ExtractedIngredient ingredient,
  ) {
    return _normalizeIngredientName(ingredientRow.baseline.name) !=
            _normalizeIngredientName(ingredient.name) ||
        ingredientRow.baseline.quantity.trim() != ingredient.quantity.trim();
  }

  bool _shouldShowEditedBadge(ExtractedIngredient ingredient) {
    return ingredient.isEdited && _shouldTrackEditedIngredients;
  }

  bool _ingredientsMatch(
    List<ExtractedIngredient> left,
    List<ExtractedIngredient> right,
  ) {
    if (left.length != right.length) {
      return false;
    }

    for (int index = 0; index < left.length; index++) {
      final ExtractedIngredient a = left[index];
      final ExtractedIngredient b = right[index];
      if (a.name != b.name ||
          a.quantity != b.quantity ||
          a.confidence != b.confidence ||
          a.isEdited != b.isEdited) {
        return false;
      }
    }

    return true;
  }

  Color _confidenceColor(IngredientConfidence confidence) {
    return switch (confidence) {
      IngredientConfidence.high => CulinexColors.confidenceHigh,
      IngredientConfidence.medium => CulinexColors.confidenceMedium,
      IngredientConfidence.low => CulinexColors.confidenceLow,
    };
  }

  bool _shouldShowBasicStaplesTooltipBelow(BuildContext context) {
    final RenderBox? renderBox =
        _basicStaplesSectionContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return false;
    }

    final Offset topLeft = renderBox.localToGlobal(Offset.zero);
    final double safeTopInset = MediaQuery.paddingOf(context).top;
    final double availableSpaceAbove = topLeft.dy - safeTopInset;
    final double estimatedTooltipHeight = _estimateBasicStaplesTooltipHeight(
      context,
      renderBox.size.width,
    );

    return availableSpaceAbove <
        estimatedTooltipHeight + _basicStaplesTooltipGap;
  }

  double _estimateBasicStaplesTooltipHeight(
    BuildContext context,
    double tooltipWidth,
  ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle bodyStyle =
        textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFF1F1F1),
          height: 1.42,
        ) ??
        const TextStyle(fontSize: 14, height: 1.42);

    final double contentWidth = (tooltipWidth - 32)
        .clamp(0, double.infinity)
        .toDouble();
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: context.l10n.basicStaplesTooltipMessage,
        style: bodyStyle,
      ),
      textDirection: Directionality.of(context),
      maxLines: null,
    )..layout(maxWidth: contentWidth);

    const double verticalPadding = 14 + 16;
    const double headerHeight = 16;
    const double headerTextGap = 10;

    return verticalPadding + headerHeight + headerTextGap + textPainter.height;
  }

  Color _cardBorderColor(IngredientConfidence? confidence) {
    final CulinexPalette colors = CulinexColors.of(context);

    return switch (confidence) {
      IngredientConfidence.high => colors.border,
      IngredientConfidence.medium => CulinexColors.confidenceMedium.withValues(
        alpha: 0.55,
      ),
      IngredientConfidence.low => CulinexColors.confidenceLow.withValues(
        alpha: 0.60,
      ),
      null => colors.border,
    };
  }

  double _cardBorderWidth(IngredientConfidence? confidence) {
    return switch (confidence) {
      IngredientConfidence.high => 1,
      IngredientConfidence.medium => 1.4,
      IngredientConfidence.low => 1.6,
      null => 1,
    };
  }

  void _resetIngredients(List<ExtractedIngredient> ingredients) {
    _ingredientRows = ingredients
        .map(_createIngredientRow)
        .toList(growable: true);
    _removingIngredientIds.clear();
  }

  _IngredientRowState _createIngredientRow(ExtractedIngredient ingredient) {
    return _IngredientRowState(
      id: _newIngredientId(),
      baseline: ingredient,
      ingredient: ingredient,
    );
  }

  String _newIngredientId() => 'ingredient-${_nextIngredientIdSeed++}';

  String _formatIngredientName(String name) => _normalizeIngredientName(name);

  int? _findIngredientIndexByKey(Key key) {
    if (key is! ValueKey<String>) {
      return null;
    }

    final int index = _findIngredientIndexById(key.value);
    return index == -1 ? null : index;
  }

  int _findIngredientIndexById(String ingredientId) {
    return _ingredientRows.indexWhere((row) => row.id == ingredientId);
  }

  void _repairIngredientState() {
    if (_ingredientRows.isNotEmpty || widget.ingredients.isEmpty) {
      return;
    }

    _resetIngredients(widget.ingredients);
  }
}

class _IngredientRowState {
  const _IngredientRowState({
    required this.id,
    required this.baseline,
    required this.ingredient,
  });

  final String id;
  final ExtractedIngredient baseline;
  final ExtractedIngredient ingredient;

  _IngredientRowState copyWith({
    ExtractedIngredient? baseline,
    ExtractedIngredient? ingredient,
  }) {
    return _IngredientRowState(
      id: id,
      baseline: baseline ?? this.baseline,
      ingredient: ingredient ?? this.ingredient,
    );
  }
}

class _ManualIngredientEmptyState extends StatelessWidget {
  const _ManualIngredientEmptyState();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;

    return GlassPanel(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.noIngredientsAddedYet, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            l10n.addAtLeastIngredientsToContinue(minRecipeIngredientCount),
            style: textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
          ),
        ],
      ),
    );
  }
}

class _DeleteIngredientBackground extends StatelessWidget {
  static const double buttonHeight = 72;

  const _DeleteIngredientBackground({
    required this.tooltip,
    required this.onPressed,
    required this.enabled,
  });

  final String tooltip;
  final Future<void> Function() onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: _SwipeRevealDeleteAction.actionWidth,
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 2),
          child: SizedBox(
            height: buttonHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CulinexColors.confidenceLow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: CulinexColors.confidenceLow.withValues(alpha: 0.40),
                ),
              ),
              child: IgnorePointer(
                ignoring: !enabled,
                child: Tooltip(
                  message: tooltip,
                  child: TextButton(
                    onPressed: () {
                      onPressed();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: CulinexColors.confidenceLow,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Icon(Icons.delete_outline_rounded),
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

class _SwipeRevealDeleteAction extends StatefulWidget {
  const _SwipeRevealDeleteAction({
    required this.child,
    required this.deleteTooltip,
    required this.onDeletePressed,
    required this.enabled,
  });

  static const double actionWidth = 92;

  final Widget child;
  final String deleteTooltip;
  final Future<bool> Function() onDeletePressed;
  final bool enabled;

  @override
  State<_SwipeRevealDeleteAction> createState() =>
      _SwipeRevealDeleteActionState();
}

class _SwipeRevealDeleteActionState extends State<_SwipeRevealDeleteAction> {
  static const Duration _actionEnableDelay = Duration(milliseconds: 220);

  Timer? _actionEnableTimer;
  double _revealWidth = 0;
  bool _isDragging = false;
  bool _isDeleteActionEnabled = true;

  @override
  void dispose() {
    _actionEnableTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: widget.enabled ? _handleDragStart : null,
      onHorizontalDragUpdate: widget.enabled ? _handleDragUpdate : null,
      onHorizontalDragEnd: widget.enabled ? _handleDragEnd : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _DeleteIngredientBackground(
              tooltip: widget.deleteTooltip,
              enabled: _isDeleteActionEnabled,
              onPressed: () async {
                final bool isDeleting = await widget.onDeletePressed();
                if (!isDeleting) {
                  _close();
                }
              },
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _revealWidth),
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            builder: (context, revealWidth, child) {
              return Transform.translate(
                offset: Offset(-revealWidth, 0),
                child: child,
              );
            },
            child: widget.child,
          ),
        ],
      ),
    );
  }

  void _handleDragStart(DragStartDetails details) {
    _actionEnableTimer?.cancel();
    setState(() {
      _isDragging = true;
      _isDeleteActionEnabled = false;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final double delta = details.primaryDelta ?? 0;
    setState(() {
      _revealWidth = (_revealWidth - delta).clamp(
        0,
        _SwipeRevealDeleteAction.actionWidth,
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    final bool shouldOpen =
        velocity < -220 ||
        _revealWidth > _SwipeRevealDeleteAction.actionWidth * 0.45;

    setState(() {
      _isDragging = false;
      _revealWidth = shouldOpen ? _SwipeRevealDeleteAction.actionWidth : 0;
      _isDeleteActionEnabled = !shouldOpen;
    });

    if (shouldOpen) {
      AppSounds.click();
      AppHaptics.selection();
      _scheduleDeleteActionEnable();
    }
  }

  void _close() {
    _actionEnableTimer?.cancel();
    setState(() {
      _isDragging = false;
      _revealWidth = 0;
      _isDeleteActionEnabled = true;
    });
  }

  void _scheduleDeleteActionEnable() {
    _actionEnableTimer?.cancel();
    _actionEnableTimer = Timer(_actionEnableDelay, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleteActionEnabled = true;
      });
    });
  }
}

class _IngredientDraft {
  const _IngredientDraft({required this.name, required this.quantity});

  final String name;
  final String quantity;
}

class _IngredientEditorSheet extends StatefulWidget {
  const _IngredientEditorSheet({
    required this.title,
    required this.actionLabel,
    required this.initialName,
    required this.initialQuantity,
  });

  final String title;
  final String actionLabel;
  final String initialName;
  final String initialQuantity;

  @override
  State<_IngredientEditorSheet> createState() => _IngredientEditorSheetState();
}

class _IngredientEditorSheetState extends State<_IngredientEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: _normalizeIngredientName(widget.initialName),
  );
  late final TextEditingController _quantityController = TextEditingController(
    text: widget.initialQuantity,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Text(
                        widget.title,
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: 0,
                      child: IconButton(
                        tooltip: l10n.closeIngredientEditorTooltip,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.ingredientEditorDescription,
                style: textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: ingredientNameMaxLength,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(ingredientNameMaxLength),
                ],
                decoration: InputDecoration(
                  labelText: l10n.ingredientNameLabel,
                ),
                validator: (value) {
                  final String trimmed = (value ?? '').trim();
                  if (trimmed.isEmpty) {
                    return l10n.enterIngredientName;
                  }
                  if (trimmed.length > ingredientNameMaxLength) {
                    return l10n.useUpToCharacters(ingredientNameMaxLength);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quantityController,
                textInputAction: TextInputAction.done,
                maxLength: ingredientQuantityMaxLength,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(ingredientQuantityMaxLength),
                ],
                decoration: InputDecoration(labelText: l10n.quantityLabel),
                validator: (value) {
                  final String trimmed = (value ?? '').trim();
                  if (trimmed.isEmpty) {
                    return l10n.enterQuantity;
                  }
                  if (trimmed.length > ingredientQuantityMaxLength) {
                    return l10n.useUpToCharacters(ingredientQuantityMaxLength);
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              PrimaryActionButton(
                label: widget.actionLabel,
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _IngredientDraft(
        name: _normalizeIngredientName(_nameController.text),
        quantity: _quantityController.text.trim(),
      ),
    );
  }
}

String _normalizeIngredientName(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
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
                      tooltip: context.l10n.closePreviewTooltip,
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.black,
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
    this.foregroundColor,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);
    final Color resolvedForegroundColor = foregroundColor ?? colors.ink;
    final Color resolvedBackgroundColor =
        backgroundColor ?? colors.elevatedSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBackgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: resolvedForegroundColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: resolvedForegroundColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicStaplesInfoToggleButton extends StatelessWidget {
  const _BasicStaplesInfoToggleButton({
    required this.isVisible,
    required this.onPressed,
  });

  final bool isVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final CulinexPalette colors = CulinexColors.of(context);
    final l10n = context.l10n;

    return IconButton(
      key: const ValueKey<String>('basic-staples-info-button'),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      tooltip: l10n.basicStaplesInfoTooltip,
      onPressed: onPressed,
      icon: Icon(
        Icons.help_outline_rounded,
        size: 18,
        color: isVisible ? colors.ink : colors.mutedInk,
      ),
    );
  }
}

class _BasicStaplesTooltipPanel extends StatelessWidget {
  const _BasicStaplesTooltipPanel();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return IgnorePointer(
      child: DecoratedBox(
        key: const ValueKey<String>('basic-staples-tooltip-panel'),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF2D2D2D)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.basicStaplesTooltipTitle,
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.basicStaplesTooltipMessage,
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFF1F1F1),
                  height: 1.42,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
