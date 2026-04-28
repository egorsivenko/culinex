import 'package:culinex/features/recipe/recipe_screen.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:culinex/core/theme/culinex_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('recipe screen uses the updated header and aligned metrics', (
    tester,
  ) async {
    bool wentBackToIngredients = false;
    bool wentHome = false;

    await tester.pumpWidget(
      buildLocalizedApp(
        home: RecipeScreen(
          recipe: _sampleRecipe,
          backTooltip: 'Back to ingredients',
          onBack: () {
            wentBackToIngredients = true;
          },
          onCookAnother: () {
            wentHome = true;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Recipe ready'), findsOneWidget);
    expect(find.text('Culinex recipe'), findsNothing);
    expect(find.text('Quick metrics'), findsOneWidget);
    expect(find.text('Nutrition Summary'), findsOneWidget);
    expect(find.text('Calories'), findsNothing);
    expect(find.text('Macros'), findsNothing);
    expect(find.text('240 kcal', findRichText: true), findsOneWidget);
    expect(find.text('14g Protein', findRichText: true), findsOneWidget);
    expect(find.text('3g Carbs', findRichText: true), findsOneWidget);
    expect(find.text('20g Fat', findRichText: true), findsOneWidget);
    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('Butter'), findsOneWidget);
    expect(find.text('Check items off as you cook.'), findsNothing);
    expect(find.text('Start cooking'), findsOneWidget);
    expect(find.text('Nutrition per serving'), findsNothing);
    expect(find.byType(Image), findsNothing);

    await tester.tap(find.byTooltip('Back to ingredients'));
    await tester.pump();
    expect(wentBackToIngredients, isTrue);

    await tester.tap(find.byTooltip('Back to home'));
    await tester.pump();
    expect(wentHome, isTrue);
  });

  testWidgets('cooking mode navigates steps and manages wake lock', (
    tester,
  ) async {
    final List<bool> wakeLockCalls = <bool>[];

    await tester.pumpWidget(
      buildLocalizedApp(
        home: RecipeScreen(
          recipe: _sampleRecipe,
          backTooltip: 'Back to ingredients',
          onBack: () {},
          onCookAnother: () {},
          cookingModeWakeLockSetter: (enable) async {
            wakeLockCalls.add(enable);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start cooking'));
    await tester.tap(find.text('Start cooking'));
    await tester.pumpAndSettle();

    expect(wakeLockCalls, <bool>[true]);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final LinearProgressIndicator progress = tester.widget(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 1 / 3);
    expect(progress.color, isNot(CulinexColors.confidenceHigh));
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Crack the eggs and whisk them gently.'), findsOneWidget);
    expect(find.text('Start cooking'), findsNothing);

    final Text activeStepText = tester.widget(
      find.text('Crack the eggs and whisk them gently.'),
    );
    expect(activeStepText.style?.fontSize, greaterThanOrEqualTo(20));

    final OutlinedButton firstBackButton = tester.widget(
      find.widgetWithText(OutlinedButton, 'Back'),
    );
    expect(firstBackButton.onPressed, isNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(
      find.text('Cook slowly in butter until softly set.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Fold in chives and serve warm.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Finish'), findsOneWidget);
    final LinearProgressIndicator completeProgress = tester.widget(
      find.byType(LinearProgressIndicator),
    );
    expect(completeProgress.value, 1);
    expect(completeProgress.color, CulinexColors.confidenceHigh);

    await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
    await tester.pumpAndSettle();
    expect(wakeLockCalls, <bool>[true, false]);
    expect(find.text('Start cooking'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('cooking mode close exits early and disables wake lock', (
    tester,
  ) async {
    final List<bool> wakeLockCalls = <bool>[];

    await tester.pumpWidget(
      buildLocalizedApp(
        home: RecipeScreen(
          recipe: _sampleRecipe,
          backTooltip: 'Back to ingredients',
          onBack: () {},
          onCookAnother: () {},
          cookingModeWakeLockSetter: (enable) async {
            wakeLockCalls.add(enable);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start cooking'));
    await tester.tap(find.text('Start cooking'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Close cooking mode'));
    await tester.pumpAndSettle();

    expect(wakeLockCalls, <bool>[true, false]);
    expect(find.text('Start cooking'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsNothing);
  });
}

const GeneratedRecipe _sampleRecipe = GeneratedRecipe(
  dishName: 'Soft Egg Scramble',
  dishDescription:
      'Creamy eggs finished gently for a quick one-person breakfast.',
  difficulty: RecipeDifficulty.easy,
  cookingTimeMinutes: 10,
  ingredients: [
    RecipeIngredient(name: 'eggs', quantity: '2 pieces'),
    RecipeIngredient(name: 'butter', quantity: '10 g'),
  ],
  steps: [
    'Crack the eggs and whisk them gently.',
    'Cook slowly in butter until softly set.',
    'Fold in chives and serve warm.',
  ],
  macros: NutritionMacros(
    caloriesKcal: 240,
    proteinG: 14.4,
    carbsG: 2.5,
    fatG: 19.6,
  ),
);
