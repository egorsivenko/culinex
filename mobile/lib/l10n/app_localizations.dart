import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uk'),
  ];

  /// No description provided for @languageEnglishShort.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageEnglishShort;

  /// No description provided for @languageUkrainianShort.
  ///
  /// In en, this message translates to:
  /// **'УКР'**
  String get languageUkrainianShort;

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get switchToDarkMode;

  /// No description provided for @switchToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Switch to English'**
  String get switchToEnglish;

  /// No description provided for @switchToUkrainian.
  ///
  /// In en, this message translates to:
  /// **'Switch to Ukrainian'**
  String get switchToUkrainian;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @mainTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get mainTabLabel;

  /// No description provided for @myRecipesTabLabel.
  ///
  /// In en, this message translates to:
  /// **'My recipes'**
  String get myRecipesTabLabel;

  /// No description provided for @settingsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTabLabel;

  /// No description provided for @myRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'My recipes'**
  String get myRecipesTitle;

  /// No description provided for @myRecipesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved recipes yet'**
  String get myRecipesEmptyTitle;

  /// No description provided for @myRecipesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Generated recipes will appear here.'**
  String get myRecipesEmptyMessage;

  /// No description provided for @myRecipesLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipes could not be loaded'**
  String get myRecipesLoadFailedTitle;

  /// No description provided for @myRecipesLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get myRecipesLoadFailedMessage;

  /// No description provided for @myRecipesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get myRecipesRetry;

  /// No description provided for @deleteRecipe.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteRecipe;

  /// No description provided for @deleteRecipeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recipe?'**
  String get deleteRecipeDialogTitle;

  /// No description provided for @deleteRecipeDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This recipe will be permanently deleted.'**
  String get deleteRecipeDialogMessage;

  /// No description provided for @deleteRecipeDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete recipe'**
  String get deleteRecipeDialogConfirm;

  /// No description provided for @deleteRecipeFailed.
  ///
  /// In en, this message translates to:
  /// **'Recipe could not be deleted. Try again.'**
  String get deleteRecipeFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsAppearanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsAppearanceLabel;

  /// No description provided for @settingsLightOption.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLightOption;

  /// No description provided for @settingsDarkOption.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDarkOption;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account is permanent and cannot be undone.'**
  String get deleteAccountDialogMessage;

  /// No description provided for @deleteAccountDialogInstruction.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm.'**
  String get deleteAccountDialogInstruction;

  /// No description provided for @deleteAccountDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountDialogConfirm;

  /// No description provided for @welcomePhrase1.
  ///
  /// In en, this message translates to:
  /// **'Turn ingredients into flavor.'**
  String get welcomePhrase1;

  /// No description provided for @welcomePhrase2.
  ///
  /// In en, this message translates to:
  /// **'Snap your ingredients. Get a recipe.'**
  String get welcomePhrase2;

  /// No description provided for @welcomePhrase3.
  ///
  /// In en, this message translates to:
  /// **'Your next meal starts with a photo.'**
  String get welcomePhrase3;

  /// No description provided for @welcomePhrase4.
  ///
  /// In en, this message translates to:
  /// **'Got ingredients? We\'ve got ideas.'**
  String get welcomePhrase4;

  /// No description provided for @welcomePhrase5.
  ///
  /// In en, this message translates to:
  /// **'Cook more with what you have.'**
  String get welcomePhrase5;

  /// No description provided for @welcomePhrase6.
  ///
  /// In en, this message translates to:
  /// **'Snap a photo. Start cooking.'**
  String get welcomePhrase6;

  /// No description provided for @welcomePhrase7.
  ///
  /// In en, this message translates to:
  /// **'Let\'s cook something great today.'**
  String get welcomePhrase7;

  /// No description provided for @welcomePhrase8.
  ///
  /// In en, this message translates to:
  /// **'Your kitchen has endless potential.'**
  String get welcomePhrase8;

  /// No description provided for @welcomePhrase9.
  ///
  /// In en, this message translates to:
  /// **'Your kitchen has hidden potential.'**
  String get welcomePhrase9;

  /// No description provided for @welcomePhrase10.
  ///
  /// In en, this message translates to:
  /// **'Recipe ideas from one photo.'**
  String get welcomePhrase10;

  /// No description provided for @welcomePhrase11.
  ///
  /// In en, this message translates to:
  /// **'Smart cooking starts here.'**
  String get welcomePhrase11;

  /// No description provided for @takePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhotoTitle;

  /// No description provided for @takePhotoDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan the ingredients you already have and turn them into a recipe.'**
  String get takePhotoDescription;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Use the camera'**
  String get useCamera;

  /// No description provided for @enterIngredientsManuallyTitle.
  ///
  /// In en, this message translates to:
  /// **'Type ingredients'**
  String get enterIngredientsManuallyTitle;

  /// No description provided for @enterIngredientsManuallyDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your ingredients manually and go straight to recipe generation.'**
  String get enterIngredientsManuallyDescription;

  /// No description provided for @typeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Type ingredients'**
  String get typeIngredients;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan ingredients with your camera or type them in to get a recipe in seconds.'**
  String get welcomeDescription;

  /// No description provided for @choiceSeparatorOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get choiceSeparatorOr;

  /// No description provided for @cameraNoDevice.
  ///
  /// In en, this message translates to:
  /// **'No camera is available on this device.'**
  String get cameraNoDevice;

  /// No description provided for @cameraFlashUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Flash is not available on this device.'**
  String get cameraFlashUnavailable;

  /// No description provided for @cameraSelectedPhotoOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The selected photo could not be opened. Please try another image.'**
  String get cameraSelectedPhotoOpenFailed;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission was denied. Enable it in system settings.'**
  String get cameraPermissionDenied;

  /// No description provided for @cameraAccessRestricted.
  ///
  /// In en, this message translates to:
  /// **'Camera access is restricted on this device.'**
  String get cameraAccessRestricted;

  /// No description provided for @cameraMicrophoneDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access was denied.'**
  String get cameraMicrophoneDenied;

  /// No description provided for @cameraStartFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be started. Please try again.'**
  String get cameraStartFailed;

  /// No description provided for @cameraShowFrameHintTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show frame hint'**
  String get cameraShowFrameHintTooltip;

  /// No description provided for @cameraInfoPopupText.
  ///
  /// In en, this message translates to:
  /// **'Place the ingredients in the frame'**
  String get cameraInfoPopupText;

  /// No description provided for @scanLoadingBadge.
  ///
  /// In en, this message translates to:
  /// **'Scanning ingredients'**
  String get scanLoadingBadge;

  /// No description provided for @scanLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Recognizing ingredients...'**
  String get scanLoadingTitle;

  /// No description provided for @scanLoadingDescription.
  ///
  /// In en, this message translates to:
  /// **'The app is checking what is visible in the photo and estimating the product quantities before recipe creation.'**
  String get scanLoadingDescription;

  /// No description provided for @ingredientConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High confidence'**
  String get ingredientConfidenceHigh;

  /// No description provided for @ingredientConfidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium confidence'**
  String get ingredientConfidenceMedium;

  /// No description provided for @ingredientConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Low confidence'**
  String get ingredientConfidenceLow;

  /// No description provided for @ingredientStatusScanned.
  ///
  /// In en, this message translates to:
  /// **'Scan complete'**
  String get ingredientStatusScanned;

  /// No description provided for @ingredientStatusManual.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get ingredientStatusManual;

  /// No description provided for @ingredientReviewScannedTitle.
  ///
  /// In en, this message translates to:
  /// **'Review and adjust the list'**
  String get ingredientReviewScannedTitle;

  /// No description provided for @ingredientReviewManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your ingredients'**
  String get ingredientReviewManualTitle;

  /// No description provided for @ingredientReviewScannedDescription.
  ///
  /// In en, this message translates to:
  /// **'Add missing ingredients, edit names or quantities, or swipe left to remove anything irrelevant before recipe generation.'**
  String get ingredientReviewScannedDescription;

  /// No description provided for @ingredientReviewManualDescription.
  ///
  /// In en, this message translates to:
  /// **'Start from scratch, add clear ingredient names and practical quantities, then generate a recipe when the list looks right.'**
  String get ingredientReviewManualDescription;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @returnToRecipe.
  ///
  /// In en, this message translates to:
  /// **'Return to recipe'**
  String get returnToRecipe;

  /// No description provided for @generateAgainHint.
  ///
  /// In en, this message translates to:
  /// **'Generate again to refresh the recipe after editing this list.'**
  String get generateAgainHint;

  /// No description provided for @viewOriginalPhoto.
  ///
  /// In en, this message translates to:
  /// **'View original photo'**
  String get viewOriginalPhoto;

  /// No description provided for @assumeBasicStaplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Assume basic staples are available'**
  String get assumeBasicStaplesTitle;

  /// No description provided for @ingredientCountStatus.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max} ingredients'**
  String ingredientCountStatus(int current, int max);

  /// No description provided for @addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get addIngredient;

  /// No description provided for @deleteIngredientTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteIngredientTooltip(Object name);

  /// No description provided for @editIngredientTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editIngredientTooltip(Object name);

  /// No description provided for @editedBadge.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get editedBadge;

  /// No description provided for @addAtLeastIngredientsToContinue.
  ///
  /// In en, this message translates to:
  /// **'Add at least {count} ingredients to continue.'**
  String addAtLeastIngredientsToContinue(int count);

  /// No description provided for @useNoMoreThanIngredients.
  ///
  /// In en, this message translates to:
  /// **'Use no more than {count} ingredients.'**
  String useNoMoreThanIngredients(int count);

  /// No description provided for @completeIngredientFields.
  ///
  /// In en, this message translates to:
  /// **'Complete all ingredient names and quantities before continuing.'**
  String get completeIngredientFields;

  /// No description provided for @addUpToIngredients.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {count} ingredients.'**
  String addUpToIngredients(int count);

  /// No description provided for @keepAtLeastIngredients.
  ///
  /// In en, this message translates to:
  /// **'Keep at least {count} ingredients before generating a recipe.'**
  String keepAtLeastIngredients(int count);

  /// No description provided for @ingredientRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed.'**
  String ingredientRemoved(Object name);

  /// No description provided for @ingredientEditorAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get ingredientEditorAddTitle;

  /// No description provided for @ingredientEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit ingredient'**
  String get ingredientEditorEditTitle;

  /// No description provided for @ingredientEditorAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get ingredientEditorAddAction;

  /// No description provided for @ingredientEditorSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save ingredient'**
  String get ingredientEditorSaveAction;

  /// No description provided for @noIngredientsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No ingredients added yet'**
  String get noIngredientsAddedYet;

  /// No description provided for @closeIngredientEditorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close ingredient editor'**
  String get closeIngredientEditorTooltip;

  /// No description provided for @ingredientEditorDescription.
  ///
  /// In en, this message translates to:
  /// **'Use clear ingredient names and practical quantities.'**
  String get ingredientEditorDescription;

  /// No description provided for @ingredientNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Ingredient name'**
  String get ingredientNameLabel;

  /// No description provided for @enterIngredientName.
  ///
  /// In en, this message translates to:
  /// **'Enter an ingredient name.'**
  String get enterIngredientName;

  /// No description provided for @useUpToCharacters.
  ///
  /// In en, this message translates to:
  /// **'Use up to {count} characters.'**
  String useUpToCharacters(int count);

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity.'**
  String get enterQuantity;

  /// No description provided for @closePreviewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close preview'**
  String get closePreviewTooltip;

  /// No description provided for @basicStaplesInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Basic staples info'**
  String get basicStaplesInfoTooltip;

  /// No description provided for @basicStaplesTooltipTitle.
  ///
  /// In en, this message translates to:
  /// **'Assumed staples'**
  String get basicStaplesTooltipTitle;

  /// No description provided for @basicStaplesTooltipMessage.
  ///
  /// In en, this message translates to:
  /// **'Water, common dried spices and seasonings, butter, and a neutral cooking oil or olive oil.'**
  String get basicStaplesTooltipMessage;

  /// No description provided for @recipeDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get recipeDifficultyEasy;

  /// No description provided for @recipeDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get recipeDifficultyMedium;

  /// No description provided for @recipeDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get recipeDifficultyHard;

  /// No description provided for @recipeReadyBadge.
  ///
  /// In en, this message translates to:
  /// **'Recipe ready'**
  String get recipeReadyBadge;

  /// No description provided for @quickMetrics.
  ///
  /// In en, this message translates to:
  /// **'Quick metrics'**
  String get quickMetrics;

  /// No description provided for @difficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficultyLabel;

  /// No description provided for @cookingTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cooking time'**
  String get cookingTimeLabel;

  /// No description provided for @cookingTimeValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String cookingTimeValue(int minutes);

  /// No description provided for @nutritionSummary.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Summary'**
  String get nutritionSummary;

  /// No description provided for @nutritionCaloriesValue.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String nutritionCaloriesValue(int calories);

  /// No description provided for @nutritionMacroValue.
  ///
  /// In en, this message translates to:
  /// **'{grams}g'**
  String nutritionMacroValue(int grams);

  /// No description provided for @proteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get proteinLabel;

  /// No description provided for @carbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbsLabel;

  /// No description provided for @fatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fatLabel;

  /// No description provided for @ingredientsHeading.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsHeading;

  /// No description provided for @ingredientsChecklistHint.
  ///
  /// In en, this message translates to:
  /// **'Check items off as you cook.'**
  String get ingredientsChecklistHint;

  /// No description provided for @stepsHeading.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsHeading;

  /// No description provided for @cookAnother.
  ///
  /// In en, this message translates to:
  /// **'Cook another'**
  String get cookAnother;

  /// No description provided for @backToIngredientsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to ingredients'**
  String get backToIngredientsTooltip;

  /// No description provided for @backToRecipesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to recipes'**
  String get backToRecipesTooltip;

  /// No description provided for @backToHomeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHomeTooltip;

  /// No description provided for @recipeLoadingMilestone1.
  ///
  /// In en, this message translates to:
  /// **'Analyzing products'**
  String get recipeLoadingMilestone1;

  /// No description provided for @recipeLoadingMilestone2.
  ///
  /// In en, this message translates to:
  /// **'Selecting flavor combinations'**
  String get recipeLoadingMilestone2;

  /// No description provided for @recipeLoadingMilestone3.
  ///
  /// In en, this message translates to:
  /// **'Calculating cooking time'**
  String get recipeLoadingMilestone3;

  /// No description provided for @recipeLoadingMilestone4.
  ///
  /// In en, this message translates to:
  /// **'Estimating calories'**
  String get recipeLoadingMilestone4;

  /// No description provided for @recipeLoadingBadge.
  ///
  /// In en, this message translates to:
  /// **'AI is cooking'**
  String get recipeLoadingBadge;

  /// No description provided for @recipeLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Creating a recipe based on your ingredients...'**
  String get recipeLoadingTitle;

  /// No description provided for @recipeLoadingDescription.
  ///
  /// In en, this message translates to:
  /// **'This can take a few moments while the assistant builds a balanced single-serving dish.'**
  String get recipeLoadingDescription;

  /// No description provided for @sessionErrorUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get sessionErrorUnknownTitle;

  /// No description provided for @sessionErrorUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get sessionErrorUnknownMessage;

  /// No description provided for @sessionErrorIngredientScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredient scan failed'**
  String get sessionErrorIngredientScanTitle;

  /// No description provided for @sessionErrorRecipeGenerationTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipe generation failed'**
  String get sessionErrorRecipeGenerationTitle;

  /// No description provided for @sessionErrorActionStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get sessionErrorActionStartOver;

  /// No description provided for @sessionErrorActionRetakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake photo'**
  String get sessionErrorActionRetakePhoto;

  /// No description provided for @sessionErrorActionTryGeneratingAgain.
  ///
  /// In en, this message translates to:
  /// **'Try generating again'**
  String get sessionErrorActionTryGeneratingAgain;

  /// No description provided for @sessionErrorActionReturnHome.
  ///
  /// In en, this message translates to:
  /// **'Return home'**
  String get sessionErrorActionReturnHome;

  /// No description provided for @sessionErrorActionBackToIngredients.
  ///
  /// In en, this message translates to:
  /// **'Back to ingredients'**
  String get sessionErrorActionBackToIngredients;

  /// No description provided for @sessionErrorActionHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get sessionErrorActionHome;

  /// No description provided for @sessionErrorNoClearIngredients.
  ///
  /// In en, this message translates to:
  /// **'No clear ingredients were detected. Try moving closer and improving the lighting.'**
  String get sessionErrorNoClearIngredients;

  /// No description provided for @sessionErrorCouldNotRecognizePhoto.
  ///
  /// In en, this message translates to:
  /// **'I could not recognize the ingredients from this photo. Please try again.'**
  String get sessionErrorCouldNotRecognizePhoto;

  /// No description provided for @sessionErrorTooFewIngredients.
  ///
  /// In en, this message translates to:
  /// **'Add at least {count} ingredients before generating a recipe.'**
  String sessionErrorTooFewIngredients(int count);

  /// No description provided for @sessionErrorTooManyIngredients.
  ///
  /// In en, this message translates to:
  /// **'Use no more than {count} ingredients for one recipe.'**
  String sessionErrorTooManyIngredients(int count);

  /// No description provided for @sessionErrorRecipeGenerationMessage.
  ///
  /// In en, this message translates to:
  /// **'Recipe generation failed. Please try again.'**
  String get sessionErrorRecipeGenerationMessage;

  /// No description provided for @sessionErrorNetworkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check the backend URL and network.'**
  String get sessionErrorNetworkUnavailable;

  /// No description provided for @sessionErrorRequestTimedOutScan.
  ///
  /// In en, this message translates to:
  /// **'Ingredient recognition took too long. Please try again.'**
  String get sessionErrorRequestTimedOutScan;

  /// No description provided for @sessionErrorRequestTimedOutRecipe.
  ///
  /// In en, this message translates to:
  /// **'Recipe creation took too long. Please try again.'**
  String get sessionErrorRequestTimedOutRecipe;

  /// No description provided for @sessionErrorInvalidImageFile.
  ///
  /// In en, this message translates to:
  /// **'Only image files can be scanned for ingredients.'**
  String get sessionErrorInvalidImageFile;

  /// No description provided for @sessionErrorUnexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'The server returned an unexpected response.'**
  String get sessionErrorUnexpectedResponse;

  /// No description provided for @authSignInIntro.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue cooking.'**
  String get authSignInIntro;

  /// No description provided for @authSignUpIntro.
  ///
  /// In en, this message translates to:
  /// **'Create your account to save your session.'**
  String get authSignUpIntro;

  /// No description provided for @authModeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authModeSignIn;

  /// No description provided for @authModeSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authModeSignUp;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullNameLabel;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get authEnterFullName;

  /// No description provided for @authEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEnterEmail;

  /// No description provided for @authEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEnterValidEmail;

  /// No description provided for @authEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authEnterPassword;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authPasswordMinLength;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get authConfirmPassword;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @authSubmitLoading.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get authSubmitLoading;

  /// No description provided for @authFutureProvidersHint.
  ///
  /// In en, this message translates to:
  /// **'Google and Apple sign-in can be added later without changing this flow.'**
  String get authFutureProvidersHint;

  /// No description provided for @authSwitchToSignUpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authSwitchToSignUpPrompt;

  /// No description provided for @authSwitchToSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authSwitchToSignInPrompt;

  /// No description provided for @authBackToDetails.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get authBackToDetails;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authDismissError.
  ///
  /// In en, this message translates to:
  /// **'Dismiss error'**
  String get authDismissError;

  /// No description provided for @authErrorValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Please check the form and try again.'**
  String get authErrorValidationFailed;

  /// No description provided for @authErrorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get authErrorEmailAlreadyInUse;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired.'**
  String get authErrorSessionExpired;

  /// No description provided for @authErrorRequestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Try again.'**
  String get authErrorRequestTimedOut;

  /// No description provided for @authErrorNetworkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No network connection.'**
  String get authErrorNetworkUnavailable;

  /// No description provided for @authErrorServerFailure.
  ///
  /// In en, this message translates to:
  /// **'Server error. Try again later.'**
  String get authErrorServerFailure;

  /// No description provided for @authErrorUnexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected server response.'**
  String get authErrorUnexpectedResponse;

  /// No description provided for @authErrorRestoreSession.
  ///
  /// In en, this message translates to:
  /// **'Could not restore the saved session.'**
  String get authErrorRestoreSession;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
