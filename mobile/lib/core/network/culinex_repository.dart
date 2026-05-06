import 'dart:io';
import 'dart:ui';

import '../../features/session/culinex_models.dart';

abstract interface class CulinexRepository {
  Future<List<ExtractedIngredient>> extractIngredients(
    File imageFile, {
    required Locale locale,
  });

  Future<GeneratedRecipe> generateRecipe(
    RecipeGenerationRequest request, {
    required Locale locale,
  });

  Future<List<RecipeSummary>> listRecipes();

  Future<List<RecipeCollection>> listRecipeCollections();

  Future<GeneratedRecipe> getRecipe(String id);

  Future<RecipeCollection> createRecipeCollection(String name);

  Future<RecipeCollection> renameRecipeCollection(String id, String name);

  Future<void> deleteRecipeCollection(String id);

  Future<void> setRecipeFavorite(String id, bool isFavorite);

  Future<void> setRecipeCollection(String id, String? collectionId);

  Future<void> deleteAllRecipes();

  Future<void> deleteRecipe(String id);

  void close();
}
