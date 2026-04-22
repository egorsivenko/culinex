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

  Future<GeneratedRecipe> getRecipe(String id);

  void close();
}
