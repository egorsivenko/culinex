import 'dart:io';

import '../../features/session/culinex_models.dart';

abstract interface class CulinexRepository {
  Future<List<ExtractedIngredient>> extractIngredients(File imageFile);

  Future<GeneratedRecipe> generateRecipe(RecipeGenerationRequest request);

  void close();
}
