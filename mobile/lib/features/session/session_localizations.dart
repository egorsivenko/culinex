import 'culinex_models.dart';
import 'cook_session_controller.dart';
import '../../l10n/app_localizations.dart';

extension IngredientConfidenceLocalization on IngredientConfidence {
  String label(AppLocalizations l10n) => switch (this) {
    IngredientConfidence.high => l10n.ingredientConfidenceHigh,
    IngredientConfidence.medium => l10n.ingredientConfidenceMedium,
    IngredientConfidence.low => l10n.ingredientConfidenceLow,
  };
}

extension RecipeDifficultyLocalization on RecipeDifficulty {
  String label(AppLocalizations l10n) => switch (this) {
    RecipeDifficulty.easy => l10n.recipeDifficultyEasy,
    RecipeDifficulty.medium => l10n.recipeDifficultyMedium,
    RecipeDifficulty.hard => l10n.recipeDifficultyHard,
  };
}

String localizeSessionErrorTitle(
  AppLocalizations l10n,
  SessionOperation operation,
) {
  return switch (operation) {
    SessionOperation.extractIngredients => l10n.sessionErrorIngredientScanTitle,
    SessionOperation.generateRecipe => l10n.sessionErrorRecipeGenerationTitle,
    SessionOperation.none => l10n.sessionErrorUnknownTitle,
  };
}

String localizeSessionPrimaryActionLabel(
  AppLocalizations l10n,
  SessionOperation operation,
) {
  return switch (operation) {
    SessionOperation.none => l10n.sessionErrorActionStartOver,
    SessionOperation.extractIngredients => l10n.sessionErrorActionRetakePhoto,
    SessionOperation.generateRecipe =>
      l10n.sessionErrorActionTryGeneratingAgain,
  };
}

String localizeSessionSecondaryActionLabel(
  AppLocalizations l10n,
  SessionOperation operation,
) {
  return switch (operation) {
    SessionOperation.extractIngredients => l10n.sessionErrorActionReturnHome,
    SessionOperation.generateRecipe => l10n.sessionErrorActionBackToIngredients,
    SessionOperation.none => l10n.sessionErrorActionHome,
  };
}

String localizeSessionErrorMessage(
  AppLocalizations l10n,
  SessionErrorState error,
) {
  return switch (error.code) {
    SessionErrorCode.unknown => l10n.sessionErrorUnknownMessage,
    SessionErrorCode.noClearIngredientsDetected =>
      l10n.sessionErrorNoClearIngredients,
    SessionErrorCode.couldNotRecognizePhoto =>
      l10n.sessionErrorCouldNotRecognizePhoto,
    SessionErrorCode.tooFewIngredients => l10n.sessionErrorTooFewIngredients(
      error.count ?? minRecipeIngredientCount,
    ),
    SessionErrorCode.tooManyIngredients => l10n.sessionErrorTooManyIngredients(
      error.count ?? maxRecipeIngredientCount,
    ),
    SessionErrorCode.recipeGenerationFailed =>
      l10n.sessionErrorRecipeGenerationMessage,
    SessionErrorCode.networkUnavailable => l10n.sessionErrorNetworkUnavailable,
    SessionErrorCode.requestTimedOut => switch (error.operation) {
      SessionOperation.generateRecipe => l10n.sessionErrorRequestTimedOutRecipe,
      _ => l10n.sessionErrorRequestTimedOutScan,
    },
    SessionErrorCode.invalidImageFile => l10n.sessionErrorInvalidImageFile,
    SessionErrorCode.unexpectedResponse => l10n.sessionErrorUnexpectedResponse,
  };
}
