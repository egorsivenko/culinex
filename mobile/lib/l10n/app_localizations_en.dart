// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageEnglishShort => 'EN';

  @override
  String get languageUkrainianShort => 'УКР';

  @override
  String get switchToLightMode => 'Switch to light mode';

  @override
  String get switchToDarkMode => 'Switch to dark mode';

  @override
  String get switchToEnglish => 'Switch to English';

  @override
  String get switchToUkrainian => 'Switch to Ukrainian';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutDialogTitle => 'Sign out?';

  @override
  String get signOutDialogMessage =>
      'You will need to sign in again to access your saved recipes and settings.';

  @override
  String get signOutDialogConfirm => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get mainTabLabel => 'Home';

  @override
  String get myRecipesTabLabel => 'My recipes';

  @override
  String get settingsTabLabel => 'Settings';

  @override
  String get myRecipesTitle => 'My recipes';

  @override
  String get myRecipesEmptyTitle => 'No saved recipes yet';

  @override
  String get myRecipesEmptyMessage => 'Generated recipes will appear here.';

  @override
  String get myRecipesLoadFailedTitle => 'Recipes could not be loaded';

  @override
  String get myRecipesLoadFailedMessage =>
      'Check your connection and try again.';

  @override
  String get myRecipesRetry => 'Retry';

  @override
  String get recipeCollectionRecents => 'Recents';

  @override
  String get createRecipeCollectionTooltip => 'Create collection';

  @override
  String get createRecipeCollectionTitle => 'New collection';

  @override
  String get renameRecipeCollectionTitle => 'Rename collection';

  @override
  String get recipeCollectionNameLabel => 'Collection name';

  @override
  String get recipeCollectionNameRequired => 'Enter a collection name.';

  @override
  String get recipeCollectionNameDuplicate =>
      'A collection with this name already exists.';

  @override
  String get createRecipeCollectionAction => 'Create';

  @override
  String get renameRecipeCollectionAction => 'Save';

  @override
  String get recipeCollectionCreateFailed =>
      'Collection could not be created. Try again.';

  @override
  String get recipeCollectionRenameFailed =>
      'Collection could not be renamed. Try again.';

  @override
  String get recipeCollectionDeleteFailed =>
      'Collection could not be deleted. Try again.';

  @override
  String get deleteRecipeCollection => 'Delete collection';

  @override
  String get renameRecipeCollection => 'Rename collection';

  @override
  String get deleteRecipeCollectionDialogTitle => 'Delete collection?';

  @override
  String get deleteRecipeCollectionDialogMessage =>
      'Recipes in this collection will move to Recents.';

  @override
  String get deleteRecipeCollectionDialogConfirm => 'Delete collection';

  @override
  String recipeCollectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
      zero: 'No recipes',
    );
    return '$_temp0';
  }

  @override
  String get addRecipeToCollection => 'Add to collection';

  @override
  String get moveRecipe => 'Move recipe';

  @override
  String get moveRecipeToRecents => 'Move to Recents';

  @override
  String get recipeCollectionMoveFailed =>
      'Recipe could not be moved. Try again.';

  @override
  String get noRecipeCollectionsYet => 'No collections yet';

  @override
  String get favoriteRecipe => 'Favorite';

  @override
  String get unfavoriteRecipe => 'Unfavorite';

  @override
  String get favoriteRecipeFailed =>
      'Favorite status could not be updated. Try again.';

  @override
  String get deleteRecipe => 'Delete';

  @override
  String get deleteRecipeDialogTitle => 'Delete recipe?';

  @override
  String get deleteRecipeDialogMessage =>
      'This recipe will be permanently deleted.';

  @override
  String get deleteRecipeDialogConfirm => 'Delete recipe';

  @override
  String get deleteRecipeFailed => 'Recipe could not be deleted. Try again.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsAppearanceLabel => 'Theme';

  @override
  String get settingsVibrationsLabel => 'Vibrations';

  @override
  String get settingsSoundsLabel => 'Sounds';

  @override
  String get settingsLightOption => 'Light';

  @override
  String get settingsDarkOption => 'Dark';

  @override
  String get deleteAllRecipes => 'Delete all data';

  @override
  String get deleteAllRecipesDialogTitle => 'Delete all data?';

  @override
  String get deleteAllRecipesDialogMessage =>
      'All saved recipes and collections will be permanently deleted.';

  @override
  String get deleteAllRecipesDialogConfirm => 'Delete all data';

  @override
  String get deleteAllRecipesFailed => 'Data could not be deleted. Try again.';

  @override
  String get deleteAccountDialogTitle => 'Delete account?';

  @override
  String get deleteAccountDialogMessage =>
      'Deleting your account is permanent and cannot be undone.';

  @override
  String get deleteAccountDialogInstruction => 'Type DELETE to confirm.';

  @override
  String get deleteAccountDialogConfirm => 'Delete account';

  @override
  String get welcomePhrase1 => 'Turn ingredients into flavor.';

  @override
  String get welcomePhrase2 => 'Snap your ingredients. Get a recipe.';

  @override
  String get welcomePhrase3 => 'Your next meal starts with a photo.';

  @override
  String get welcomePhrase4 => 'Got ingredients? We\'ve got ideas.';

  @override
  String get welcomePhrase5 => 'Cook more with what you have.';

  @override
  String get welcomePhrase6 => 'Snap a photo. Start cooking.';

  @override
  String get welcomePhrase7 => 'Let\'s cook something great today.';

  @override
  String get welcomePhrase8 => 'Your kitchen has endless potential.';

  @override
  String get welcomePhrase9 => 'Your kitchen has hidden potential.';

  @override
  String get welcomePhrase10 => 'Recipe ideas from one photo.';

  @override
  String get welcomePhrase11 => 'Smart cooking starts here.';

  @override
  String get takePhotoTitle => 'Take a photo';

  @override
  String get takePhotoDescription =>
      'Scan the ingredients you already have and turn them into a recipe.';

  @override
  String get useCamera => 'Use the camera';

  @override
  String get enterIngredientsManuallyTitle => 'Type ingredients';

  @override
  String get enterIngredientsManuallyDescription =>
      'Enter your ingredients manually and go straight to recipe generation.';

  @override
  String get typeIngredients => 'Type ingredients';

  @override
  String get welcomeDescription =>
      'Scan ingredients with your camera or type them in to get a recipe in seconds.';

  @override
  String get choiceSeparatorOr => 'or';

  @override
  String get cameraNoDevice => 'No camera is available on this device.';

  @override
  String get cameraFlashUnavailable => 'Flash is not available on this device.';

  @override
  String get cameraSelectedPhotoOpenFailed =>
      'The selected photo could not be opened. Please try another image.';

  @override
  String get cameraPermissionDenied =>
      'Camera permission was denied. Enable it in system settings.';

  @override
  String get cameraAccessRestricted =>
      'Camera access is restricted on this device.';

  @override
  String get cameraMicrophoneDenied => 'Microphone access was denied.';

  @override
  String get cameraStartFailed =>
      'The camera could not be started. Please try again.';

  @override
  String get cameraShowFrameHintTooltip => 'Show frame hint';

  @override
  String get cameraInfoPopupText => 'Place the ingredients in the frame';

  @override
  String get scanLoadingBadge => 'Scanning ingredients';

  @override
  String get scanLoadingTitle => 'Recognizing ingredients...';

  @override
  String get scanLoadingDescription =>
      'The app is checking what is visible in the photo and estimating the product quantities before recipe creation.';

  @override
  String get ingredientConfidenceHigh => 'High confidence';

  @override
  String get ingredientConfidenceMedium => 'Medium confidence';

  @override
  String get ingredientConfidenceLow => 'Low confidence';

  @override
  String get ingredientStatusScanned => 'Scan complete';

  @override
  String get ingredientStatusManual => 'Manual entry';

  @override
  String get ingredientReviewScannedTitle => 'Review and adjust the list';

  @override
  String get ingredientReviewManualTitle => 'Add your ingredients';

  @override
  String get ingredientReviewScannedDescription =>
      'Add missing ingredients, edit names or quantities, or swipe left to remove anything irrelevant before recipe generation.';

  @override
  String get ingredientReviewManualDescription =>
      'Start from scratch, add clear ingredient names and practical quantities, then generate a recipe when the list looks right.';

  @override
  String get proceed => 'Proceed';

  @override
  String get returnToRecipe => 'Return to recipe';

  @override
  String get generateAgainHint =>
      'Generate again to refresh the recipe after editing this list.';

  @override
  String get viewOriginalPhoto => 'View original photo';

  @override
  String get recipeStyleTitle => 'Recipe style';

  @override
  String get recipeStyleEveryday => 'Everyday';

  @override
  String get recipeStyleProfessional => 'Professional';

  @override
  String get recipeStyleCreative => 'Creative';

  @override
  String get assumeBasicStaplesTitle => 'Assume basic staples are available';

  @override
  String ingredientCountStatus(int current, int max) {
    return '$current / $max ingredients';
  }

  @override
  String get addIngredient => 'Add ingredient';

  @override
  String deleteIngredientTooltip(Object name) {
    return 'Delete $name';
  }

  @override
  String editIngredientTooltip(Object name) {
    return 'Edit $name';
  }

  @override
  String get editedBadge => 'Edited';

  @override
  String addMoreIngredientsToGenerate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add at least $count more ingredients to continue.',
      one: 'Add 1 more ingredient to continue.',
    );
    return '$_temp0';
  }

  @override
  String addAtLeastIngredientsToContinue(int count) {
    return 'Add at least $count ingredients to continue.';
  }

  @override
  String useNoMoreThanIngredients(int count) {
    return 'Use no more than $count ingredients.';
  }

  @override
  String get completeIngredientFields =>
      'Complete all ingredient names and quantities before continuing.';

  @override
  String addUpToIngredients(int count) {
    return 'You can add up to $count ingredients.';
  }

  @override
  String keepAtLeastIngredients(int count) {
    return 'Keep at least $count ingredients before generating a recipe.';
  }

  @override
  String ingredientRemoved(Object name) {
    return '$name removed.';
  }

  @override
  String get ingredientEditorAddTitle => 'Add ingredient';

  @override
  String get ingredientEditorEditTitle => 'Edit ingredient';

  @override
  String get ingredientEditorAddAction => 'Add ingredient';

  @override
  String get ingredientEditorSaveAction => 'Save ingredient';

  @override
  String get noIngredientsAddedYet => 'No ingredients added yet';

  @override
  String get closeIngredientEditorTooltip => 'Close ingredient editor';

  @override
  String get ingredientEditorDescription =>
      'Use clear ingredient names and practical quantities.';

  @override
  String get ingredientNameLabel => 'Ingredient name';

  @override
  String get enterIngredientName => 'Enter an ingredient name.';

  @override
  String useUpToCharacters(int count) {
    return 'Use up to $count characters.';
  }

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get enterQuantity => 'Enter a quantity.';

  @override
  String get closePreviewTooltip => 'Close preview';

  @override
  String get basicStaplesInfoTooltip => 'Basic staples info';

  @override
  String get basicStaplesTooltipTitle => 'Assumed staples';

  @override
  String get basicStaplesTooltipMessage =>
      'Water, common dried spices and seasonings, butter, and a neutral cooking oil or olive oil.';

  @override
  String get recipeDifficultyEasy => 'Easy';

  @override
  String get recipeDifficultyMedium => 'Medium';

  @override
  String get recipeDifficultyHard => 'Hard';

  @override
  String get recipeReadyBadge => 'Recipe ready';

  @override
  String get recipeImagesDisclaimer =>
      'Images are for illustrative purposes only.';

  @override
  String get photosProvidedByPexels => 'Photos provided by Pexels';

  @override
  String get quickMetrics => 'Quick metrics';

  @override
  String get difficultyLabel => 'Difficulty';

  @override
  String get cookingTimeLabel => 'Cooking time';

  @override
  String cookingTimeValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get nutritionSummary => 'Nutrition Summary';

  @override
  String nutritionCaloriesValue(int calories) {
    return '$calories kcal';
  }

  @override
  String nutritionMacroValue(int grams) {
    return '${grams}g';
  }

  @override
  String get proteinLabel => 'Protein';

  @override
  String get carbsLabel => 'Carbs';

  @override
  String get fatLabel => 'Fat';

  @override
  String get ingredientsHeading => 'Ingredients';

  @override
  String get ingredientsChecklistHint => 'Check items off as you cook.';

  @override
  String get stepsHeading => 'Steps';

  @override
  String get startCooking => 'Start cooking';

  @override
  String cookingModeStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get cookingModeBack => 'Back';

  @override
  String get cookingModeNext => 'Next';

  @override
  String get cookingModeFinish => 'Finish';

  @override
  String get closeCookingModeTooltip => 'Close cooking mode';

  @override
  String get cookAnother => 'Cook another';

  @override
  String get backToIngredientsTooltip => 'Back to ingredients';

  @override
  String get backToRecipesTooltip => 'Back to recipes';

  @override
  String get backToHomeTooltip => 'Back to home';

  @override
  String get recipeLoadingMilestone1 => 'Analyzing products';

  @override
  String get recipeLoadingMilestone2 => 'Selecting flavor combinations';

  @override
  String get recipeLoadingMilestone3 => 'Calculating cooking time';

  @override
  String get recipeLoadingMilestone4 => 'Estimating calories';

  @override
  String get recipeLoadingBadge => 'AI is cooking';

  @override
  String get recipeLoadingTitle =>
      'Creating a recipe based on your ingredients...';

  @override
  String get recipeLoadingDescription =>
      'This can take a few moments while the assistant builds a balanced single-serving dish.';

  @override
  String get sessionErrorUnknownTitle => 'Something went wrong';

  @override
  String get sessionErrorUnknownMessage =>
      'Something went wrong. Please try again.';

  @override
  String get sessionErrorIngredientScanTitle => 'Ingredient scan failed';

  @override
  String get sessionErrorRecipeGenerationTitle => 'Recipe generation failed';

  @override
  String get sessionErrorActionStartOver => 'Start over';

  @override
  String get sessionErrorActionRetakePhoto => 'Retake photo';

  @override
  String get sessionErrorActionTryGeneratingAgain => 'Try generating again';

  @override
  String get sessionErrorActionReturnHome => 'Return home';

  @override
  String get sessionErrorActionBackToIngredients => 'Back to ingredients';

  @override
  String get sessionErrorActionHome => 'Home';

  @override
  String get sessionErrorNoClearIngredients =>
      'No clear ingredients were detected. Try moving closer and improving the lighting.';

  @override
  String get sessionErrorCouldNotRecognizePhoto =>
      'I could not recognize the ingredients from this photo. Please try again.';

  @override
  String sessionErrorTooFewIngredients(int count) {
    return 'Add at least $count ingredients before generating a recipe.';
  }

  @override
  String sessionErrorTooManyIngredients(int count) {
    return 'Use no more than $count ingredients for one recipe.';
  }

  @override
  String get sessionErrorRecipeGenerationMessage =>
      'Recipe generation failed. Please try again.';

  @override
  String get sessionErrorInvalidIngredients =>
      'Could not create a recipe from those ingredients. Check the names and quantities, then try again.';

  @override
  String get sessionErrorNetworkUnavailable =>
      'Could not reach the server. Check the backend URL and network.';

  @override
  String get sessionErrorRequestTimedOutScan =>
      'Ingredient recognition took too long. Please try again.';

  @override
  String get sessionErrorRequestTimedOutRecipe =>
      'Recipe creation took too long. Please try again.';

  @override
  String get sessionErrorInvalidImageFile =>
      'Only image files can be scanned for ingredients.';

  @override
  String get sessionErrorUnexpectedResponse =>
      'The server returned an unexpected response.';

  @override
  String get authSignInIntro => 'Sign in to continue cooking.';

  @override
  String get authSignUpIntro => 'Create your account to save your session.';

  @override
  String get authModeSignIn => 'Sign in';

  @override
  String get authModeSignUp => 'Sign up';

  @override
  String get authFullNameLabel => 'Full Name';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm Password';

  @override
  String get authEnterFullName => 'Enter your full name';

  @override
  String get authEnterEmail => 'Enter your email';

  @override
  String get authEnterValidEmail => 'Enter a valid email';

  @override
  String get authEnterPassword => 'Enter your password';

  @override
  String get authPasswordMinLength => 'Password must be at least 8 characters';

  @override
  String get authConfirmPassword => 'Confirm your password';

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authSubmitLoading => 'Please wait...';

  @override
  String get authFutureProvidersHint =>
      'Google and Apple sign-in can be added later without changing this flow.';

  @override
  String get authSwitchToSignUpPrompt => 'Don\'t have an account?';

  @override
  String get authSwitchToSignInPrompt => 'Already have an account?';

  @override
  String get authBackToDetails => 'Back';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authDismissError => 'Dismiss error';

  @override
  String get authErrorValidationFailed =>
      'Please check the form and try again.';

  @override
  String get authErrorEmailAlreadyInUse => 'This email is already in use.';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrorSessionExpired => 'Your session has expired.';

  @override
  String get authErrorRequestTimedOut => 'The request timed out. Try again.';

  @override
  String get authErrorNetworkUnavailable => 'No network connection.';

  @override
  String get authErrorServerFailure => 'Server error. Try again later.';

  @override
  String get authErrorUnexpectedResponse => 'Unexpected server response.';

  @override
  String get authErrorRestoreSession => 'Could not restore the saved session.';
}
