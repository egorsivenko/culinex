import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/network/culinex_api_client.dart';
import '../../core/network/culinex_repository.dart';
import 'culinex_models.dart';

enum SessionStage {
  welcome,
  camera,
  extracting,
  ingredients,
  generatingRecipe,
  recipe,
  error,
}

enum SessionOperation { none, extractIngredients, generateRecipe }

class CookSessionController extends ChangeNotifier {
  CookSessionController({required CulinexRepository repository})
    : _repository = repository;

  final CulinexRepository _repository;

  SessionStage _stage = SessionStage.welcome;
  SessionOperation _lastOperation = SessionOperation.none;
  String? _capturedImagePath;
  List<ExtractedIngredient> _ingredients = const [];
  bool _assumeBasicStaples = true;
  GeneratedRecipe? _recipe;
  String? _errorMessage;
  bool _isDisposed = false;

  SessionStage get stage => _stage;
  String? get capturedImagePath => _capturedImagePath;
  List<ExtractedIngredient> get ingredients => _ingredients;
  bool get assumeBasicStaples => _assumeBasicStaples;
  GeneratedRecipe? get recipe => _recipe;
  String get errorMessage =>
      _errorMessage ?? 'Something went wrong. Please try again.';

  String get errorTitle => switch (_lastOperation) {
    SessionOperation.extractIngredients => 'Ingredient scan failed',
    SessionOperation.generateRecipe => 'Recipe generation failed',
    SessionOperation.none => 'Something went wrong',
  };

  String get primaryErrorActionLabel => switch (_lastOperation) {
    SessionOperation.none => 'Start over',
    SessionOperation.extractIngredients => 'Retake photo',
    SessionOperation.generateRecipe => 'Try generating again',
  };

  String get secondaryErrorActionLabel => switch (_lastOperation) {
    SessionOperation.extractIngredients => 'Return home',
    SessionOperation.generateRecipe => 'Back to ingredients',
    SessionOperation.none => 'Home',
  };

  void showWelcome() {
    _stage = SessionStage.welcome;
    _errorMessage = null;
    _notifySafely();
  }

  void openCamera() {
    _stage = SessionStage.camera;
    _errorMessage = null;
    _notifySafely();
  }

  void showIngredients() {
    if (_ingredients.isEmpty) {
      openCamera();
      return;
    }

    _stage = SessionStage.ingredients;
    _errorMessage = null;
    _notifySafely();
  }

  void showRecipe() {
    if (_recipe == null) {
      showIngredients();
      return;
    }

    _stage = SessionStage.recipe;
    _errorMessage = null;
    _notifySafely();
  }

  void resetSession() {
    _capturedImagePath = null;
    _ingredients = const [];
    _assumeBasicStaples = true;
    _recipe = null;
    _errorMessage = null;
    _lastOperation = SessionOperation.none;
    _stage = SessionStage.welcome;
    _notifySafely();
  }

  void retakePhoto() {
    _ingredients = const [];
    _assumeBasicStaples = true;
    _recipe = null;
    _errorMessage = null;
    _stage = SessionStage.camera;
    _notifySafely();
  }

  void performErrorSecondaryAction() {
    switch (_lastOperation) {
      case SessionOperation.extractIngredients:
        resetSession();
        return;
      case SessionOperation.generateRecipe:
        showIngredients();
        return;
      case SessionOperation.none:
        resetSession();
        return;
    }
  }

  Future<void> performErrorPrimaryAction() async {
    switch (_lastOperation) {
      case SessionOperation.extractIngredients:
        retakePhoto();
        return;
      case SessionOperation.generateRecipe:
        await generateRecipe();
        return;
      case SessionOperation.none:
        resetSession();
        return;
    }
  }

  Future<void> extractIngredientsFromPhoto(String imagePath) async {
    _capturedImagePath = imagePath;
    _ingredients = const [];
    _assumeBasicStaples = true;
    _recipe = null;
    _errorMessage = null;
    _lastOperation = SessionOperation.extractIngredients;
    _stage = SessionStage.extracting;
    _notifySafely();

    try {
      final List<ExtractedIngredient> extractedIngredients = await _repository
          .extractIngredients(File(imagePath));

      if (_isDisposed) {
        return;
      }

      if (extractedIngredients.isEmpty) {
        throw const CulinexSessionException(
          'No clear ingredients were detected. Try moving closer and improving the lighting.',
        );
      }

      _ingredients = List<ExtractedIngredient>.unmodifiable(
        extractedIngredients,
      );
      _stage = SessionStage.ingredients;
      _notifySafely();
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      _setError(
        error,
        fallbackMessage:
            'I could not recognize the ingredients from this photo. Please try again.',
      );
    }
  }

  Future<void> generateRecipe() async {
    if (_ingredients.length < minRecipeIngredientCount) {
      _setError(
        const CulinexSessionException(
          'Add at least 2 ingredients before generating a recipe.',
        ),
        fallbackMessage:
            'Add at least 2 ingredients before generating a recipe.',
      );
      return;
    }

    if (_ingredients.length > maxRecipeIngredientCount) {
      _setError(
        CulinexSessionException(
          'Use no more than $maxRecipeIngredientCount ingredients for one recipe.',
        ),
        fallbackMessage:
            'Use no more than $maxRecipeIngredientCount ingredients for one recipe.',
      );
      return;
    }

    _errorMessage = null;
    _lastOperation = SessionOperation.generateRecipe;
    _stage = SessionStage.generatingRecipe;
    _notifySafely();

    try {
      final GeneratedRecipe nextRecipe = await _repository.generateRecipe(
        RecipeGenerationRequest(
          ingredients: _ingredients
              .map((item) => item.toRecipeIngredient())
              .toList(),
          assumeBasicStaples: _assumeBasicStaples,
        ),
      );

      if (_isDisposed) {
        return;
      }

      _recipe = nextRecipe;
      _stage = SessionStage.recipe;
      _notifySafely();
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      _setError(
        error,
        fallbackMessage: 'Recipe generation failed. Please try again.',
      );
    }
  }

  Future<void> generateRecipeFromIngredients(
    List<ExtractedIngredient> ingredients,
    bool assumeBasicStaples,
  ) async {
    try {
      _ingredients = _prepareIngredients(ingredients);
      _assumeBasicStaples = assumeBasicStaples;
      _recipe = null;
      await generateRecipe();
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      _setError(
        error,
        fallbackMessage: 'Recipe generation failed. Please try again.',
      );
    }
  }

  List<ExtractedIngredient> _prepareIngredients(
    List<ExtractedIngredient> ingredients,
  ) {
    final List<ExtractedIngredient> sanitized = ingredients
        .map(
          (item) => ExtractedIngredient(
            name: item.name.trim(),
            quantity: item.quantity.trim(),
            confidence: item.confidence,
            isEdited: item.isEdited,
          ),
        )
        .where((item) => item.name.isNotEmpty && item.quantity.isNotEmpty)
        .toList(growable: false);

    if (sanitized.length < minRecipeIngredientCount) {
      throw const CulinexSessionException(
        'Add at least 2 ingredients before generating a recipe.',
      );
    }

    if (sanitized.length > maxRecipeIngredientCount) {
      throw CulinexSessionException(
        'Use no more than $maxRecipeIngredientCount ingredients for one recipe.',
      );
    }

    return List<ExtractedIngredient>.unmodifiable(sanitized);
  }

  void _setError(Object error, {required String fallbackMessage}) {
    _errorMessage = switch (error) {
      CulinexApiException apiException => apiException.message,
      CulinexSessionException sessionException => sessionException.message,
      _ => fallbackMessage,
    };
    _stage = SessionStage.error;
    _notifySafely();
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _repository.close();
    super.dispose();
  }
}

class CulinexSessionException implements Exception {
  const CulinexSessionException(this.message);

  final String message;

  @override
  String toString() => message;
}
