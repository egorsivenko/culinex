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
  GeneratedRecipe? _recipe;
  String? _errorMessage;
  bool _isDisposed = false;

  SessionStage get stage => _stage;
  String? get capturedImagePath => _capturedImagePath;
  List<ExtractedIngredient> get ingredients => _ingredients;
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
    SessionOperation.extractIngredients => 'Try scan again',
    SessionOperation.generateRecipe => 'Try generating again',
  };

  String get secondaryErrorActionLabel => switch (_lastOperation) {
    SessionOperation.extractIngredients => 'Retake photo',
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
    _recipe = null;
    _errorMessage = null;
    _lastOperation = SessionOperation.none;
    _stage = SessionStage.welcome;
    _notifySafely();
  }

  void retakePhoto() {
    _ingredients = const [];
    _recipe = null;
    _errorMessage = null;
    _stage = SessionStage.camera;
    _notifySafely();
  }

  void performErrorSecondaryAction() {
    switch (_lastOperation) {
      case SessionOperation.extractIngredients:
        retakePhoto();
        return;
      case SessionOperation.generateRecipe:
        showIngredients();
        return;
      case SessionOperation.none:
        resetSession();
        return;
    }
  }

  Future<void> retryLastAction() async {
    switch (_lastOperation) {
      case SessionOperation.extractIngredients:
        final String? imagePath = _capturedImagePath;
        if (imagePath != null) {
          await extractIngredientsFromPhoto(imagePath);
        }
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
    if (_ingredients.isEmpty) {
      return;
    }

    _errorMessage = null;
    _lastOperation = SessionOperation.generateRecipe;
    _stage = SessionStage.generatingRecipe;
    _notifySafely();

    try {
      final GeneratedRecipe nextRecipe = await _repository.generateRecipe(
        _ingredients.map((item) => item.toRecipeIngredient()).toList(),
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
