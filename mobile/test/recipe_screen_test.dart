import 'package:culinex/features/recipe/recipe_screen.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('recipe screen uses the updated header and aligned metrics', (
    tester,
  ) async {
    bool wentBackToIngredients = false;
    bool wentHome = false;

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeScreen(
          recipe: GeneratedRecipe(
            dishName: 'Soft Egg Scramble',
            dishDescription:
                'Creamy eggs finished gently for a quick one-person breakfast.',
            difficulty: RecipeDifficulty.easy,
            cookingTimeMinutes: 10,
            ingredients: const [
              RecipeIngredient(name: 'eggs', quantity: '2 pieces'),
              RecipeIngredient(name: 'butter', quantity: '10 g'),
            ],
            steps: const [
              'Crack the eggs and whisk them gently.',
              'Cook slowly in butter until softly set.',
            ],
            macros: const NutritionMacros(
              caloriesKcal: 240,
              proteinG: 14,
              carbsG: 2,
              fatG: 19,
            ),
          ),
          onBackToIngredients: () {
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
    expect(find.text('Macros'), findsOneWidget);
    expect(find.text('P 14  C 2  F 19'), findsOneWidget);
    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('Butter'), findsOneWidget);
    expect(find.text('Nutrition per serving'), findsNothing);
    expect(find.byType(Image), findsNothing);

    await tester.tap(find.byTooltip('Back to ingredients'));
    await tester.pump();
    expect(wentBackToIngredients, isTrue);

    await tester.tap(find.byTooltip('Back to home'));
    await tester.pump();
    expect(wentHome, isTrue);
  });
}
