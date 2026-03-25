import 'dart:io';

import 'package:culinex/core/network/culinex_repository.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:culinex/features/session/cook_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startManualIngredientEntry opens an empty manual ingredient list', () {
    final FakeRepository repository = FakeRepository();
    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    controller.startManualIngredientEntry();

    expect(controller.stage, SessionStage.ingredients);
    expect(controller.isManualIngredientEntry, isTrue);
    expect(controller.capturedImagePath, isNull);
    expect(controller.ingredients, isEmpty);

    controller.dispose();
  });

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
        ExtractedIngredient(
          name: 'Butter',
          quantity: '10 g',
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
    expect(repository.lastRecipeIngredients, hasLength(2));
    expect(repository.lastAssumeBasicStaples, isTrue);

    controller.dispose();
  });

  test(
    'ingredient scan errors offer retake photo and home actions without reusing the same image',
    () async {
      final FakeRepository repository = FakeRepository();

      final CookSessionController controller = CookSessionController(
        repository: repository,
      );

      await controller.extractIngredientsFromPhoto('/tmp/test-photo.jpg');

      expect(controller.stage, SessionStage.error);
      expect(controller.errorTitle, 'Ingredient scan failed');
      expect(controller.primaryErrorActionLabel, 'Retake photo');
      expect(controller.secondaryErrorActionLabel, 'Return home');
      expect(repository.extractCallCount, 1);

      await controller.performErrorPrimaryAction();

      expect(controller.stage, SessionStage.camera);
      expect(repository.extractCallCount, 1);

      controller.performErrorSecondaryAction();

      expect(controller.stage, SessionStage.welcome);
      expect(controller.capturedImagePath, isNull);

      controller.dispose();
    },
  );

  test(
    'generateRecipeFromIngredients uses the edited ingredient list',
    () async {
      final FakeRepository repository = FakeRepository(
        generatedRecipe: GeneratedRecipe(
          dishName: 'Tomato Toast',
          dishDescription: 'A quick toast topped with tomatoes.',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 8,
          ingredients: const [
            RecipeIngredient(name: 'Tomatoes', quantity: '150 g'),
            RecipeIngredient(name: 'Bread', quantity: '2 slices'),
          ],
          steps: const ['Toast the bread.', 'Top it with tomatoes.'],
          macros: const NutritionMacros(
            caloriesKcal: 220,
            proteinG: 6,
            carbsG: 30,
            fatG: 8,
          ),
        ),
      );

      final CookSessionController controller = CookSessionController(
        repository: repository,
      );

      await controller.generateRecipeFromIngredients(const [
        ExtractedIngredient(name: 'Tomatoes', quantity: '150 g'),
        ExtractedIngredient(name: 'Bread', quantity: '2 slices'),
        ExtractedIngredient(name: 'Basil', quantity: '4 leaves'),
      ], false);

      expect(controller.stage, SessionStage.recipe);
      expect(controller.ingredients, hasLength(3));
      expect(repository.lastRecipeIngredients, hasLength(3));
      expect(repository.lastAssumeBasicStaples, isFalse);
      expect(repository.lastRecipeIngredients?.first.name, 'Tomatoes');
      expect(repository.lastRecipeIngredients?.last.quantity, '4 leaves');

      controller.dispose();
    },
  );

  test('generateRecipeFromIngredients rejects too few ingredients', () async {
    final FakeRepository repository = FakeRepository();

    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    await controller.generateRecipeFromIngredients(const [
      ExtractedIngredient(name: 'Eggs', quantity: '2 pieces'),
    ], true);

    expect(controller.stage, SessionStage.error);
    expect(
      controller.errorMessage,
      'Add at least 2 ingredients before generating a recipe.',
    );
    expect(repository.lastRecipeIngredients, isNull);

    controller.dispose();
  });

  test(
    'manual ingredient entry returns home instead of opening the camera',
    () {
      final FakeRepository repository = FakeRepository();
      final CookSessionController controller = CookSessionController(
        repository: repository,
      );

      controller.startManualIngredientEntry();
      controller.showWelcome();
      controller.showIngredients();

      expect(controller.stage, SessionStage.ingredients);
      expect(controller.isManualIngredientEntry, isTrue);

      controller.leaveIngredientEntry();

      expect(controller.stage, SessionStage.welcome);
      expect(controller.isManualIngredientEntry, isFalse);
      expect(controller.ingredients, isEmpty);

      controller.dispose();
    },
  );

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
          ExtractedIngredient(
            name: 'Butter',
            quantity: '10 g',
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
      expect(controller.ingredients, hasLength(2));
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
        ExtractedIngredient(
          name: 'Butter',
          quantity: '10 g',
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

  int extractCallCount = 0;
  File? lastExtractedFile;
  List<RecipeIngredient>? lastRecipeIngredients;
  bool? lastAssumeBasicStaples;

  @override
  Future<List<ExtractedIngredient>> extractIngredients(File imageFile) async {
    extractCallCount += 1;
    lastExtractedFile = imageFile;
    return extractedIngredients;
  }

  @override
  Future<GeneratedRecipe> generateRecipe(
    RecipeGenerationRequest request,
  ) async {
    lastRecipeIngredients = request.ingredients;
    lastAssumeBasicStaples = request.assumeBasicStaples;
    return _generatedRecipe;
  }

  @override
  void close() {}
}
