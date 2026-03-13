import 'package:culinex/features/ingredients/ingredient_review_screen.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:culinex/core/theme/culinex_theme.dart';
import 'package:culinex/core/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ingredient review screen uses a preview button and clean rows', (
    tester,
  ) async {
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
          ],
          onBack: () {},
          onProceed: () async {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('View original photo'), findsOneWidget);
    expect(find.text('Tomatoes'), findsOneWidget);
    expect(find.text('3 pieces'), findsOneWidget);
    expect(find.text('High confidence'), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await tester.tap(find.text('View original photo'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close preview'), findsOneWidget);
  });

  testWidgets('ingredient review screen highlights lower confidence items', (
    tester,
  ) async {
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
          onBack: () {},
          onProceed: () async {},
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
      panels[0].borderColor,
      CulinexColors.confidenceMedium.withValues(alpha: 0.55),
    );
    expect(
      panels[1].borderColor,
      CulinexColors.confidenceLow.withValues(alpha: 0.60),
    );
  });

  testWidgets('ingredient review screen shows recipe shortcut when available', (
    tester,
  ) async {
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
          ],
          onBack: () {},
          onProceed: () async {},
          onOpenRecipe: () {
            openedRecipe = true;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Return to recipe'), findsOneWidget);

    await tester.tap(find.text('Return to recipe'));
    await tester.pump();

    expect(openedRecipe, isTrue);
  });
}
