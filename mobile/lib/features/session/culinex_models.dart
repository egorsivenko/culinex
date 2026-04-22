const int minRecipeIngredientCount = 2;
const int maxRecipeIngredientCount = 20;

enum IngredientConfidence {
  high,
  medium,
  low;

  factory IngredientConfidence.fromJson(String rawValue) {
    return switch (rawValue.trim().toLowerCase()) {
      'high' => IngredientConfidence.high,
      'low' => IngredientConfidence.low,
      _ => IngredientConfidence.medium,
    };
  }
}

class ExtractedIngredient {
  const ExtractedIngredient({
    required this.name,
    required this.quantity,
    this.confidence,
    this.isEdited = false,
  });

  final String name;
  final String quantity;
  final IngredientConfidence? confidence;
  final bool isEdited;

  factory ExtractedIngredient.fromJson(Map<String, dynamic> json) {
    final Object? confidenceValue = json['confidence'];

    return ExtractedIngredient(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      confidence: confidenceValue is String
          ? IngredientConfidence.fromJson(confidenceValue)
          : null,
      isEdited: false,
    );
  }

  ExtractedIngredient copyWith({
    String? name,
    String? quantity,
    IngredientConfidence? confidence,
    bool? isEdited,
    bool clearConfidence = false,
  }) {
    return ExtractedIngredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      confidence: clearConfidence ? null : confidence ?? this.confidence,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  RecipeIngredient toRecipeIngredient() {
    return RecipeIngredient(name: name, quantity: quantity);
  }
}

class RecipeIngredient {
  const RecipeIngredient({required this.name, required this.quantity});

  final String name;
  final String quantity;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'quantity': quantity};
  }
}

class RecipeGenerationRequest {
  const RecipeGenerationRequest({
    required this.ingredients,
    required this.assumeBasicStaples,
  });

  final List<RecipeIngredient> ingredients;
  final bool assumeBasicStaples;

  Map<String, dynamic> toJson() {
    return {
      'ingredients': ingredients.map((item) => item.toJson()).toList(),
      'assume_basic_staples': assumeBasicStaples,
    };
  }
}

enum RecipeDifficulty {
  easy,
  medium,
  hard;

  factory RecipeDifficulty.fromJson(String rawValue) {
    return switch (rawValue.trim().toLowerCase()) {
      'easy' => RecipeDifficulty.easy,
      'hard' => RecipeDifficulty.hard,
      _ => RecipeDifficulty.medium,
    };
  }
}

class NutritionMacros {
  const NutritionMacros({
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  factory NutritionMacros.fromJson(Map<String, dynamic> json) {
    return NutritionMacros(
      caloriesKcal: (json['calories_kcal'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GeneratedRecipe {
  const GeneratedRecipe({
    this.id,
    required this.dishName,
    required this.dishDescription,
    required this.difficulty,
    required this.cookingTimeMinutes,
    required this.ingredients,
    required this.steps,
    required this.macros,
    this.createdAt,
  });

  final String? id;
  final String dishName;
  final String dishDescription;
  final RecipeDifficulty difficulty;
  final int cookingTimeMinutes;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final NutritionMacros macros;
  final DateTime? createdAt;

  factory GeneratedRecipe.fromJson(Map<String, dynamic> json) {
    return GeneratedRecipe(
      id: json['id'] as String?,
      dishName: json['dish_name'] as String? ?? '',
      dishDescription: json['dish_description'] as String? ?? '',
      difficulty: RecipeDifficulty.fromJson(
        json['difficulty'] as String? ?? 'medium',
      ),
      cookingTimeMinutes: json['cooking_time_minutes'] as int? ?? 0,
      ingredients: ((json['ingredients'] as List<dynamic>?) ?? [])
          .map(
            (item) => RecipeIngredient.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      steps: ((json['steps'] as List<dynamic>?) ?? [])
          .map((item) => item as String)
          .toList(growable: false),
      macros: NutritionMacros.fromJson(
        json['macros'] as Map<String, dynamic>? ?? const {},
      ),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class RecipeSummary {
  const RecipeSummary({
    required this.id,
    required this.dishName,
    required this.dishDescription,
    required this.difficulty,
    required this.cookingTimeMinutes,
    this.createdAt,
  });

  final String id;
  final String dishName;
  final String dishDescription;
  final RecipeDifficulty difficulty;
  final int cookingTimeMinutes;
  final DateTime? createdAt;

  factory RecipeSummary.fromJson(Map<String, dynamic> json) {
    return RecipeSummary(
      id: json['id'] as String? ?? '',
      dishName: json['dish_name'] as String? ?? '',
      dishDescription: json['dish_description'] as String? ?? '',
      difficulty: RecipeDifficulty.fromJson(
        json['difficulty'] as String? ?? 'medium',
      ),
      cookingTimeMinutes: json['cooking_time_minutes'] as int? ?? 0,
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
