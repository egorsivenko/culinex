import 'dart:async';
import 'dart:math' as math;

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
                      isSubmitting: widget.authController.isSubmitting,
                      errorCode: widget.authController.error?.code,
                      onClearError: widget.authController.clearError,
                      onSignOut: () async {
                        widget.controller.resetSession();
                        await widget.authController.signOut();
                      },
                      onDeleteAccount: () async {
                        widget.controller.resetSession();
                        await widget.authController.deleteAccount();
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

class _RootBottomNavigationBar extends StatefulWidget {
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
  State<_RootBottomNavigationBar> createState() =>
      _RootBottomNavigationBarState();
}

class _RootBottomNavigationBarState extends State<_RootBottomNavigationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late double _fromIndex;
  late double _toIndex;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.selectedTab.index.toDouble();
    _toIndex = _fromIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _RootBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final double nextIndex = widget.selectedTab.index.toDouble();
    if (nextIndex == _toIndex) {
      return;
    }

    final double progress = Curves.easeOutCubic.transform(_controller.value);
    _fromIndex = _fromIndex + ((_toIndex - _fromIndex) * progress);
    _toIndex = nextIndex;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color backgroundColor =
        theme.navigationBarTheme.backgroundColor ??
        theme.colorScheme.surfaceContainer;
    final Color indicatorColor =
        theme.navigationBarTheme.indicatorColor ??
        theme.colorScheme.secondaryContainer;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double progress = Curves.easeOutCubic.transform(
          _controller.value,
        );

        return Material(
          color: backgroundColor,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double segmentWidth = constraints.maxWidth / 2;
                  final double animatedIndex =
                      _fromIndex + ((_toIndex - _fromIndex) * progress);
                  final double stretch = math.sin(progress * math.pi);
                  final double pillWidth = 64 + (12 * stretch);
                  final double pillHeight = 32 - (8 * stretch);
                  final double centerX = segmentWidth * (animatedIndex + 0.5);
                  final double pillTop = 24 - (pillHeight / 2);

                  return Stack(
                    children: [
                      Positioned(
                        left: centerX - (pillWidth / 2),
                        top: pillTop,
                        width: pillWidth,
                        height: pillHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: indicatorColor,
                            borderRadius: BorderRadius.circular(pillHeight / 2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _RootBottomNavDestination(
                              label: widget.mainLabel,
                              icon: Icons.home_outlined,
                              selectedIcon: Icons.home_rounded,
                              isSelected: widget.selectedTab == _RootTab.main,
                              onPressed: () =>
                                  widget.onTabSelected(_RootTab.main),
                            ),
                          ),
                          Expanded(
                            child: _RootBottomNavDestination(
                              label: widget.settingsLabel,
                              icon: Icons.settings_outlined,
                              selectedIcon: Icons.settings_rounded,
                              isSelected:
                                  widget.selectedTab == _RootTab.settings,
                              onPressed: () =>
                                  widget.onTabSelected(_RootTab.settings),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RootBottomNavDestination extends StatelessWidget {
  const _RootBottomNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color selectedColor =
        theme.navigationBarTheme.labelTextStyle?.resolve(<WidgetState>{
          WidgetState.selected,
        })?.color ??
        theme.colorScheme.onSecondaryContainer;
    final Color unselectedColor =
        theme.navigationBarTheme.labelTextStyle
            ?.resolve(<WidgetState>{})
            ?.color ??
        theme.colorScheme.onSurfaceVariant;
    final TextStyle labelStyle =
        theme.navigationBarTheme.labelTextStyle?.resolve(
          isSelected ? <WidgetState>{WidgetState.selected} : <WidgetState>{},
        ) ??
        theme.textTheme.labelMedium!.copyWith(
          color: isSelected ? selectedColor : unselectedColor,
          fontWeight: FontWeight.w500,
        );

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 2),
              Icon(
                isSelected ? selectedIcon : icon,
                size: 24,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              const SizedBox(height: 6),
              Text(label, style: labelStyle),
            ],
          ),
        ),
      ),
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
