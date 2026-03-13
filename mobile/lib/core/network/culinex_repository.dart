import 'dart:io';

import '../../features/session/culinex_models.dart';

abstract interface class CulinexRepository {
  Future<List<ExtractedIngredient>> extractIngredients(File imageFile);

  Future<GeneratedRecipe> generateRecipe(List<RecipeIngredient> ingredients);

  void close();
}
