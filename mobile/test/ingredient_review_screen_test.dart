import 'package:culinex/core/theme/culinex_theme.dart';
import 'package:culinex/core/widgets/glass_panel.dart';
import 'package:culinex/features/ingredients/ingredient_review_screen.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'ingredient review screen supports preview, add, edit, delete, and proceed',
    (tester) async {
      _setTallSurface(tester);
      List<ExtractedIngredient>? submittedIngredients;
      bool? submittedAssumeBasicStaples;

      await tester.pumpWidget(
        MaterialApp(
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
      expect(submittedIngredients, hasLength(2));
      expect(submittedIngredients!.first.name, 'Cherry tomatoes');
      expect(submittedIngredients!.first.quantity, '200 g');
      expect(submittedIngredients!.first.confidence, IngredientConfidence.high);
      expect(submittedIngredients!.first.isEdited, isTrue);
    },
  );

  testWidgets('ingredient review screen highlights lower confidence items', (
    tester,
  ) async {
    _setTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
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
      MaterialApp(
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

    await tester.drag(find.byType(GlassPanel).at(1), const Offset(-600, 0));
    await tester.pumpAndSettle();

    final Finder deleteButton = find.widgetWithIcon(
      TextButton,
      Icons.delete_outline_rounded,
    );
    expect(deleteButton, findsOneWidget);

    final Size initialDeleteButtonSize = tester.getSize(deleteButton);

    await tester.pumpWidget(
      MaterialApp(
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

    await tester.drag(find.byType(GlassPanel).at(1), const Offset(-600, 0));
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
      MaterialApp(
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
        MaterialApp(
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
        find.text('Keep at least 2 ingredients before generating a recipe.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ingredient review screen hides stale recipe shortcut after edits',
    (tester) async {
      _setTallSurface(tester);
      bool openedRecipe = false;

      await tester.pumpWidget(
        MaterialApp(
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
      expect(
        find.text(
          'Generate again to refresh the recipe after editing this list.',
        ),
        findsOneWidget,
      );

      expect(openedRecipe, isFalse);
    },
  );

  testWidgets(
    'ingredient review screen hides stale recipe shortcut after staples toggle changes',
    (tester) async {
      _setTallSurface(tester);

      await tester.pumpWidget(
        MaterialApp(
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
