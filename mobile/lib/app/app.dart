import 'dart:async';

import 'package:flutter/material.dart';

import '../core/localization/app_locale.dart';
import '../core/localization/locale_store.dart';
import '../core/network/culinex_api_client.dart';
import '../core/network/culinex_repository.dart';
import '../core/theme/culinex_theme.dart';
import '../core/theme/theme_mode_store.dart';
import '../features/camera/camera_capture_screen.dart';
import '../features/home/welcome_screen.dart';
import '../features/ingredients/ingredient_review_screen.dart';
import '../features/ingredients/scan_loading_screen.dart';
import '../features/recipe/recipe_loading_screen.dart';
import '../features/recipe/recipe_screen.dart';
import '../features/session/cook_session_controller.dart';
import '../features/session/session_localizations.dart';
import '../features/session/session_error_screen.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';

class CulinexApp extends StatefulWidget {
  const CulinexApp({
    super.key,
    this.controller,
    this.initialThemeMode = ThemeMode.light,
    this.themeModeStore,
    this.initialLocale = AppLocale.english,
    this.localeStore,
  });

  final CookSessionController? controller;
  final ThemeMode initialThemeMode;
  final ThemeModeStore? themeModeStore;
  final Locale initialLocale;
  final LocaleStore? localeStore;

  @override
  State<CulinexApp> createState() => _CulinexAppState();
}

class _CulinexAppState extends State<CulinexApp> {
  late final bool _ownsController;
  late final CookSessionController _controller;
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = AppLocale.english;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? _buildController();
    _themeMode = widget.initialThemeMode;
    _locale = AppLocale.normalize(widget.initialLocale);
    _controller.setLocale(_locale);
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Culinex',
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildCulinexTheme(),
      darkTheme: buildCulinexTheme(brightness: Brightness.dark),
      themeMode: _themeMode,
      home: CulinexFlowShell(
        controller: _controller,
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
        locale: _locale,
        onSelectLocale: _selectLocale,
      ),
    );
  }

  CookSessionController _buildController() {
    final CulinexRepository repository = CulinexApiClient();
    return CookSessionController(repository: repository);
  }

  void _toggleTheme() {
    final ThemeMode nextThemeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    setState(() {
      _themeMode = nextThemeMode;
    });

    final ThemeModeStore? themeModeStore = widget.themeModeStore;
    if (themeModeStore != null) {
      unawaited(themeModeStore.saveThemeMode(nextThemeMode));
    }
  }

  void _selectLocale(Locale locale) {
    final Locale normalizedLocale = AppLocale.normalize(locale);
    if (_locale == normalizedLocale) {
      return;
    }

    setState(() {
      _locale = normalizedLocale;
    });
    _controller.setLocale(normalizedLocale);

    final LocaleStore? localeStore = widget.localeStore;
    if (localeStore != null) {
      unawaited(localeStore.saveLocale(normalizedLocale));
    }
  }
}

class CulinexFlowShell extends StatelessWidget {
  const CulinexFlowShell({
    required this.controller,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.locale,
    required this.onSelectLocale,
    super.key,
  });

  final CookSessionController controller;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Locale locale;
  final ValueChanged<Locale> onSelectLocale;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final AppLocalizations l10n = context.l10n;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(controller.stage),
            child: switch (controller.stage) {
              SessionStage.welcome => WelcomeScreen(
                onStart: controller.openCamera,
                onStartManualEntry: controller.startManualIngredientEntry,
                isDarkMode: isDarkMode,
                onToggleTheme: onToggleTheme,
                locale: locale,
                onSelectLocale: onSelectLocale,
              ),
              SessionStage.camera => CameraCaptureScreen(
                onBack: controller.showWelcome,
                onCapture: controller.extractIngredientsFromPhoto,
              ),
              SessionStage.extracting => ScanLoadingScreen(
                imagePath: controller.capturedImagePath,
              ),
              SessionStage.ingredients => IngredientReviewScreen(
                imagePath: controller.capturedImagePath,
                ingredients: controller.ingredients,
                assumeBasicStaples: controller.assumeBasicStaples,
                entryMode: controller.isManualIngredientEntry
                    ? IngredientReviewEntryMode.manual
                    : IngredientReviewEntryMode.scanned,
                onBack: controller.leaveIngredientEntry,
                onProceed: controller.generateRecipeFromIngredients,
                onOpenRecipe: controller.recipe != null
                    ? controller.showRecipe
                    : null,
              ),
              SessionStage.generatingRecipe => RecipeLoadingScreen(
                imagePath: controller.capturedImagePath,
              ),
              SessionStage.recipe => RecipeScreen(
                recipe: controller.recipe!,
                onBackToIngredients: controller.showIngredients,
                onCookAnother: controller.resetSession,
              ),
              SessionStage.error => SessionErrorScreen(
                title: localizeSessionErrorTitle(
                  l10n,
                  controller.lastOperation,
                ),
                message: localizeSessionErrorMessage(
                  l10n,
                  controller.errorState,
                ),
                primaryActionLabel: localizeSessionPrimaryActionLabel(
                  l10n,
                  controller.lastOperation,
                ),
                secondaryActionLabel: localizeSessionSecondaryActionLabel(
                  l10n,
                  controller.lastOperation,
                ),
                onPrimaryAction: controller.performErrorPrimaryAction,
                onSecondaryAction: controller.performErrorSecondaryAction,
              ),
            },
          ),
        );
      },
    );
  }
}
