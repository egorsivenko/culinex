import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/primary_action_button.dart';
import '../session/culinex_models.dart';

const int ingredientNameMaxLength = 50;
const int ingredientQuantityMaxLength = 30;
const String basicStaplesTooltipMessage =
    'Water, common dried spices and seasonings, butter, and a neutral cooking oil or olive oil.';

class IngredientReviewScreen extends StatefulWidget {
  const IngredientReviewScreen({
    required this.imagePath,
    required this.ingredients,
    required this.assumeBasicStaples,
    required this.onBack,
    required this.onProceed,
    this.onOpenRecipe,
    super.key,
  });

  final String? imagePath;
  final List<ExtractedIngredient> ingredients;
  final bool assumeBasicStaples;
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
  List<ExtractedIngredient> _ingredients = <ExtractedIngredient>[];
  List<String> _ingredientIds = <String>[];
  final Set<String> _removingIngredientIds = <String>{};

  bool get _hasUnsavedChanges =>
      !_ingredientsMatch(_ingredients, widget.ingredients) ||
      _assumeBasicStaples != widget.assumeBasicStaples;

  bool get _canProceed =>
      !_isSubmitting &&
      _ingredients.length >= minRecipeIngredientCount &&
      _ingredients.length <= maxRecipeIngredientCount &&
      _ingredients.every(_isComplete);

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
                      label: 'Proceed',
                      icon: Icons.auto_awesome_rounded,
                      onPressed: _canProceed ? _handleProceed : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _footerMessage,
                      style: textTheme.bodySmall?.copyWith(
                        color: _canProceed
                            ? CulinexColors.mutedInk
                            : CulinexColors.confidenceLow,
                      ),
                    ),
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
                              onPressed: widget.onBack,
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
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
                        Text(
                          'Review and adjust the list',
                          style: textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Add missing ingredients, edit names or quantities, or swipe left to remove anything irrelevant before recipe generation.',
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
                        if (widget.onOpenRecipe != null &&
                            !_hasUnsavedChanges) ...[
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
                        if (widget.onOpenRecipe != null &&
                            _hasUnsavedChanges) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Generate again to refresh the recipe after editing this list.',
                            style: textTheme.bodySmall?.copyWith(
                              color: CulinexColors.mutedInk,
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
                                              setState(() {
                                                _assumeBasicStaples = value;
                                              });
                                            },
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Assume basic staples are available',
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
                                color: CulinexColors.elevatedSurface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: CulinexColors.border),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  '${_ingredients.length} / $maxRecipeIngredientCount ingredients',
                                  style: textTheme.labelMedium,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isSubmitting
                                  ? null
                                  : _handleAddIngredient,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add ingredient'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Keep between $minRecipeIngredientCount and $maxRecipeIngredientCount ingredients. Swipe any card left to reveal the delete action.',
                          style: textTheme.bodySmall?.copyWith(
                            color: CulinexColors.mutedInk,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ExtractedIngredient ingredient =
                            _ingredients[index];
                        final String ingredientId = _ingredientIds[index];
                        final bool isRemoving = _removingIngredientIds.contains(
                          ingredientId,
                        );

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
                                      bottom: index == _ingredients.length - 1
                                          ? 0
                                          : 12,
                                    ),
                                    child: _SwipeRevealDeleteAction(
                                      deleteTooltip:
                                          'Delete ${_formatIngredientName(ingredient.name)}',
                                      enabled: !_isSubmitting && !isRemoving,
                                      onDeletePressed: () async =>
                                          _handleDeletePressed(ingredientId),
                                      child: GlassPanel(
                                        padding: const EdgeInsets.all(18),
                                        borderRadius: BorderRadius.circular(26),
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
                                                    style: textTheme.titleLarge,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip:
                                                      'Edit ${_formatIngredientName(ingredient.name)}',
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
                                                  foregroundColor: CulinexColors
                                                      .quantityBlue,
                                                  backgroundColor: CulinexColors
                                                      .quantityBlue
                                                      .withValues(alpha: 0.10),
                                                ),
                                                if (ingredient.confidence !=
                                                    null)
                                                  _DetailChip(
                                                    icon: Icons
                                                        .auto_awesome_rounded,
                                                    label: ingredient
                                                        .confidence!
                                                        .label,
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
                                                if (ingredient.isEdited)
                                                  const _DetailChip(
                                                    icon: Icons.edit_rounded,
                                                    label: 'Edited',
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
                      childCount: _ingredients.length,
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

  String get _footerMessage {
    if (_ingredients.length < minRecipeIngredientCount) {
      return 'Add at least $minRecipeIngredientCount ingredients to continue.';
    }

    if (_ingredients.length > maxRecipeIngredientCount) {
      return 'Use no more than $maxRecipeIngredientCount ingredients.';
    }

    return 'You can fine-tune the list now, and the recipe will use the edited version.';
  }

  Future<void> _handleProceed() async {
    if (!_canProceed) {
      _showSnack(_footerMessage);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onProceed(
        List<ExtractedIngredient>.unmodifiable(_ingredients),
        _assumeBasicStaples,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleAddIngredient() async {
    if (_ingredients.length >= maxRecipeIngredientCount) {
      _showSnack('You can add up to $maxRecipeIngredientCount ingredients.');
      return;
    }

    final _IngredientDraft? draft = await _showIngredientEditor();
    if (draft == null) {
      return;
    }

    setState(() {
      _ingredients = <ExtractedIngredient>[
        ..._ingredients,
        ExtractedIngredient(
          name: _normalizeIngredientName(draft.name),
          quantity: draft.quantity,
        ),
      ];
      _ingredientIds = <String>[..._ingredientIds, _newIngredientId()];
    });
  }

  Future<void> _handleEditIngredient(int index) async {
    final ExtractedIngredient current = _ingredients[index];
    final _IngredientDraft? draft = await _showIngredientEditor(
      initialIngredient: current,
    );
    if (draft == null) {
      return;
    }

    final String nextName = _normalizeIngredientName(draft.name);
    final String nextQuantity = draft.quantity.trim();
    final bool changed =
        current.name.trim() != nextName ||
        current.quantity.trim() != nextQuantity;

    if (!changed) {
      return;
    }

    setState(() {
      _ingredients[index] = ExtractedIngredient(
        name: nextName,
        quantity: nextQuantity,
        confidence: current.confidence,
        isEdited: true,
      );
    });
  }

  Future<bool> _handleDeletePressed(String ingredientId) async {
    if (_ingredients.length <= minRecipeIngredientCount) {
      _showSnack(
        'Keep at least $minRecipeIngredientCount ingredients before generating a recipe.',
      );
      return false;
    }

    setState(() {
      _removingIngredientIds.add(ingredientId);
    });

    await Future<void>.delayed(_deleteAnimationDuration);
    if (!mounted) {
      return true;
    }

    final int index = _ingredientIds.indexOf(ingredientId);
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
    if (index < 0 || index >= _ingredients.length) {
      return;
    }

    final String removedName = _formatIngredientName(_ingredients[index].name);

    setState(() {
      _ingredients.removeAt(index);
      _ingredientIds.removeAt(index);
      _removingIngredientIds.remove(ingredientId);
    });

    _showSnack('$removedName removed.');
  }

  Future<_IngredientDraft?> _showIngredientEditor({
    ExtractedIngredient? initialIngredient,
  }) {
    return showModalBottomSheet<_IngredientDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _IngredientEditorSheet(
          title: initialIngredient == null
              ? 'Add ingredient'
              : 'Edit ingredient',
          actionLabel: initialIngredient == null
              ? 'Add ingredient'
              : 'Save ingredient',
          initialName: _normalizeIngredientName(initialIngredient?.name ?? ''),
          initialQuantity: initialIngredient?.quantity ?? '',
        );
      },
    );
  }

  void _showPreview() {
    setState(() {
      _isPreviewVisible = true;
    });
  }

  void _toggleBasicStaplesInfo() {
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
      text: TextSpan(text: basicStaplesTooltipMessage, style: bodyStyle),
      textDirection: Directionality.of(context),
      maxLines: null,
    )..layout(maxWidth: contentWidth);

    const double verticalPadding = 14 + 16;
    const double headerHeight = 16;
    const double headerTextGap = 10;

    return verticalPadding + headerHeight + headerTextGap + textPainter.height;
  }

  Color _cardBorderColor(IngredientConfidence? confidence) {
    return switch (confidence) {
      IngredientConfidence.high => CulinexColors.border,
      IngredientConfidence.medium => CulinexColors.confidenceMedium.withValues(
        alpha: 0.55,
      ),
      IngredientConfidence.low => CulinexColors.confidenceLow.withValues(
        alpha: 0.60,
      ),
      null => CulinexColors.border,
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
    _ingredients = List<ExtractedIngredient>.of(ingredients);
    _ingredientIds = List<String>.generate(
      _ingredients.length,
      (_) => _newIngredientId(),
    );
    _removingIngredientIds.clear();
  }

  String _newIngredientId() => 'ingredient-${_nextIngredientIdSeed++}';

  String _formatIngredientName(String name) => _normalizeIngredientName(name);

  int? _findIngredientIndexByKey(Key key) {
    if (key is! ValueKey<String>) {
      return null;
    }

    final int index = _ingredientIds.indexOf(key.value);
    return index == -1 ? null : index;
  }

  void _repairIngredientState() {
    if (_ingredientIds.length == _ingredients.length) {
      return;
    }

    if (_ingredients.isEmpty && widget.ingredients.isNotEmpty) {
      _ingredients = List<ExtractedIngredient>.of(widget.ingredients);
    }

    _ingredientIds = List<String>.generate(
      _ingredients.length,
      (_) => _newIngredientId(),
    );
    _removingIngredientIds.clear();
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
                        tooltip: 'Close ingredient editor',
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
                'Use clear ingredient names and practical quantities.',
                style: textTheme.bodyMedium?.copyWith(
                  color: CulinexColors.mutedInk,
                ),
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
                decoration: const InputDecoration(labelText: 'Ingredient name'),
                validator: (value) {
                  final String trimmed = (value ?? '').trim();
                  if (trimmed.isEmpty) {
                    return 'Enter an ingredient name.';
                  }
                  if (trimmed.length > ingredientNameMaxLength) {
                    return 'Use up to $ingredientNameMaxLength characters.';
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
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (value) {
                  final String trimmed = (value ?? '').trim();
                  if (trimmed.isEmpty) {
                    return 'Enter a quantity.';
                  }
                  if (trimmed.length > ingredientQuantityMaxLength) {
                    return 'Use up to $ingredientQuantityMaxLength characters.';
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

class _BasicStaplesInfoToggleButton extends StatelessWidget {
  const _BasicStaplesInfoToggleButton({
    required this.isVisible,
    required this.onPressed,
  });

  final bool isVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey<String>('basic-staples-info-button'),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      tooltip: 'Basic staples info',
      onPressed: onPressed,
      icon: Icon(
        Icons.help_outline_rounded,
        size: 18,
        color: isVisible ? CulinexColors.ink : CulinexColors.mutedInk,
      ),
    );
  }
}

class _BasicStaplesTooltipPanel extends StatelessWidget {
  const _BasicStaplesTooltipPanel();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

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
                    'Assumed staples',
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                basicStaplesTooltipMessage,
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
