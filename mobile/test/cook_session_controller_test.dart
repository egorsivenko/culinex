import 'dart:async';
import 'dart:io';

import 'package:culinex/core/network/culinex_api_client.dart';
import 'package:culinex/core/network/culinex_repository.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:culinex/features/session/cook_session_controller.dart';
import 'package:flutter/widgets.dart';
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
    expect(repository.lastExtractLocale, const Locale('en'));

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
    expect(repository.lastGenerateLocale, const Locale('en'));

    controller.dispose();
  });

  test('generateRecipe maps invalid ingredients errors', () async {
    final FakeRepository repository = FakeRepository(
      extractedIngredients: const [
        ExtractedIngredient(name: 'adadsa', quantity: 'adadad'),
        ExtractedIngredient(name: 'qweqwe', quantity: 'zxczxc'),
      ],
      generateRecipeError: const CulinexApiException(
        CulinexApiErrorCode.invalidIngredients,
      ),
    );

    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    await controller.extractIngredientsFromPhoto('/tmp/test-photo.jpg');
    await controller.generateRecipe();

    expect(controller.stage, SessionStage.error);
    expect(controller.lastOperation, SessionOperation.generateRecipe);
    expect(controller.errorState.code, SessionErrorCode.invalidIngredients);
    expect(controller.recipe, isNull);

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
      expect(controller.lastOperation, SessionOperation.extractIngredients);
      expect(
        controller.errorState.code,
        SessionErrorCode.noClearIngredientsDetected,
      );
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
    expect(controller.errorState.code, SessionErrorCode.tooFewIngredients);
    expect(controller.errorState.count, minRecipeIngredientCount);
    expect(repository.lastRecipeIngredients, isNull);

    controller.dispose();
  });

  test('selected locale is used for extract and recipe generation', () async {
    final FakeRepository repository = FakeRepository(
      extractedIngredients: const [
        ExtractedIngredient(name: 'Яйця', quantity: '2 шт'),
        ExtractedIngredient(name: 'Масло', quantity: '10 г'),
      ],
    );
    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    controller.setLocale(const Locale('uk'));
    await controller.extractIngredientsFromPhoto('/tmp/test-photo.jpg');
    await controller.generateRecipe();

    expect(repository.lastExtractLocale, const Locale('uk'));
    expect(repository.lastGenerateLocale, const Locale('uk'));

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

  test('loadRecipeHistory stores saved recipe summaries', () async {
    final FakeRepository repository = FakeRepository(
      recipeSummaries: [
        RecipeSummary(
          id: 'recipe-1',
          dishName: 'Tomato Pasta',
          dishDescription: 'Simple dinner',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 20,
          createdAt: DateTime.utc(2026, 4, 21, 12),
        ),
        RecipeSummary(
          id: 'recipe-2',
          dishName: 'Egg Toast',
          dishDescription: 'Fast breakfast',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 8,
          isFavorite: true,
          createdAt: DateTime.utc(2026, 4, 20, 12),
        ),
      ],
    );
    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    await controller.loadRecipeHistory();

    expect(controller.recipeHistoryStatus, RecipeHistoryStatus.loaded);
    expect(controller.recipeSummaries, hasLength(2));
    expect(controller.recipeSummaries.first.dishName, 'Egg Toast');
    expect(repository.listRecipesCallCount, 1);

    controller.dispose();
  });

  test(
    'setRecipeFavorite optimistically favorites, reorders, deselects, and syncs open detail',
    () async {
      final FakeRepository repository = FakeRepository(
        recipeSummaries: [
          RecipeSummary(
            id: 'recipe-1',
            dishName: 'Tomato Pasta',
            dishDescription: 'Simple dinner',
            difficulty: RecipeDifficulty.easy,
            cookingTimeMinutes: 20,
            createdAt: DateTime.utc(2026, 4, 20, 12),
          ),
          RecipeSummary(
            id: 'recipe-2',
            dishName: 'Egg Toast',
            dishDescription: 'Fast breakfast',
            difficulty: RecipeDifficulty.easy,
            cookingTimeMinutes: 8,
            createdAt: DateTime.utc(2026, 4, 21, 12),
          ),
        ],
        savedRecipe: GeneratedRecipe(
          id: 'recipe-1',
          dishName: 'Tomato Pasta',
          dishDescription: 'Simple dinner',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 20,
          ingredients: const [
            RecipeIngredient(name: 'Tomatoes', quantity: '2 pieces'),
            RecipeIngredient(name: 'Pasta', quantity: '90 g'),
          ],
          steps: const ['Boil pasta.', 'Add tomatoes.'],
          macros: const NutritionMacros(
            caloriesKcal: 320,
            proteinG: 12,
            carbsG: 54,
            fatG: 8,
          ),
        ),
      );
      final CookSessionController controller = CookSessionController(
        repository: repository,
      );

      await controller.loadRecipeHistory();
      await controller.openSavedRecipe('recipe-1');
      controller.selectRecipeActions('recipe-1');
      final bool updated = await controller.setRecipeFavorite('recipe-1', true);

      expect(updated, isTrue);
      expect(repository.favoriteUpdates, <String, bool>{'recipe-1': true});
      expect(controller.favoritingRecipeId, isNull);
      expect(controller.selectedRecipeActionId, isNull);
      expect(controller.recipe?.isFavorite, isTrue);
      expect(controller.recipeSummaries.map((recipe) => recipe.id), <String>[
        'recipe-1',
        'recipe-2',
      ]);
      expect(controller.recipeSummaries.first.isFavorite, isTrue);

      controller.dispose();
    },
  );

  test(
    'setRecipeFavorite optimistically unfavorites, reorders, and deselects',
    () async {
      final FakeRepository repository = FakeRepository(
        recipeSummaries: [
          RecipeSummary(
            id: 'recipe-1',
            dishName: 'Tomato Pasta',
            dishDescription: 'Simple dinner',
            difficulty: RecipeDifficulty.easy,
            cookingTimeMinutes: 20,
            isFavorite: true,
            createdAt: DateTime.utc(2026, 4, 20, 12),
          ),
          RecipeSummary(
            id: 'recipe-2',
            dishName: 'Egg Toast',
            dishDescription: 'Fast breakfast',
            difficulty: RecipeDifficulty.easy,
            cookingTimeMinutes: 8,
            createdAt: DateTime.utc(2026, 4, 21, 12),
          ),
        ],
      );
      final CookSessionController controller = CookSessionController(
        repository: repository,
      );

      await controller.loadRecipeHistory();
      controller.selectRecipeActions('recipe-1');
      final bool updated = await controller.setRecipeFavorite(
        'recipe-1',
        false,
      );

      expect(updated, isTrue);
      expect(repository.favoriteUpdates, <String, bool>{'recipe-1': false});
      expect(controller.selectedRecipeActionId, isNull);
      expect(controller.recipeSummaries.map((recipe) => recipe.id), <String>[
        'recipe-2',
        'recipe-1',
      ]);
      expect(controller.recipeSummaries.last.isFavorite, isFalse);

      controller.dispose();
    },
  );

  test('setRecipeFavorite rolls back on failure', () async {
    final FakeRepository repository = FakeRepository(
      setFavoriteError: const CulinexApiException(
        CulinexApiErrorCode.serverFailure,
      ),
      recipeSummaries: [
        RecipeSummary(
          id: 'recipe-1',
          dishName: 'Tomato Pasta',
          dishDescription: 'Simple dinner',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 20,
          createdAt: DateTime.utc(2026, 4, 20, 12),
        ),
        RecipeSummary(
          id: 'recipe-2',
          dishName: 'Egg Toast',
          dishDescription: 'Fast breakfast',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 8,
          createdAt: DateTime.utc(2026, 4, 21, 12),
        ),
      ],
    );
    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    await controller.loadRecipeHistory();
    controller.selectRecipeActions('recipe-1');
    final bool updated = await controller.setRecipeFavorite('recipe-1', true);

    expect(updated, isFalse);
    expect(controller.favoritingRecipeId, isNull);
    expect(controller.selectedRecipeActionId, 'recipe-1');
    expect(controller.recipeSummaries.map((recipe) => recipe.id), <String>[
      'recipe-2',
      'recipe-1',
    ]);
    expect(
      controller.recipeSummaries
          .firstWhere((recipe) => recipe.id == 'recipe-1')
          .isFavorite,
      isFalse,
    );

    controller.dispose();
  });

  test('deleteAllRecipes clears summaries and saved history detail', () async {
    final FakeRepository repository = FakeRepository(
      recipeSummaries: const [
        RecipeSummary(
          id: 'recipe-1',
          dishName: 'Tomato Pasta',
          dishDescription: 'Simple dinner',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 20,
        ),
        RecipeSummary(
          id: 'recipe-2',
          dishName: 'Egg Toast',
          dishDescription: 'Fast breakfast',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 8,
        ),
      ],
      savedRecipe: GeneratedRecipe(
        id: 'recipe-1',
        dishName: 'Tomato Pasta',
        dishDescription: 'Simple dinner',
        difficulty: RecipeDifficulty.easy,
        cookingTimeMinutes: 20,
        ingredients: const [
          RecipeIngredient(name: 'Tomatoes', quantity: '2 pieces'),
        ],
        steps: const ['Cook.'],
        macros: const NutritionMacros(
          caloriesKcal: 320,
          proteinG: 12,
          carbsG: 54,
          fatG: 8,
        ),
      ),
    );
    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    await controller.loadRecipeHistory();
    await controller.openSavedRecipe('recipe-1');
    controller.showRecipeHistory();
    final bool deleted = await controller.deleteAllRecipes();

    expect(deleted, isTrue);
    expect(repository.deleteAllRecipesCallCount, 1);
    expect(controller.isDeletingAllRecipes, isFalse);
    expect(controller.recipeHistoryStatus, RecipeHistoryStatus.loaded);
    expect(controller.recipeSummaries, isEmpty);
    expect(controller.recipe, isNull);
    expect(controller.recipeOpenedFromHistory, isFalse);
    expect(controller.selectedRecipeActionId, isNull);

    controller.dispose();
  });

  test('deleteAllRecipes preserves state on failure', () async {
    final FakeRepository repository = FakeRepository(
      deleteAllRecipesError: const CulinexApiException(
        CulinexApiErrorCode.serverFailure,
      ),
      recipeSummaries: const [
        RecipeSummary(
          id: 'recipe-1',
          dishName: 'Tomato Pasta',
          dishDescription: 'Simple dinner',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 20,
        ),
      ],
    );
    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    await controller.loadRecipeHistory();
    controller.selectRecipeActions('recipe-1');
    final bool deleted = await controller.deleteAllRecipes();

    expect(deleted, isFalse);
    expect(controller.isDeletingAllRecipes, isFalse);
    expect(controller.recipeHistoryStatus, RecipeHistoryStatus.loaded);
    expect(controller.recipeSummaries, hasLength(1));
    expect(controller.selectedRecipeActionId, 'recipe-1');

    controller.dispose();
  });

  test(
    'deleteAllRecipes is blocked while another recipe mutation is running',
    () async {
      final Completer<void> pendingDelete = Completer<void>();
      final FakeRepository repository = FakeRepository(
        deleteRecipeCompleter: pendingDelete,
        recipeSummaries: const [
          RecipeSummary(
            id: 'recipe-1',
            dishName: 'Tomato Pasta',
            dishDescription: 'Simple dinner',
            difficulty: RecipeDifficulty.easy,
            cookingTimeMinutes: 20,
          ),
        ],
      );
      final CookSessionController controller = CookSessionController(
        repository: repository,
      );

      await controller.loadRecipeHistory();
      final Future<bool> deleteFuture = controller.deleteRecipe('recipe-1');
      await Future<void>.delayed(Duration.zero);

      final bool deletedAll = await controller.deleteAllRecipes();
      expect(deletedAll, isFalse);
      expect(repository.deleteAllRecipesCallCount, 0);

      pendingDelete.complete();
      expect(await deleteFuture, isTrue);

      controller.dispose();
    },
  );

  test(
    'deleteRecipe removes the summary and clears the selected action',
    () async {
      final FakeRepository repository = FakeRepository(
        recipeSummaries: const [
          RecipeSummary(
            id: 'recipe-1',
            dishName: 'Tomato Pasta',
            dishDescription: 'Simple dinner',
            difficulty: RecipeDifficulty.easy,
            cookingTimeMinutes: 20,
          ),
          RecipeSummary(
            id: 'recipe-2',
            dishName: 'Egg Toast',
            dishDescription: 'Fast breakfast',
            difficulty: RecipeDifficulty.easy,
            cookingTimeMinutes: 8,
          ),
        ],
      );
      final CookSessionController controller = CookSessionController(
        repository: repository,
      );

      await controller.loadRecipeHistory();
      controller.selectRecipeActions('recipe-1');
      final bool deleted = await controller.deleteRecipe('recipe-1');

      expect(deleted, isTrue);
      expect(repository.deletedRecipeIds, <String>['recipe-1']);
      expect(controller.recipeHistoryStatus, RecipeHistoryStatus.loaded);
      expect(controller.selectedRecipeActionId, isNull);
      expect(controller.deletingRecipeId, isNull);
      expect(controller.recipeSummaries.map((recipe) => recipe.id), <String>[
        'recipe-2',
      ]);

      controller.dispose();
    },
  );

  test(
    'deleteRecipe keeps summaries visible and exposes history error on failure',
    () async {
      final FakeRepository repository = FakeRepository(
        deleteRecipeError: const CulinexApiException(
          CulinexApiErrorCode.serverFailure,
        ),
        recipeSummaries: const [
          RecipeSummary(
            id: 'recipe-1',
            dishName: 'Tomato Pasta',
            dishDescription: 'Simple dinner',
            difficulty: RecipeDifficulty.easy,
            cookingTimeMinutes: 20,
          ),
        ],
      );
      final CookSessionController controller = CookSessionController(
        repository: repository,
      );

      await controller.loadRecipeHistory();
      controller.selectRecipeActions('recipe-1');
      final bool deleted = await controller.deleteRecipe('recipe-1');

      expect(deleted, isFalse);
      expect(controller.recipeHistoryStatus, RecipeHistoryStatus.error);
      expect(controller.recipeSummaries, hasLength(1));
      expect(controller.selectedRecipeActionId, 'recipe-1');
      expect(controller.deletingRecipeId, isNull);

      controller.dispose();
    },
  );

  test('openSavedRecipe opens history recipe detail', () async {
    final FakeRepository repository = FakeRepository(
      savedRecipe: GeneratedRecipe(
        id: 'recipe-1',
        dishName: 'Tomato Pasta',
        dishDescription: 'Simple dinner',
        difficulty: RecipeDifficulty.easy,
        cookingTimeMinutes: 20,
        ingredients: const [
          RecipeIngredient(name: 'Tomatoes', quantity: '2 pieces'),
          RecipeIngredient(name: 'Pasta', quantity: '90 g'),
        ],
        steps: const ['Boil pasta.', 'Add tomatoes.'],
        macros: const NutritionMacros(
          caloriesKcal: 320,
          proteinG: 12,
          carbsG: 54,
          fatG: 8,
        ),
      ),
    );
    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    await controller.openSavedRecipe('recipe-1');

    expect(controller.stage, SessionStage.recipe);
    expect(controller.recipeOpenedFromHistory, isTrue);
    expect(controller.recipe?.dishName, 'Tomato Pasta');
    expect(repository.lastOpenedRecipeId, 'recipe-1');

    controller.showRecipeHistory();

    expect(controller.stage, SessionStage.welcome);
    expect(controller.recipeOpenedFromHistory, isFalse);

    controller.dispose();
  });

  test('deleteRecipe clears the open history detail when it matches', () async {
    final FakeRepository repository = FakeRepository(
      recipeSummaries: const [
        RecipeSummary(
          id: 'recipe-1',
          dishName: 'Tomato Pasta',
          dishDescription: 'Simple dinner',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 20,
        ),
      ],
      savedRecipe: GeneratedRecipe(
        id: 'recipe-1',
        dishName: 'Tomato Pasta',
        dishDescription: 'Simple dinner',
        difficulty: RecipeDifficulty.easy,
        cookingTimeMinutes: 20,
        ingredients: const [
          RecipeIngredient(name: 'Tomatoes', quantity: '2 pieces'),
          RecipeIngredient(name: 'Pasta', quantity: '90 g'),
        ],
        steps: const ['Boil pasta.', 'Add tomatoes.'],
        macros: const NutritionMacros(
          caloriesKcal: 320,
          proteinG: 12,
          carbsG: 54,
          fatG: 8,
        ),
      ),
    );
    final CookSessionController controller = CookSessionController(
      repository: repository,
    );

    await controller.loadRecipeHistory();
    await controller.openSavedRecipe('recipe-1');
    final bool deleted = await controller.deleteRecipe('recipe-1');

    expect(deleted, isTrue);
    expect(controller.stage, SessionStage.welcome);
    expect(controller.recipe, isNull);
    expect(controller.recipeOpenedFromHistory, isFalse);
    expect(controller.recipeSummaries, isEmpty);

    controller.dispose();
  });
}

class FakeRepository implements CulinexRepository {
  FakeRepository({
    this.extractedIngredients = const [],
    this.recipeSummaries = const [],
    GeneratedRecipe? generatedRecipe,
    this.generateRecipeError,
    GeneratedRecipe? savedRecipe,
    this.setFavoriteError,
    this.deleteAllRecipesError,
    this.deleteRecipeCompleter,
    this.deleteRecipeError,
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
           ),
       _savedRecipe = savedRecipe;

  final List<ExtractedIngredient> extractedIngredients;
  final List<RecipeSummary> recipeSummaries;
  final GeneratedRecipe _generatedRecipe;
  final GeneratedRecipe? _savedRecipe;
  final Object? generateRecipeError;
  final Object? setFavoriteError;
  final Object? deleteAllRecipesError;
  final Completer<void>? deleteRecipeCompleter;
  final Object? deleteRecipeError;

  int extractCallCount = 0;
  int listRecipesCallCount = 0;
  int deleteAllRecipesCallCount = 0;
  final Map<String, bool> favoriteUpdates = <String, bool>{};
  final List<String> deletedRecipeIds = <String>[];
  String? lastOpenedRecipeId;
  File? lastExtractedFile;
  Locale? lastExtractLocale;
  List<RecipeIngredient>? lastRecipeIngredients;
  bool? lastAssumeBasicStaples;
  Locale? lastGenerateLocale;

  @override
  Future<List<ExtractedIngredient>> extractIngredients(
    File imageFile, {
    required Locale locale,
  }) async {
    extractCallCount += 1;
    lastExtractedFile = imageFile;
    lastExtractLocale = locale;
    return extractedIngredients;
  }

  @override
  Future<GeneratedRecipe> generateRecipe(
    RecipeGenerationRequest request, {
    required Locale locale,
  }) async {
    lastRecipeIngredients = request.ingredients;
    lastAssumeBasicStaples = request.assumeBasicStaples;
    lastGenerateLocale = locale;
    final Object? error = generateRecipeError;
    if (error != null) {
      throw error;
    }
    return _generatedRecipe;
  }

  @override
  Future<List<RecipeSummary>> listRecipes() async {
    listRecipesCallCount += 1;
    return recipeSummaries;
  }

  @override
  Future<GeneratedRecipe> getRecipe(String id) async {
    lastOpenedRecipeId = id;
    final GeneratedRecipe? savedRecipe = _savedRecipe;
    if (savedRecipe == null) {
      throw const CulinexApiException(CulinexApiErrorCode.serverFailure);
    }
    return savedRecipe;
  }

  @override
  Future<void> setRecipeFavorite(String id, bool isFavorite) async {
    final Object? error = setFavoriteError;
    if (error != null) {
      throw error;
    }
    favoriteUpdates[id] = isFavorite;
  }

  @override
  Future<void> deleteRecipe(String id) async {
    final Completer<void>? completer = deleteRecipeCompleter;
    if (completer != null) {
      await completer.future;
    }
    final Object? error = deleteRecipeError;
    if (error != null) {
      throw error;
    }
    deletedRecipeIds.add(id);
  }

  @override
  Future<void> deleteAllRecipes() async {
    deleteAllRecipesCallCount += 1;
    final Object? error = deleteAllRecipesError;
    if (error != null) {
      throw error;
    }
  }

  @override
  void close() {}
}
