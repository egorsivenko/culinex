import 'dart:async';

import 'package:flutter/material.dart';

import '../core/auth/auth_api_client.dart';
import '../core/auth/auth_session_store.dart';
import '../core/localization/app_locale.dart';
import '../core/localization/locale_store.dart';
import '../core/network/culinex_api_client.dart';
import '../core/network/culinex_repository.dart';
import '../core/theme/culinex_theme.dart';
import '../core/theme/theme_mode_store.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_screen.dart';
import '../features/camera/camera_capture_screen.dart';
import '../features/home/welcome_screen.dart';
import '../features/ingredients/ingredient_review_screen.dart';
import '../features/ingredients/scan_loading_screen.dart';
import '../features/recipe/recipe_loading_screen.dart';
import '../features/recipe/recipe_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/session/cook_session_controller.dart';
import '../features/session/session_localizations.dart';
import '../features/session/session_error_screen.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';

class CulinexApp extends StatefulWidget {
  const CulinexApp({
    super.key,
    this.controller,
    this.authController,
    this.initialThemeMode = ThemeMode.light,
    this.themeModeStore,
    this.initialLocale = AppLocale.english,
    this.localeStore,
  });

  final CookSessionController? controller;
  final AuthController? authController;
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
  late final bool _ownsAuthController;
  late final AuthController _authController;
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = AppLocale.english;

  @override
  void initState() {
    super.initState();
    _ownsAuthController = widget.authController == null;
    _authController = widget.authController ?? _buildAuthController();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? _buildController(_authController);
    _themeMode = widget.initialThemeMode;
    _locale = AppLocale.normalize(widget.initialLocale);
    _controller.setLocale(_locale);
    unawaited(_authController.restoreSession());
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsAuthController) {
      _authController.dispose();
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
      home: AnimatedBuilder(
        animation: _authController,
        builder: (BuildContext context, _) {
          return switch (_authController.stage) {
            AuthStage.loading => const _AuthLoadingScreen(),
            AuthStage.signedOut => AuthScreen(
              controller: _authController,
              isDarkMode: _themeMode == ThemeMode.dark,
              onToggleTheme: _toggleTheme,
              locale: _locale,
              onSelectLocale: _selectLocale,
            ),
            AuthStage.authenticated => CulinexFlowShell(
              controller: _controller,
              authController: _authController,
              isDarkMode: _themeMode == ThemeMode.dark,
              onToggleTheme: _toggleTheme,
              locale: _locale,
              onSelectLocale: _selectLocale,
            ),
          };
        },
      ),
    );
  }

  CookSessionController _buildController(AuthController authController) {
    final CulinexRepository repository = CulinexApiClient(
      authSessionCoordinator: authController,
    );
    return CookSessionController(repository: repository);
  }

  AuthController _buildAuthController() {
    return AuthController(
      authClient: AuthApiClient(),
      sessionStore: SecureStorageAuthSessionStore(),
    );
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

enum _RootTab { main, settings }

class CulinexFlowShell extends StatefulWidget {
  const CulinexFlowShell({
    required this.controller,
    required this.authController,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.locale,
    required this.onSelectLocale,
    super.key,
  });

  final CookSessionController controller;
  final AuthController authController;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Locale locale;
  final ValueChanged<Locale> onSelectLocale;

  @override
  State<CulinexFlowShell> createState() => _CulinexFlowShellState();
}

class _CulinexFlowShellState extends State<CulinexFlowShell> {
  _RootTab _selectedTab = _RootTab.main;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final AppLocalizations l10n = context.l10n;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(widget.controller.stage),
            child: switch (widget.controller.stage) {
              SessionStage.welcome => Scaffold(
                body: IndexedStack(
                  index: _selectedTab.index,
                  children: [
                    WelcomeScreen(
                      onStart: widget.controller.openCamera,
                      onStartManualEntry:
                          widget.controller.startManualIngredientEntry,
                    ),
                    SettingsScreen(
                      isDarkMode: widget.isDarkMode,
                      onToggleTheme: widget.onToggleTheme,
                      locale: widget.locale,
                      onSelectLocale: widget.onSelectLocale,
                      onSignOut: () async {
                        widget.controller.resetSession();
                        await widget.authController.signOut();
                      },
                    ),
                  ],
                ),
                bottomNavigationBar: _RootBottomNavigationBar(
                  selectedTab: _selectedTab,
                  onTabSelected: (_RootTab tab) {
                    setState(() {
                      _selectedTab = tab;
                    });
                  },
                  mainLabel: l10n.mainTabLabel,
                  settingsLabel: l10n.settingsTabLabel,
                ),
              ),
              SessionStage.camera => CameraCaptureScreen(
                onBack: widget.controller.showWelcome,
                onCapture: widget.controller.extractIngredientsFromPhoto,
              ),
              SessionStage.extracting => ScanLoadingScreen(
                imagePath: widget.controller.capturedImagePath,
              ),
              SessionStage.ingredients => IngredientReviewScreen(
                imagePath: widget.controller.capturedImagePath,
                ingredients: widget.controller.ingredients,
                assumeBasicStaples: widget.controller.assumeBasicStaples,
                entryMode: widget.controller.isManualIngredientEntry
                    ? IngredientReviewEntryMode.manual
                    : IngredientReviewEntryMode.scanned,
                onBack: widget.controller.leaveIngredientEntry,
                onProceed: widget.controller.generateRecipeFromIngredients,
                onOpenRecipe: widget.controller.recipe != null
                    ? widget.controller.showRecipe
                    : null,
              ),
              SessionStage.generatingRecipe => RecipeLoadingScreen(
                imagePath: widget.controller.capturedImagePath,
              ),
              SessionStage.recipe => RecipeScreen(
                recipe: widget.controller.recipe!,
                onBackToIngredients: widget.controller.showIngredients,
                onCookAnother: widget.controller.resetSession,
              ),
              SessionStage.error => SessionErrorScreen(
                title: localizeSessionErrorTitle(
                  l10n,
                  widget.controller.lastOperation,
                ),
                message: localizeSessionErrorMessage(
                  l10n,
                  widget.controller.errorState,
                ),
                primaryActionLabel: localizeSessionPrimaryActionLabel(
                  l10n,
                  widget.controller.lastOperation,
                ),
                secondaryActionLabel: localizeSessionSecondaryActionLabel(
                  l10n,
                  widget.controller.lastOperation,
                ),
                onPrimaryAction: widget.controller.performErrorPrimaryAction,
                onSecondaryAction:
                    widget.controller.performErrorSecondaryAction,
              ),
            },
          ),
        );
      },
    );
  }
}

class _RootBottomNavigationBar extends StatelessWidget {
  const _RootBottomNavigationBar({
    required this.selectedTab,
    required this.onTabSelected,
    required this.mainLabel,
    required this.settingsLabel,
  });

  final _RootTab selectedTab;
  final ValueChanged<_RootTab> onTabSelected;
  final String mainLabel;
  final String settingsLabel;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 68,
      selectedIndex: selectedTab.index,
      onDestinationSelected: (int index) {
        onTabSelected(_RootTab.values[index]);
      },
      destinations: <NavigationDestination>[
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: mainLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: settingsLabel,
        ),
      ],
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
