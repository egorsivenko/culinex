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

enum RecipeHistoryStatus { initial, loading, loaded, error }

enum SessionErrorCode {
  unknown,
  noClearIngredientsDetected,
  couldNotRecognizePhoto,
  tooFewIngredients,
  tooManyIngredients,
  invalidIngredients,
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
  RecipeStyle _recipeStyle = RecipeStyle.everyday;
  GeneratedRecipe? _recipe;
  List<RecipeSummary> _recipeSummaries = const [];
  List<RecipeCollection> _recipeCollections = const [];
  RecipeHistoryStatus _recipeHistoryStatus = RecipeHistoryStatus.initial;
  bool _isOpeningSavedRecipe = false;
  bool _recipeOpenedFromHistory = false;
  String? _selectedRecipeActionId;
  String? _deletingRecipeId;
  String? _favoritingRecipeId;
  String? _movingRecipeId;
  String? _deletingCollectionId;
  bool _isDeletingAllRecipes = false;
  SessionErrorState? _errorState;
  Locale _locale = AppLocale.english;
  bool _isDisposed = false;

  SessionStage get stage => _stage;
  SessionOperation get lastOperation => _lastOperation;
  String? get capturedImagePath => _capturedImagePath;
  List<ExtractedIngredient> get ingredients => _ingredients;
  bool get assumeBasicStaples => _assumeBasicStaples;
  RecipeStyle get recipeStyle => _recipeStyle;
  bool get isManualIngredientEntry =>
      _ingredientEntryMethod == IngredientEntryMethod.manual;
  GeneratedRecipe? get recipe => _recipe;
  List<RecipeSummary> get recipeSummaries => _recipeSummaries;
  List<RecipeCollection> get recipeCollections => _recipeCollections;
  RecipeHistoryStatus get recipeHistoryStatus => _recipeHistoryStatus;
  bool get isOpeningSavedRecipe => _isOpeningSavedRecipe;
  bool get recipeOpenedFromHistory => _recipeOpenedFromHistory;
  String? get selectedRecipeActionId => _selectedRecipeActionId;
  String? get deletingRecipeId => _deletingRecipeId;
  String? get favoritingRecipeId => _favoritingRecipeId;
  String? get movingRecipeId => _movingRecipeId;
  String? get deletingCollectionId => _deletingCollectionId;
  bool get isDeletingAllRecipes => _isDeletingAllRecipes;
  SessionErrorState get errorState =>
      _errorState ?? const SessionErrorState(SessionErrorCode.unknown);

  void setLocale(Locale locale) {
    _locale = AppLocale.normalize(locale);
  }

  void showWelcome() {
    _stage = SessionStage.welcome;
    _errorState = null;
    _selectedRecipeActionId = null;
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
    _recipeStyle = RecipeStyle.everyday;
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

  void showRecipeHistory() {
    _stage = SessionStage.welcome;
    _errorState = null;
    _recipeOpenedFromHistory = false;
    _selectedRecipeActionId = null;
    _notifySafely();
  }

  void resetSession() {
    _ingredientEntryMethod = IngredientEntryMethod.photo;
    _capturedImagePath = null;
    _ingredients = const [];
    _assumeBasicStaples = true;
    _recipeStyle = RecipeStyle.everyday;
    _recipe = null;
    _recipeOpenedFromHistory = false;
    _selectedRecipeActionId = null;
    _deletingRecipeId = null;
    _favoritingRecipeId = null;
    _movingRecipeId = null;
    _deletingCollectionId = null;
    _isDeletingAllRecipes = false;
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
    _recipeStyle = RecipeStyle.everyday;
    _recipe = null;
    _recipeOpenedFromHistory = false;
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
    _recipeStyle = RecipeStyle.everyday;
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
          recipeStyle: _recipeStyle,
        ),
        locale: _locale,
      );

      if (_isDisposed) {
        return;
      }

      _recipe = nextRecipe;
      _recipeOpenedFromHistory = false;
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

  Future<void> loadRecipeHistory({bool force = false}) async {
    if (_recipeHistoryStatus == RecipeHistoryStatus.loading) {
      return;
    }
    if (!force && _recipeHistoryStatus == RecipeHistoryStatus.loaded) {
      return;
    }

    _recipeHistoryStatus = RecipeHistoryStatus.loading;
    _notifySafely();

    try {
      final List<RecipeSummary> summaries = await _repository.listRecipes();
      final List<RecipeCollection> collections = await _repository
          .listRecipeCollections();
      if (_isDisposed) {
        return;
      }

      _recipeSummaries = _sortRecipeSummaries(summaries);
      _recipeCollections = _sortRecipeCollections(collections);
      if (!_recipeSummaries.any(
        (summary) => summary.id == _selectedRecipeActionId,
      )) {
        _selectedRecipeActionId = null;
      }
      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      _notifySafely();
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      _recipeHistoryStatus = RecipeHistoryStatus.error;
      _notifySafely();
    }
  }

  Future<void> openSavedRecipe(String id) async {
    if (_isOpeningSavedRecipe || _deletingRecipeId != null) {
      return;
    }

    _isOpeningSavedRecipe = true;
    _selectedRecipeActionId = null;
    _notifySafely();

    try {
      final GeneratedRecipe savedRecipe = await _repository.getRecipe(id);
      if (_isDisposed) {
        return;
      }

      _recipe = savedRecipe;
      _recipeOpenedFromHistory = true;
      _isOpeningSavedRecipe = false;
      _errorState = null;
      _stage = SessionStage.recipe;
      _notifySafely();
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      _isOpeningSavedRecipe = false;
      _recipeHistoryStatus = RecipeHistoryStatus.error;
      _notifySafely();
    }
  }

  void selectRecipeActions(String id) {
    if (_deletingRecipeId != null || _movingRecipeId != null) {
      return;
    }

    _selectedRecipeActionId = id;
    _notifySafely();
  }

  void clearRecipeActions() {
    if (_selectedRecipeActionId == null ||
        _deletingRecipeId != null ||
        _favoritingRecipeId != null ||
        _movingRecipeId != null) {
      return;
    }

    _selectedRecipeActionId = null;
    _notifySafely();
  }

  Future<bool> setRecipeFavorite(String id, bool isFavorite) async {
    if (_favoritingRecipeId != null ||
        _deletingRecipeId != null ||
        _movingRecipeId != null) {
      return false;
    }

    final List<RecipeSummary> previousSummaries = _recipeSummaries;
    final GeneratedRecipe? previousRecipe = _recipe;
    final String? previousSelectedRecipeActionId = _selectedRecipeActionId;
    final int summaryIndex = previousSummaries.indexWhere(
      (summary) => summary.id == id,
    );
    if (summaryIndex == -1) {
      return false;
    }

    _favoritingRecipeId = id;
    _selectedRecipeActionId = null;
    _recipeSummaries = _sortRecipeSummaries(
      previousSummaries.map((summary) {
        if (summary.id != id) {
          return summary;
        }
        return summary.copyWith(isFavorite: isFavorite);
      }),
    );
    if (_recipe?.id == id) {
      _recipe = _recipe?.copyWith(isFavorite: isFavorite);
    }
    _recipeHistoryStatus = RecipeHistoryStatus.loaded;
    _notifySafely();

    try {
      await _repository.setRecipeFavorite(id, isFavorite);
      if (_isDisposed) {
        return false;
      }

      _favoritingRecipeId = null;
      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      _notifySafely();
      return true;
    } catch (_) {
      if (_isDisposed) {
        return false;
      }

      _recipeSummaries = previousSummaries;
      _recipe = previousRecipe;
      _selectedRecipeActionId = previousSelectedRecipeActionId;
      _favoritingRecipeId = null;
      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      _notifySafely();
      return false;
    }
  }

  Future<bool> createRecipeCollection(String name) async {
    if (_deletingCollectionId != null || _isDeletingAllRecipes) {
      return false;
    }

    try {
      final RecipeCollection collection = await _repository
          .createRecipeCollection(name);
      if (_isDisposed) {
        return false;
      }

      _recipeCollections = _sortRecipeCollections(<RecipeCollection>[
        collection,
        ..._recipeCollections,
      ]);
      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      _notifySafely();
      return true;
    } catch (_) {
      if (_isDisposed) {
        return false;
      }

      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      _notifySafely();
      return false;
    }
  }

  Future<bool> renameRecipeCollection(String id, String name) async {
    if (_deletingCollectionId != null || _isDeletingAllRecipes) {
      return false;
    }

    try {
      final RecipeCollection collection = await _repository
          .renameRecipeCollection(id, name);
      if (_isDisposed) {
        return false;
      }

      _recipeCollections = _sortRecipeCollections(
        _recipeCollections.map((item) => item.id == id ? collection : item),
      );
      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      _notifySafely();
      return true;
    } catch (_) {
      if (_isDisposed) {
        return false;
      }

      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      _notifySafely();
      return false;
    }
  }

  Future<bool> deleteRecipeCollection(String id) async {
    if (_deletingCollectionId != null || _isDeletingAllRecipes) {
      return false;
    }

    final List<RecipeCollection> previousCollections = _recipeCollections;
    final List<RecipeSummary> previousSummaries = _recipeSummaries;
    final GeneratedRecipe? previousRecipe = _recipe;

    _deletingCollectionId = id;
    _notifySafely();

    try {
      await _repository.deleteRecipeCollection(id);
      if (_isDisposed) {
        return false;
      }

      _recipeCollections = List<RecipeCollection>.unmodifiable(
        _recipeCollections.where((collection) => collection.id != id),
      );
      _recipeSummaries = _sortRecipeSummaries(
        _recipeSummaries.map((summary) {
          if (summary.collectionId != id) {
            return summary;
          }
          return summary.copyWith(clearCollectionId: true);
        }),
      );
      if (_recipe?.collectionId == id) {
        _recipe = _recipe?.copyWith(clearCollectionId: true);
      }
      _selectedRecipeActionId = null;
      _deletingCollectionId = null;
      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      _notifySafely();
      return true;
    } catch (_) {
      if (_isDisposed) {
        return false;
      }

      _recipeCollections = previousCollections;
      _recipeSummaries = previousSummaries;
      _recipe = previousRecipe;
      _deletingCollectionId = null;
      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      _notifySafely();
      return false;
    }
  }

  Future<bool> setRecipeCollection(String id, String? collectionId) async {
    if (_favoritingRecipeId != null ||
        _deletingRecipeId != null ||
        _movingRecipeId != null ||
        _isDeletingAllRecipes) {
      return false;
    }

    final List<RecipeSummary> previousSummaries = _recipeSummaries;
    final GeneratedRecipe? previousRecipe = _recipe;
    final String? previousSelectedRecipeActionId = _selectedRecipeActionId;
    final int summaryIndex = previousSummaries.indexWhere(
      (summary) => summary.id == id,
    );
    if (summaryIndex == -1) {
      return false;
    }

    _movingRecipeId = id;
    _selectedRecipeActionId = null;
    _recipeSummaries = _sortRecipeSummaries(
      previousSummaries.map((summary) {
        if (summary.id != id) {
          return summary;
        }
        return summary.copyWith(
          collectionId: collectionId,
          clearCollectionId: collectionId == null,
        );
      }),
    );
    if (_recipe?.id == id) {
      _recipe = _recipe?.copyWith(
        collectionId: collectionId,
        clearCollectionId: collectionId == null,
      );
    }
    _recipeHistoryStatus = RecipeHistoryStatus.loaded;
    _notifySafely();

    try {
      await _repository.setRecipeCollection(id, collectionId);
      if (_isDisposed) {
        return false;
      }

      _movingRecipeId = null;
      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      _notifySafely();
      return true;
    } catch (_) {
      if (_isDisposed) {
        return false;
      }

      _recipeSummaries = previousSummaries;
      _recipe = previousRecipe;
      _selectedRecipeActionId = previousSelectedRecipeActionId;
      _movingRecipeId = null;
      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      _notifySafely();
      return false;
    }
  }

  Future<bool> deleteRecipe(String id) async {
    if (_deletingRecipeId != null ||
        _favoritingRecipeId != null ||
        _movingRecipeId != null ||
        _isDeletingAllRecipes) {
      return false;
    }

    _deletingRecipeId = id;
    _notifySafely();

    try {
      await _repository.deleteRecipe(id);
      if (_isDisposed) {
        return false;
      }

      _recipeSummaries = List<RecipeSummary>.unmodifiable(
        _recipeSummaries.where((summary) => summary.id != id),
      );
      _selectedRecipeActionId = null;
      _deletingRecipeId = null;
      _recipeHistoryStatus = RecipeHistoryStatus.loaded;

      if (_recipeOpenedFromHistory && _recipe?.id == id) {
        _recipe = null;
        _recipeOpenedFromHistory = false;
        _stage = SessionStage.welcome;
      }

      _notifySafely();
      return true;
    } catch (_) {
      if (_isDisposed) {
        return false;
      }

      _deletingRecipeId = null;
      _recipeHistoryStatus = RecipeHistoryStatus.error;
      _notifySafely();
      return false;
    }
  }

  Future<bool> deleteAllRecipes() async {
    if (_deletingRecipeId != null ||
        _favoritingRecipeId != null ||
        _movingRecipeId != null ||
        _isDeletingAllRecipes) {
      return false;
    }

    final List<RecipeSummary> previousSummaries = _recipeSummaries;
    final List<RecipeCollection> previousCollections = _recipeCollections;
    final GeneratedRecipe? previousRecipe = _recipe;
    final bool previousRecipeOpenedFromHistory = _recipeOpenedFromHistory;
    final String? previousSelectedRecipeActionId = _selectedRecipeActionId;
    final RecipeHistoryStatus previousRecipeHistoryStatus =
        _recipeHistoryStatus;
    final SessionStage previousStage = _stage;

    _isDeletingAllRecipes = true;
    _notifySafely();

    try {
      await _repository.deleteAllRecipes();
      if (_isDisposed) {
        return false;
      }

      _recipeSummaries = const [];
      _recipeCollections = const [];
      _selectedRecipeActionId = null;
      _recipeHistoryStatus = RecipeHistoryStatus.loaded;
      if (_recipe?.id != null) {
        _recipe = null;
        _recipeOpenedFromHistory = false;
        if (_stage == SessionStage.recipe) {
          _stage = SessionStage.welcome;
        }
      }
      _isDeletingAllRecipes = false;
      _notifySafely();
      return true;
    } catch (_) {
      if (_isDisposed) {
        return false;
      }

      _recipeSummaries = previousSummaries;
      _recipeCollections = previousCollections;
      _recipe = previousRecipe;
      _recipeOpenedFromHistory = previousRecipeOpenedFromHistory;
      _selectedRecipeActionId = previousSelectedRecipeActionId;
      _recipeHistoryStatus = previousRecipeHistoryStatus;
      _stage = previousStage;
      _isDeletingAllRecipes = false;
      _notifySafely();
      return false;
    }
  }

  List<RecipeSummary> _sortRecipeSummaries(Iterable<RecipeSummary> summaries) {
    final List<RecipeSummary> sorted = summaries.toList(growable: false);
    sorted.sort((RecipeSummary a, RecipeSummary b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }

      final DateTime? aCreatedAt = a.createdAt;
      final DateTime? bCreatedAt = b.createdAt;
      if (aCreatedAt == null && bCreatedAt == null) {
        return 0;
      }
      if (aCreatedAt == null) {
        return 1;
      }
      if (bCreatedAt == null) {
        return -1;
      }
      return bCreatedAt.compareTo(aCreatedAt);
    });
    return List<RecipeSummary>.unmodifiable(sorted);
  }

  List<RecipeCollection> _sortRecipeCollections(
    Iterable<RecipeCollection> collections,
  ) {
    final List<RecipeCollection> sorted = collections.toList(growable: false);
    sorted.sort((RecipeCollection a, RecipeCollection b) {
      final DateTime? aCreatedAt = a.createdAt;
      final DateTime? bCreatedAt = b.createdAt;
      if (aCreatedAt == null && bCreatedAt == null) {
        return 0;
      }
      if (aCreatedAt == null) {
        return 1;
      }
      if (bCreatedAt == null) {
        return -1;
      }
      return bCreatedAt.compareTo(aCreatedAt);
    });
    return List<RecipeCollection>.unmodifiable(sorted);
  }

  Future<void> generateRecipeFromIngredients(
    List<ExtractedIngredient> ingredients,
    bool assumeBasicStaples,
    RecipeStyle recipeStyle,
  ) async {
    _lastOperation = SessionOperation.generateRecipe;

    try {
      _ingredients = _prepareIngredients(ingredients);
      _assumeBasicStaples = assumeBasicStaples;
      _recipeStyle = recipeStyle;
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
      CulinexApiErrorCode.invalidIngredients => const SessionErrorState(
        SessionErrorCode.invalidIngredients,
      ),
      CulinexApiErrorCode.requestTimedOut => SessionErrorState(
        SessionErrorCode.requestTimedOut,
        operation: _lastOperation,
      ),
      CulinexApiErrorCode.networkUnavailable => const SessionErrorState(
        SessionErrorCode.networkUnavailable,
      ),
      CulinexApiErrorCode.unauthorized => fallbackError,
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
