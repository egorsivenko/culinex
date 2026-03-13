import 'dart:io';

import 'package:culinex/core/network/culinex_repository.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:culinex/features/session/cook_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extractIngredientsFromPhoto stores extracted ingredients', () async {
    final FakeRepository repository = FakeRepository(
      extractedIngredients: const [
        ExtractedIngredient(
          name: 'Tomatoes',
          quantity: '3 pieces',
          confidence: IngredientConfidence.high,
        ),
        ExtractedIngredient(
          name: 'Basil',
          quantity: '1 bunch',
          confidence: IngredientConfidence.medium,
        ),
      ],
    );

    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    controller.openCamera();
    await controller.extractIngredientsFromPhoto('/tmp/test-photo.jpg');

    expect(controller.stage, SessionStage.ingredients);
    expect(controller.ingredients, hasLength(2));
    expect(repository.lastExtractedFile?.path, '/tmp/test-photo.jpg');

    controller.dispose();
  });

  test('generateRecipe stores the generated recipe', () async {
    final FakeRepository repository = FakeRepository(
      extractedIngredients: const [
        ExtractedIngredient(
          name: 'Eggs',
          quantity: '2 pieces',
          confidence: IngredientConfidence.high,
        ),
      ],
      generatedRecipe: GeneratedRecipe(
        dishName: 'Soft Egg Scramble',
        dishDescription: 'Creamy eggs with a simple toast-style finish.',
        difficulty: RecipeDifficulty.easy,
        cookingTimeMinutes: 10,
        ingredients: const [
          RecipeIngredient(name: 'Eggs', quantity: '2 pieces'),
          RecipeIngredient(name: 'Butter', quantity: '10 g'),
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
    );

    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    await controller.extractIngredientsFromPhoto('/tmp/test-photo.jpg');
    await controller.generateRecipe();

    expect(controller.stage, SessionStage.recipe);
    expect(controller.recipe?.dishName, 'Soft Egg Scramble');
    expect(repository.lastRecipeIngredients, hasLength(1));

    controller.dispose();
  });

  test(
    'showIngredients returns from recipe to the ingredient review',
    () async {
      final FakeRepository repository = FakeRepository(
        extractedIngredients: const [
          ExtractedIngredient(
            name: 'Eggs',
            quantity: '2 pieces',
            confidence: IngredientConfidence.high,
          ),
        ],
        generatedRecipe: GeneratedRecipe(
          dishName: 'Soft Egg Scramble',
          dishDescription: 'Creamy eggs with a simple toast-style finish.',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 10,
          ingredients: const [
            RecipeIngredient(name: 'eggs', quantity: '2 pieces'),
          ],
          steps: const ['Cook slowly in butter until softly set.'],
          macros: const NutritionMacros(
            caloriesKcal: 240,
            proteinG: 14,
            carbsG: 2,
            fatG: 19,
          ),
        ),
      );

      final CookSessionController controller = CookSessionController(
        repository: repository,
      );

      await controller.extractIngredientsFromPhoto('/tmp/test-photo.jpg');
      await controller.generateRecipe();
      controller.showIngredients();

      expect(controller.stage, SessionStage.ingredients);
      expect(controller.ingredients, hasLength(1));
      expect(controller.recipe?.dishName, 'Soft Egg Scramble');

      controller.dispose();
    },
  );

  test('showRecipe returns from ingredients to the generated recipe', () async {
    final FakeRepository repository = FakeRepository(
      extractedIngredients: const [
        ExtractedIngredient(
          name: 'Eggs',
          quantity: '2 pieces',
          confidence: IngredientConfidence.high,
        ),
      ],
      generatedRecipe: GeneratedRecipe(
        dishName: 'Soft Egg Scramble',
        dishDescription: 'Creamy eggs with a simple toast-style finish.',
        difficulty: RecipeDifficulty.easy,
        cookingTimeMinutes: 10,
        ingredients: const [
          RecipeIngredient(name: 'eggs', quantity: '2 pieces'),
        ],
        steps: const ['Cook slowly in butter until softly set.'],
        macros: const NutritionMacros(
          caloriesKcal: 240,
          proteinG: 14,
          carbsG: 2,
          fatG: 19,
        ),
      ),
    );

    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    await controller.extractIngredientsFromPhoto('/tmp/test-photo.jpg');
    await controller.generateRecipe();
    controller.showIngredients();
    controller.showRecipe();

    expect(controller.stage, SessionStage.recipe);
    expect(controller.recipe?.dishName, 'Soft Egg Scramble');

    controller.dispose();
  });
}

class FakeRepository implements CulinexRepository {
  FakeRepository({
    this.extractedIngredients = const [],
    GeneratedRecipe? generatedRecipe,
  }) : _generatedRecipe =
           generatedRecipe ??
           GeneratedRecipe(
             dishName: 'Fallback dish',
             dishDescription: 'Fallback description',
             difficulty: RecipeDifficulty.medium,
             cookingTimeMinutes: 15,
             ingredients: const [
               RecipeIngredient(name: 'Fallback ingredient', quantity: '1'),
             ],
             steps: const ['Cook it.'],
             macros: const NutritionMacros(
               caloriesKcal: 100,
               proteinG: 5,
               carbsG: 10,
               fatG: 3,
             ),
           );

  final List<ExtractedIngredient> extractedIngredients;
  final GeneratedRecipe _generatedRecipe;

  File? lastExtractedFile;
  List<RecipeIngredient>? lastRecipeIngredients;

  @override
  Future<List<ExtractedIngredient>> extractIngredients(File imageFile) async {
    lastExtractedFile = imageFile;
    return extractedIngredients;
  }

  @override
  Future<GeneratedRecipe> generateRecipe(
    List<RecipeIngredient> ingredients,
  ) async {
    lastRecipeIngredients = ingredients;
    return _generatedRecipe;
  }

  @override
  void close() {}
}
