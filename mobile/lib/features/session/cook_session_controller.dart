import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../core/network/culinex_api_client.dart';
import '../../core/localization/app_locale.dart';
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

enum IngredientEntryMethod { photo, manual }

enum SessionErrorCode {
  unknown,
  noClearIngredientsDetected,
  couldNotRecognizePhoto,
  tooFewIngredients,
  tooManyIngredients,
  recipeGenerationFailed,
  networkUnavailable,
  requestTimedOut,
  invalidImageFile,
  unexpectedResponse,
}

class SessionErrorState {
  const SessionErrorState(this.code, {this.count, this.operation});

  final SessionErrorCode code;
  final int? count;
  final SessionOperation? operation;
}

class CookSessionController extends ChangeNotifier {
  CookSessionController({required CulinexRepository repository})
    : _repository = repository;

  final CulinexRepository _repository;

  SessionStage _stage = SessionStage.welcome;
  SessionOperation _lastOperation = SessionOperation.none;
  IngredientEntryMethod _ingredientEntryMethod = IngredientEntryMethod.photo;
  String? _capturedImagePath;
  List<ExtractedIngredient> _ingredients = const [];
  bool _assumeBasicStaples = true;
  GeneratedRecipe? _recipe;
  SessionErrorState? _errorState;
  Locale _locale = AppLocale.english;
  bool _isDisposed = false;

  SessionStage get stage => _stage;
  SessionOperation get lastOperation => _lastOperation;
  String? get capturedImagePath => _capturedImagePath;
  List<ExtractedIngredient> get ingredients => _ingredients;
  bool get assumeBasicStaples => _assumeBasicStaples;
  bool get isManualIngredientEntry =>
      _ingredientEntryMethod == IngredientEntryMethod.manual;
  GeneratedRecipe? get recipe => _recipe;
  SessionErrorState get errorState =>
      _errorState ?? const SessionErrorState(SessionErrorCode.unknown);

  void setLocale(Locale locale) {
    _locale = AppLocale.normalize(locale);
  }

  void showWelcome() {
    _stage = SessionStage.welcome;
    _errorState = null;
    _notifySafely();
  }

  void openCamera() {
    _ingredientEntryMethod = IngredientEntryMethod.photo;
    _stage = SessionStage.camera;
    _errorState = null;
    _notifySafely();
  }

  void startManualIngredientEntry() {
    _ingredientEntryMethod = IngredientEntryMethod.manual;
    _capturedImagePath = null;
    _ingredients = const [];
    _assumeBasicStaples = true;
    _recipe = null;
    _errorState = null;
    _lastOperation = SessionOperation.none;
    _stage = SessionStage.ingredients;
    _notifySafely();
  }

  void showIngredients() {
    if (_ingredients.isEmpty && !isManualIngredientEntry) {
      openCamera();
      return;
    }

    _stage = SessionStage.ingredients;
    _errorState = null;
    _notifySafely();
  }

  void showRecipe() {
    if (_recipe == null) {
      showIngredients();
      return;
    }

    _stage = SessionStage.recipe;
    _errorState = null;
    _notifySafely();
  }

  void resetSession() {
    _ingredientEntryMethod = IngredientEntryMethod.photo;
    _capturedImagePath = null;
    _ingredients = const [];
    _assumeBasicStaples = true;
    _recipe = null;
    _errorState = null;
    _lastOperation = SessionOperation.none;
    _stage = SessionStage.welcome;
    _notifySafely();
  }

  void retakePhoto() {
    _ingredientEntryMethod = IngredientEntryMethod.photo;
    _capturedImagePath = null;
    _ingredients = const [];
    _assumeBasicStaples = true;
    _recipe = null;
    _errorState = null;
    _stage = SessionStage.camera;
    _notifySafely();
  }

  void leaveIngredientEntry() {
    if (isManualIngredientEntry) {
      resetSession();
      return;
    }

    retakePhoto();
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
    _ingredientEntryMethod = IngredientEntryMethod.photo;
    _capturedImagePath = imagePath;
    _ingredients = const [];
    _assumeBasicStaples = true;
    _recipe = null;
    _errorState = null;
    _lastOperation = SessionOperation.extractIngredients;
    _stage = SessionStage.extracting;
    _notifySafely();

    try {
      final List<ExtractedIngredient> extractedIngredients = await _repository
          .extractIngredients(File(imagePath), locale: _locale);

      if (_isDisposed) {
        return;
      }

      if (extractedIngredients.isEmpty) {
        throw const CulinexSessionException(
          SessionErrorState(SessionErrorCode.noClearIngredientsDetected),
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
        fallbackError: const SessionErrorState(
          SessionErrorCode.couldNotRecognizePhoto,
        ),
      );
    }
  }

  Future<void> generateRecipe() async {
    if (_ingredients.length < minRecipeIngredientCount) {
      _setError(
        const CulinexSessionException(
          SessionErrorState(
            SessionErrorCode.tooFewIngredients,
            count: minRecipeIngredientCount,
          ),
        ),
        fallbackError: const SessionErrorState(
          SessionErrorCode.tooFewIngredients,
          count: minRecipeIngredientCount,
        ),
      );
      return;
    }

    if (_ingredients.length > maxRecipeIngredientCount) {
      _setError(
        CulinexSessionException(
          SessionErrorState(
            SessionErrorCode.tooManyIngredients,
            count: maxRecipeIngredientCount,
          ),
        ),
        fallbackError: const SessionErrorState(
          SessionErrorCode.tooManyIngredients,
          count: maxRecipeIngredientCount,
        ),
      );
      return;
    }

    _errorState = null;
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
        locale: _locale,
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
        fallbackError: const SessionErrorState(
          SessionErrorCode.recipeGenerationFailed,
        ),
      );
    }
  }

  Future<void> generateRecipeFromIngredients(
    List<ExtractedIngredient> ingredients,
    bool assumeBasicStaples,
  ) async {
    _lastOperation = SessionOperation.generateRecipe;

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
        fallbackError: const SessionErrorState(
          SessionErrorCode.recipeGenerationFailed,
        ),
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
        SessionErrorState(
          SessionErrorCode.tooFewIngredients,
          count: minRecipeIngredientCount,
        ),
      );
    }

    if (sanitized.length > maxRecipeIngredientCount) {
      throw CulinexSessionException(
        const SessionErrorState(
          SessionErrorCode.tooManyIngredients,
          count: maxRecipeIngredientCount,
        ),
      );
    }

    return List<ExtractedIngredient>.unmodifiable(sanitized);
  }

  void _setError(Object error, {required SessionErrorState fallbackError}) {
    _errorState = switch (error) {
      CulinexApiException apiException => _mapApiError(
        apiException,
        fallbackError,
      ),
      CulinexSessionException sessionException => sessionException.error,
      _ => fallbackError,
    };
    _stage = SessionStage.error;
    _notifySafely();
  }

  SessionErrorState _mapApiError(
    CulinexApiException error,
    SessionErrorState fallbackError,
  ) {
    return switch (error.code) {
      CulinexApiErrorCode.invalidImageFile => const SessionErrorState(
        SessionErrorCode.invalidImageFile,
      ),
      CulinexApiErrorCode.requestTimedOut => SessionErrorState(
        SessionErrorCode.requestTimedOut,
        operation: _lastOperation,
      ),
      CulinexApiErrorCode.networkUnavailable => const SessionErrorState(
        SessionErrorCode.networkUnavailable,
      ),
      CulinexApiErrorCode.unexpectedResponse => const SessionErrorState(
        SessionErrorCode.unexpectedResponse,
      ),
      CulinexApiErrorCode.serverFailure => fallbackError,
    };
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
  const CulinexSessionException(this.error);

  final SessionErrorState error;

  @override
  String toString() => error.code.name;
}
