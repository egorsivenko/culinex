import 'package:culinex/core/theme/culinex_theme.dart';
import 'package:culinex/core/widgets/glass_panel.dart';
import 'package:culinex/features/ingredients/ingredient_review_screen.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

const String _basicStaplesTooltipMessage =
    'Water, common dried spices and seasonings, butter, and a neutral cooking oil or olive oil.';

void main() {
  testWidgets(
    'ingredient review screen supports preview, add, edit, delete, and proceed',
    (tester) async {
      _setTallSurface(tester);
      List<ExtractedIngredient>? submittedIngredients;
      bool? submittedAssumeBasicStaples;

      await tester.pumpWidget(
        buildLocalizedApp(
          home: IngredientReviewScreen(
            imagePath: '/tmp/fake-image.jpg',
            ingredients: const [
              ExtractedIngredient(
                name: 'tomatoes',
                quantity: '3 pieces',
                confidence: IngredientConfidence.high,
              ),
              ExtractedIngredient(
                name: 'basil',
                quantity: '1 bunch',
                confidence: IngredientConfidence.medium,
              ),
              ExtractedIngredient(
                name: 'mozzarella',
                quantity: '80 g',
                confidence: IngredientConfidence.low,
              ),
            ],
            assumeBasicStaples: true,
            onBack: () {},
            onProceed: (ingredients, assumeBasicStaples) async {
              submittedIngredients = ingredients;
              submittedAssumeBasicStaples = assumeBasicStaples;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('View original photo'), findsOneWidget);
      expect(find.text('Tomatoes'), findsOneWidget);
      expect(find.text('3 pieces'), findsOneWidget);
      expect(find.text('High confidence'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );

      await tester.tap(find.text('View original photo'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close preview'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Proceed'), findsNothing);

      await tester.tap(find.byTooltip('Close preview'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Proceed'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingredient name'),
        'garlic',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '2 cloves',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      expect(find.text('Garlic'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Edit Tomatoes'));
      await tester.tap(find.byTooltip('Edit Tomatoes'));
      await tester.pumpAndSettle();

      final TextFormField nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Ingredient name'),
      );
      expect(nameField.controller?.text, 'Tomatoes');
      expect(find.byTooltip('Close ingredient editor'), findsOneWidget);

      await tester.tap(find.byTooltip('Close ingredient editor'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Ingredient name'),
        findsNothing,
      );

      await tester.ensureVisible(find.byTooltip('Edit Tomatoes'));
      await tester.tap(find.byTooltip('Edit Tomatoes'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save ingredient'));
      await tester.pumpAndSettle();

      expect(find.text('Edited'), findsNothing);

      await tester.ensureVisible(find.byTooltip('Edit Tomatoes'));
      await tester.tap(find.byTooltip('Edit Tomatoes'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingredient name'),
        'cherry tomatoes',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '200 g',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save ingredient'));
      await tester.pumpAndSettle();

      expect(find.text('Cherry tomatoes'), findsOneWidget);
      expect(find.text('High confidence'), findsOneWidget);
      expect(find.text('Edited'), findsOneWidget);

      await tester.drag(find.text('Garlic'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(find.text('Garlic'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);

      await tester.tap(find.byTooltip('Delete Garlic'));
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text('Garlic'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Garlic'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Proceed'));
      await tester.pumpAndSettle();

      expect(submittedIngredients, isNotNull);
      expect(submittedAssumeBasicStaples, isFalse);
      expect(submittedIngredients, hasLength(3));
      expect(submittedIngredients!.first.name, 'Cherry tomatoes');
      expect(submittedIngredients!.first.quantity, '200 g');
      expect(submittedIngredients!.first.confidence, IngredientConfidence.high);
      expect(submittedIngredients!.first.isEdited, isTrue);
    },
  );

  testWidgets(
    'manual ingredient review mode starts empty and submits through the same form',
    (tester) async {
      _setTallSurface(tester);
      List<ExtractedIngredient>? submittedIngredients;
      bool? submittedAssumeBasicStaples;

      await tester.pumpWidget(
        buildLocalizedApp(
          home: IngredientReviewScreen(
            imagePath: null,
            ingredients: const [],
            assumeBasicStaples: true,
            entryMode: IngredientReviewEntryMode.manual,
            onBack: () {},
            onProceed: (ingredients, assumeBasicStaples) async {
              submittedIngredients = ingredients;
              submittedAssumeBasicStaples = assumeBasicStaples;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Manual entry'), findsOneWidget);
      expect(find.text('Add your ingredients'), findsOneWidget);
      expect(find.text('No ingredients added yet'), findsOneWidget);
      expect(
        find.text('Add at least 3 ingredients to continue.'),
        findsOneWidget,
      );
      expect(find.text('View original photo'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Proceed'))
            .onPressed,
        isNull,
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingredient name'),
        'eggs',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '2 pieces',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('No ingredients added yet'), findsNothing);
      expect(find.text('Edited'), findsNothing);
      expect(
        find.text('Add at least 2 more to generate a recipe'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.byTooltip('Edit Eggs'));
      await tester.tap(find.byTooltip('Edit Eggs'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '3 pieces',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save ingredient'));
      await tester.pumpAndSettle();

      expect(find.text('3 pieces'), findsOneWidget);
      expect(find.text('Edited'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingredient name'),
        'milk',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '100 ml',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      expect(find.text('Add 1 more to generate a recipe'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingredient name'),
        'cheese',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '30 g',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      expect(find.text('Add 1 more to generate a recipe'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Proceed'))
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Proceed'));
      await tester.pumpAndSettle();

      expect(submittedIngredients, isNotNull);
      expect(submittedIngredients, hasLength(3));
      expect(submittedIngredients!.first.name, 'Eggs');
      expect(submittedIngredients!.first.quantity, '3 pieces');
      expect(submittedIngredients!.first.isEdited, isFalse);
      expect(submittedIngredients![1].name, 'Milk');
      expect(submittedIngredients!.last.name, 'Cheese');
      expect(submittedAssumeBasicStaples, isTrue);
    },
  );

  testWidgets(
    'edited badge disappears when a scanned ingredient is restored to its original value',
    (tester) async {
      _setTallSurface(tester);
      List<ExtractedIngredient>? submittedIngredients;

      await tester.pumpWidget(
        buildLocalizedApp(
          home: IngredientReviewScreen(
            imagePath: null,
            ingredients: const [
              ExtractedIngredient(
                name: 'eggs',
                quantity: '5 pieces',
                confidence: IngredientConfidence.high,
              ),
              ExtractedIngredient(
                name: 'milk',
                quantity: '100 ml',
                confidence: IngredientConfidence.medium,
              ),
              ExtractedIngredient(
                name: 'cheese',
                quantity: '30 g',
                confidence: IngredientConfidence.high,
              ),
            ],
            assumeBasicStaples: true,
            onBack: () {},
            onProceed: (ingredients, _) async {
              submittedIngredients = ingredients;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byTooltip('Edit Eggs'));
      await tester.tap(find.byTooltip('Edit Eggs'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingredient name'),
        'eggss',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '6 pieces',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save ingredient'));
      await tester.pumpAndSettle();

      expect(find.text('Edited'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Edit Eggss'));
      await tester.tap(find.byTooltip('Edit Eggss'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingredient name'),
        '  eggs  ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        ' 5 pieces ',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save ingredient'));
      await tester.pumpAndSettle();

      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('5 pieces'), findsOneWidget);
      expect(find.text('Edited'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Proceed'));
      await tester.pumpAndSettle();

      expect(submittedIngredients, isNotNull);
      expect(submittedIngredients!.first.name, 'Eggs');
      expect(submittedIngredients!.first.quantity, '5 pieces');
      expect(submittedIngredients!.first.isEdited, isFalse);
    },
  );

  testWidgets(
    'manual ingredient review shows edited badge after a recipe already exists',
    (tester) async {
      _setTallSurface(tester);

      await tester.pumpWidget(
        buildLocalizedApp(
          home: IngredientReviewScreen(
            imagePath: null,
            ingredients: const [
              ExtractedIngredient(name: 'eggs', quantity: '2 pieces'),
              ExtractedIngredient(name: 'milk', quantity: '100 ml'),
            ],
            assumeBasicStaples: true,
            entryMode: IngredientReviewEntryMode.manual,
            onBack: () {},
            onProceed: (_, _) async {},
            onOpenRecipe: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byTooltip('Edit Eggs'));
      await tester.tap(find.byTooltip('Edit Eggs'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '3 pieces',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save ingredient'));
      await tester.pumpAndSettle();

      expect(find.text('Edited'), findsOneWidget);
    },
  );

  testWidgets('ingredient review screen shows the basic staples tooltip', (
    tester,
  ) async {
    _setTallSurface(tester);

    await tester.pumpWidget(
      buildLocalizedApp(
        home: IngredientReviewScreen(
          imagePath: null,
          ingredients: const [
            ExtractedIngredient(
              name: 'eggs',
              quantity: '2 pieces',
              confidence: IngredientConfidence.high,
            ),
            ExtractedIngredient(
              name: 'milk',
              quantity: '100 ml',
              confidence: IngredientConfidence.medium,
            ),
          ],
          assumeBasicStaples: true,
          onBack: () {},
          onProceed: (_, _) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('basic-staples-info-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('basic-staples-info-button')),
    );
    await tester.pumpAndSettle();

    final Finder sectionFinder = find.byKey(
      const ValueKey<String>('basic-staples-section-panel'),
    );
    final Finder tooltipFinder = find.byKey(
      const ValueKey<String>('basic-staples-tooltip-panel'),
    );
    final Size staplesSectionSize = tester.getSize(sectionFinder);
    final Size tooltipSize = tester.getSize(tooltipFinder);

    expect(find.text(_basicStaplesTooltipMessage), findsOneWidget);
    expect(tooltipSize.width, staplesSectionSize.width);

    await tester.tap(
      find.byKey(const ValueKey<String>('basic-staples-info-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text(_basicStaplesTooltipMessage), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('basic-staples-info-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text(_basicStaplesTooltipMessage), findsOneWidget);

    await tester.tap(find.text('Review and adjust the list'));
    await tester.pumpAndSettle();

    expect(find.text(_basicStaplesTooltipMessage), findsNothing);
  });

  testWidgets(
    'ingredient review screen shows the basic staples tooltip below when the section is at the top',
    (tester) async {
      _setSurface(tester, const Size(390, 844));

      await tester.pumpWidget(
        buildLocalizedApp(
          home: IngredientReviewScreen(
            imagePath: null,
            ingredients: const [
              ExtractedIngredient(
                name: 'eggs',
                quantity: '2 pieces',
                confidence: IngredientConfidence.high,
              ),
              ExtractedIngredient(
                name: 'milk',
                quantity: '100 ml',
                confidence: IngredientConfidence.medium,
              ),
            ],
            assumeBasicStaples: true,
            onBack: () {},
            onProceed: (_, _) async {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final Finder sectionFinder = find.byKey(
        const ValueKey<String>('basic-staples-section-panel'),
      );
      final Finder tooltipButtonFinder = find.byKey(
        const ValueKey<String>('basic-staples-info-button'),
      );

      final Rect sectionRect = tester.getRect(sectionFinder);
      expect(sectionRect.top, lessThanOrEqualTo(32));

      await tester.tap(tooltipButtonFinder);
      await tester.pumpAndSettle();

      final Rect tooltipRect = tester.getRect(
        find.byKey(const ValueKey<String>('basic-staples-tooltip-panel')),
      );
      expect(tooltipRect.left, sectionRect.left);
      expect(tooltipRect.top, greaterThan(sectionRect.bottom));
    },
  );

  testWidgets('ingredient review screen highlights lower confidence items', (
    tester,
  ) async {
    _setTallSurface(tester);
    await tester.pumpWidget(
      buildLocalizedApp(
        home: IngredientReviewScreen(
          imagePath: null,
          ingredients: const [
            ExtractedIngredient(
              name: 'spinach',
              quantity: '1 bunch',
              confidence: IngredientConfidence.medium,
            ),
            ExtractedIngredient(
              name: 'pepper',
              quantity: '2 pieces',
              confidence: IngredientConfidence.low,
            ),
          ],
          assumeBasicStaples: true,
          onBack: () {},
          onProceed: (_, _) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Spinach'), findsOneWidget);
    expect(find.text('Pepper'), findsOneWidget);
    expect(find.text('Medium confidence'), findsOneWidget);
    expect(find.text('Low confidence'), findsOneWidget);

    final Text quantityText = tester.widget<Text>(find.text('1 bunch'));
    final Text mediumConfidenceText = tester.widget<Text>(
      find.text('Medium confidence'),
    );
    final Text lowConfidenceText = tester.widget<Text>(
      find.text('Low confidence'),
    );
    final List<GlassPanel> panels = tester
        .widgetList<GlassPanel>(find.byType(GlassPanel))
        .toList();

    expect(quantityText.style?.color, CulinexColors.quantityBlue);
    expect(mediumConfidenceText.style?.color, CulinexColors.confidenceMedium);
    expect(lowConfidenceText.style?.color, CulinexColors.confidenceLow);
    expect(
      panels[1].borderColor,
      CulinexColors.confidenceMedium.withValues(alpha: 0.55),
    );
    expect(
      panels[2].borderColor,
      CulinexColors.confidenceLow.withValues(alpha: 0.60),
    );
  });

  testWidgets('delete action keeps a fixed height after ingredient edits', (
    tester,
  ) async {
    _setSurface(tester, const Size(390, 844));

    await tester.pumpWidget(
      buildLocalizedApp(
        home: IngredientReviewScreen(
          imagePath: null,
          ingredients: const [
            ExtractedIngredient(
              name: 'tomatoes',
              quantity: '3 pieces',
              confidence: IngredientConfidence.high,
            ),
            ExtractedIngredient(
              name: 'basil',
              quantity: '1 bunch',
              confidence: IngredientConfidence.medium,
            ),
          ],
          assumeBasicStaples: true,
          onBack: () {},
          onProceed: (_, _) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(GlassPanel).at(1),
      const Offset(-600, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final Finder deleteButton = find.widgetWithIcon(
      TextButton,
      Icons.delete_outline_rounded,
    );
    expect(deleteButton, findsOneWidget);

    final Size initialDeleteButtonSize = tester.getSize(deleteButton);

    await tester.pumpWidget(
      buildLocalizedApp(
        home: IngredientReviewScreen(
          imagePath: null,
          ingredients: const [
            ExtractedIngredient(
              name: 'very ripe cherry tomatoes',
              quantity: '3 pieces',
              confidence: IngredientConfidence.high,
              isEdited: true,
            ),
            ExtractedIngredient(
              name: 'basil',
              quantity: '1 bunch',
              confidence: IngredientConfidence.medium,
            ),
          ],
          assumeBasicStaples: true,
          onBack: () {},
          onProceed: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Very ripe cherry tomatoes'), findsOneWidget);
    expect(find.text('Edited'), findsOneWidget);

    await tester.drag(
      find.byType(GlassPanel).at(1),
      const Offset(-600, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final Size updatedDeleteButtonSize = tester.getSize(deleteButton);
    expect(updatedDeleteButtonSize.height, initialDeleteButtonSize.height);
    expect(updatedDeleteButtonSize.width, initialDeleteButtonSize.width);
  });

  testWidgets('ingredient editor enforces name and quantity length limits', (
    tester,
  ) async {
    _setTallSurface(tester);

    await tester.pumpWidget(
      buildLocalizedApp(
        home: IngredientReviewScreen(
          imagePath: null,
          ingredients: const [
            ExtractedIngredient(
              name: 'eggs',
              quantity: '2 pieces',
              confidence: IngredientConfidence.high,
            ),
            ExtractedIngredient(
              name: 'milk',
              quantity: '100 ml',
              confidence: IngredientConfidence.medium,
            ),
          ],
          assumeBasicStaples: true,
          onBack: () {},
          onProceed: (_, _) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add ingredient'));
    await tester.pumpAndSettle();

    expect(find.text('0/$ingredientNameMaxLength'), findsOneWidget);
    expect(find.text('0/$ingredientQuantityMaxLength'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ingredient name'),
      'a' * 80,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantity'),
      '1' * 60,
    );
    await tester.pumpAndSettle();

    final TextFormField nameField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Ingredient name'),
    );
    final TextFormField quantityField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Quantity'),
    );

    expect(nameField.controller?.text.length, ingredientNameMaxLength);
    expect(quantityField.controller?.text.length, ingredientQuantityMaxLength);
    expect(
      find.text('$ingredientNameMaxLength/$ingredientNameMaxLength'),
      findsOneWidget,
    );
    expect(
      find.text('$ingredientQuantityMaxLength/$ingredientQuantityMaxLength'),
      findsOneWidget,
    );
  });

  testWidgets(
    'ingredient review screen blocks swipe delete at the minimum count',
    (tester) async {
      _setTallSurface(tester);
      await tester.pumpWidget(
        buildLocalizedApp(
          home: IngredientReviewScreen(
            imagePath: null,
            ingredients: const [
              ExtractedIngredient(
                name: 'eggs',
                quantity: '2 pieces',
                confidence: IngredientConfidence.high,
              ),
              ExtractedIngredient(
                name: 'milk',
                quantity: '100 ml',
                confidence: IngredientConfidence.high,
              ),
              ExtractedIngredient(
                name: 'cheese',
                quantity: '30 g',
                confidence: IngredientConfidence.high,
              ),
            ],
            assumeBasicStaples: true,
            onBack: () {},
            onProceed: (_, _) async {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(find.text('Eggs'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete Eggs'));
      await tester.pumpAndSettle();

      expect(find.text('Eggs'), findsOneWidget);
      expect(
        find.text('Keep at least 3 ingredients before generating a recipe.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ingredient review screen places recipe shortcut above original photo',
    (tester) async {
      _setTallSurface(tester);

      await tester.pumpWidget(
        buildLocalizedApp(
          home: IngredientReviewScreen(
            imagePath: '/tmp/fake-image.jpg',
            ingredients: const [
              ExtractedIngredient(
                name: 'eggs',
                quantity: '2 pieces',
                confidence: IngredientConfidence.high,
              ),
              ExtractedIngredient(
                name: 'milk',
                quantity: '100 ml',
                confidence: IngredientConfidence.medium,
              ),
            ],
            assumeBasicStaples: true,
            onBack: () {},
            onProceed: (_, _) async {},
            onOpenRecipe: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      final Finder recipeButton = find.widgetWithText(
        OutlinedButton,
        'Return to recipe',
      );
      final Finder photoButton = find.widgetWithText(
        OutlinedButton,
        'View original photo',
      );

      expect(recipeButton, findsOneWidget);
      expect(photoButton, findsOneWidget);
      expect(
        tester.getTopLeft(recipeButton).dy,
        lessThan(tester.getTopLeft(photoButton).dy),
      );
    },
  );

  testWidgets(
    'ingredient review screen hides stale recipe shortcut after edits',
    (tester) async {
      _setTallSurface(tester);
      bool openedRecipe = false;

      await tester.pumpWidget(
        buildLocalizedApp(
          home: IngredientReviewScreen(
            imagePath: '/tmp/fake-image.jpg',
            ingredients: const [
              ExtractedIngredient(
                name: 'eggs',
                quantity: '2 pieces',
                confidence: IngredientConfidence.high,
              ),
              ExtractedIngredient(
                name: 'milk',
                quantity: '100 ml',
                confidence: IngredientConfidence.medium,
              ),
            ],
            assumeBasicStaples: true,
            onBack: () {},
            onProceed: (_, _) async {},
            onOpenRecipe: () {
              openedRecipe = true;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Return to recipe'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Edit Eggs'));
      await tester.tap(find.byTooltip('Edit Eggs'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '3 pieces',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save ingredient'));
      await tester.pumpAndSettle();

      expect(find.text('Return to recipe'), findsNothing);
      final Finder staleRecipeMessage = find.text(
        'Generate again to refresh the recipe after editing this list.',
      );
      final Finder photoButton = find.widgetWithText(
        OutlinedButton,
        'View original photo',
      );
      expect(staleRecipeMessage, findsOneWidget);
      expect(photoButton, findsOneWidget);
      expect(
        tester.getTopLeft(staleRecipeMessage).dy,
        lessThan(tester.getTopLeft(photoButton).dy),
      );

      expect(openedRecipe, isFalse);
    },
  );

  testWidgets(
    'ingredient review screen hides stale recipe shortcut after staples toggle changes',
    (tester) async {
      _setTallSurface(tester);

      await tester.pumpWidget(
        buildLocalizedApp(
          home: IngredientReviewScreen(
            imagePath: null,
            ingredients: const [
              ExtractedIngredient(
                name: 'eggs',
                quantity: '2 pieces',
                confidence: IngredientConfidence.high,
              ),
              ExtractedIngredient(
                name: 'milk',
                quantity: '100 ml',
                confidence: IngredientConfidence.medium,
              ),
            ],
            assumeBasicStaples: true,
            onBack: () {},
            onProceed: (_, _) async {},
            onOpenRecipe: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Return to recipe'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Return to recipe'), findsNothing);
      expect(
        find.text(
          'Generate again to refresh the recipe after editing this list.',
        ),
        findsOneWidget,
      );
    },
  );
}

void _setTallSurface(WidgetTester tester) {
  _setSurface(tester, const Size(1080, 2200));
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
