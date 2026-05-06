import 'package:culinex/app/app.dart';
import 'package:culinex/core/auth/auth_api_client.dart';
import 'package:culinex/core/auth/auth_models.dart';
import 'package:culinex/core/auth/auth_session_store.dart';
import 'package:culinex/core/localization/locale_store.dart';
import 'package:culinex/core/network/culinex_api_client.dart';
import 'package:culinex/core/network/culinex_repository.dart';
import 'package:culinex/features/auth/auth_controller.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:culinex/features/session/cook_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:culinex/core/theme/theme_mode_store.dart';

const List<String> _englishWelcomePhrases = <String>[
  'Turn ingredients into flavor.',
  'Snap your ingredients. Get a recipe.',
  'Your next meal starts with a photo.',
  'Got ingredients? We\'ve got ideas.',
  'Cook more with what you have.',
  'Snap a photo. Start cooking.',
  'Let\'s cook something great today.',
  'Your kitchen has endless potential.',
  'Your kitchen has hidden potential.',
  'Recipe ideas from one photo.',
  'Smart cooking starts here.',
];

Finder _manualEntryButtonFinder(String label) {
  return find.widgetWithText(OutlinedButton, label);
}

void main() {
  testWidgets('app opens on the welcome screen', (tester) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(controller: controller, authController: authController),
    );
    await tester.pumpAndSettle();

    expect(find.text('Culinex'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('My recipes'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Use the camera'), findsOneWidget);
    expect(find.text('Type ingredients'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('language-toggle-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('theme-toggle-button')),
      findsNothing,
    );
    expect(find.text('Choose how to start your recipe'), findsNothing);
    expect(find.text('Take a photo or type ingredients'), findsNothing);
    expect(find.text('Take a photo of ingredients'), findsNothing);
    expect(find.text('How it works'), findsNothing);
    expect(find.text('Show what is in front of you'), findsNothing);
    expect(
      _englishWelcomePhrases.any(
        (String phrase) => find.text(phrase).evaluate().isNotEmpty,
      ),
      isTrue,
    );

    controller.dispose();
    authController.dispose();
  });

  testWidgets('manual entry button opens the ingredient screen', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(controller: controller, authController: authController),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(_manualEntryButtonFinder('Type ingredients'));
    await tester.pumpAndSettle();
    await tester.tap(_manualEntryButtonFinder('Type ingredients'));
    await tester.pumpAndSettle();

    expect(find.text('Manual entry'), findsOneWidget);
    expect(find.text('Add your ingredients'), findsOneWidget);
    expect(find.text('No ingredients added yet'), findsOneWidget);
    expect(find.text('View original photo'), findsNothing);

    controller.dispose();
    authController.dispose();
  });

  testWidgets('language dropdown switches between English and Ukrainian', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(controller: controller, authController: authController),
    );
    await tester.pumpAndSettle();

    MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en'));
    expect(find.text('Use the camera'), findsOneWidget);
    expect(find.text('Використати камеру'), findsNothing);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-language-toggle-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Українська').last);
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('uk'));
    expect(find.text('Language'), findsNothing);
    expect(find.text('Мова'), findsOneWidget);
    expect(find.text('Налаштування'), findsWidgets);

    controller.dispose();
    authController.dispose();
  });

  testWidgets('theme toggle switches between light and dark modes on welcome', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(controller: controller, authController: authController),
    );
    await tester.pumpAndSettle();

    MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(find.text('Use the camera'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-theme-toggle-button')),
    );
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Dark'), findsOneWidget);

    controller.dispose();
    authController.dispose();
  });

  testWidgets('app can start in dark mode from persisted theme', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(
        controller: controller,
        authController: authController,
        initialThemeMode: ThemeMode.dark,
      ),
    );
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.themeMode, ThemeMode.dark);
    expect(find.text('Use the camera'), findsOneWidget);

    controller.dispose();
    authController.dispose();
  });

  testWidgets('app can start in Ukrainian from persisted locale', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(
        controller: controller,
        authController: authController,
        initialLocale: const Locale('uk'),
      ),
    );
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.locale, const Locale('uk'));
    expect(find.text('Використати камеру'), findsOneWidget);
    expect(find.text('Ввести інгредієнти'), findsWidgets);
    expect(find.text('Use the camera'), findsNothing);

    controller.dispose();
    authController.dispose();
  });

  testWidgets('theme toggle persists the selected theme', (tester) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final _FakeThemeModeStore themeModeStore = _FakeThemeModeStore();
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(
        controller: controller,
        authController: authController,
        themeModeStore: themeModeStore,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-theme-toggle-button')),
    );
    await tester.pumpAndSettle();

    expect(themeModeStore.savedModes, <ThemeMode>[ThemeMode.dark]);

    controller.dispose();
    authController.dispose();
  });

  testWidgets('language toggle persists the selected locale', (tester) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final _FakeLocaleStore localeStore = _FakeLocaleStore();
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(
        controller: controller,
        authController: authController,
        localeStore: localeStore,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-language-toggle-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Українська').last);
    await tester.pumpAndSettle();

    expect(localeStore.savedLocales, <Locale>[const Locale('uk')]);

    controller.dispose();
    authController.dispose();
  });

  testWidgets('app shows auth gate when there is no stored session', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final AuthController authController = AuthController(
      authClient: _FakeAuthClient(),
      sessionStore: _MemorySessionStore(),
    );

    await tester.pumpWidget(
      CulinexApp(controller: controller, authController: authController),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Use the camera'), findsNothing);

    controller.dispose();
    authController.dispose();
  });

  testWidgets('delete account requires DELETE confirmation and signs out', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final _FakeAuthClient authClient = _FakeAuthClient();
    final AuthController authController = AuthController(
      authClient: authClient,
      sessionStore: _MemorySessionStore(initialSession: _buildSession()),
    );

    await tester.pumpWidget(
      CulinexApp(controller: controller, authController: authController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('settings-delete-account-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-delete-account-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete account?'), findsOneWidget);
    final Finder confirmButton = find.byKey(
      const ValueKey<String>('delete-account-confirm-button'),
    );
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey<String>('delete-account-confirmation-input')),
      'DELETE',
    );
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNotNull);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(authClient.deletedAccountAccessToken, 'access-token');

    controller.dispose();
    authController.dispose();
  });

  testWidgets('sign out requires confirmation and signs out', (tester) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(controller: controller, authController: authController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('settings-sign-out-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-sign-out-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('sign-out-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);

    controller.dispose();
    authController.dispose();
  });

  testWidgets('delete all recipes confirms and clears recipe history', (
    tester,
  ) async {
    final _NoopRepository repository = _NoopRepository(
      recipeSummaries: const [
        RecipeSummary(
          id: 'recipe-1',
          dishName: 'Tomato Pasta',
          dishDescription: 'Simple dinner',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 20,
        ),
      ],
    );
    final CookSessionController controller = CookSessionController(
      repository: repository,
    );
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(controller: controller, authController: authController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    final Finder signOutButton = find.byKey(
      const ValueKey<String>('settings-sign-out-button'),
    );
    final Finder deleteAllButton = find.byKey(
      const ValueKey<String>('settings-delete-all-recipes-button'),
    );
    final Finder deleteAccountButton = find.byKey(
      const ValueKey<String>('settings-delete-account-button'),
    );

    expect(
      tester.getTopLeft(signOutButton).dy,
      lessThan(tester.getTopLeft(deleteAllButton).dy),
    );
    expect(
      tester.getTopLeft(deleteAllButton).dy,
      lessThan(tester.getTopLeft(deleteAccountButton).dy),
    );

    await tester.ensureVisible(deleteAllButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteAllButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete all data?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('delete-all-recipes-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.deleteAllRecipesCallCount, 1);

    await tester.tap(find.text('My recipes'));
    await tester.pumpAndSettle();

    expect(find.text('No saved recipes yet'), findsOneWidget);

    controller.dispose();
    authController.dispose();
  });

  testWidgets('delete all recipes failure shows snackbar', (tester) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(
        deleteAllRecipesError: const CulinexApiException(
          CulinexApiErrorCode.serverFailure,
        ),
      ),
    );
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(controller: controller, authController: authController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('settings-delete-all-recipes-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-delete-all-recipes-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('delete-all-recipes-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Data could not be deleted. Try again.'),
      findsOneWidget,
    );

    controller.dispose();
    authController.dispose();
  });

  testWidgets('bottom navigation is hidden during the cooking flow', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(controller: controller, authController: authController),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(_manualEntryButtonFinder('Type ingredients'));
    await tester.pumpAndSettle();

    expect(find.text('Manual entry'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('My recipes'), findsNothing);
    expect(find.text('Settings'), findsNothing);

    controller.dispose();
    authController.dispose();
  });

  testWidgets('my recipes tab lists saved recipes and opens detail', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(
        recipeSummaries: const [
          RecipeSummary(
            id: 'recipe-1',
            dishName: 'Tomato Pasta',
            dishDescription: 'Simple dinner',
            difficulty: RecipeDifficulty.easy,
            cookingTimeMinutes: 20,
          ),
        ],
        savedRecipe: GeneratedRecipe(
          id: 'recipe-1',
          dishName: 'Tomato Pasta',
          dishDescription: 'Simple dinner',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 20,
          ingredients: const [
            RecipeIngredient(name: 'Tomatoes', quantity: '2 pieces'),
            RecipeIngredient(name: 'Pasta', quantity: '90 g'),
          ],
          steps: const ['Boil pasta.', 'Add tomatoes.'],
          macros: const NutritionMacros(
            caloriesKcal: 320,
            proteinG: 12,
            carbsG: 54,
            fatG: 8,
          ),
        ),
      ),
    );
    final AuthController authController = _buildAuthenticatedAuthController();

    await tester.pumpWidget(
      CulinexApp(controller: controller, authController: authController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('My recipes'));
    await tester.pumpAndSettle();

    expect(find.text('Tomato Pasta'), findsOneWidget);
    expect(find.text('Simple dinner'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('20 min'), findsOneWidget);

    await tester.tap(find.text('Tomato Pasta'));
    await tester.pumpAndSettle();

    expect(find.text('Recipe ready'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('My recipes'), findsNothing);

    await tester.tap(find.byTooltip('Back to recipes'));
    await tester.pumpAndSettle();

    expect(find.text('My recipes'), findsWidgets);
    expect(find.text('Tomato Pasta'), findsOneWidget);

    controller.dispose();
    authController.dispose();
  });
}

class _NoopRepository implements CulinexRepository {
  _NoopRepository({
    List<RecipeSummary> recipeSummaries = const [],
    List<RecipeCollection> recipeCollections = const [],
    this.savedRecipe,
    this.deleteAllRecipesError,
  }) : recipeSummaries = List<RecipeSummary>.of(recipeSummaries),
       recipeCollections = List<RecipeCollection>.of(recipeCollections);

  final List<RecipeSummary> recipeSummaries;
  final List<RecipeCollection> recipeCollections;
  final GeneratedRecipe? savedRecipe;
  final List<String> deletedRecipeIds = <String>[];
  final Object? deleteAllRecipesError;
  int deleteAllRecipesCallCount = 0;

  @override
  void close() {}

  @override
  Future<List<ExtractedIngredient>> extractIngredients(
    imageFile, {
    required Locale locale,
  }) async {
    return const [];
  }

  @override
  Future<GeneratedRecipe> generateRecipe(
    RecipeGenerationRequest request, {
    required Locale locale,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<RecipeSummary>> listRecipes() async {
    return recipeSummaries;
  }

  @override
  Future<List<RecipeCollection>> listRecipeCollections() async {
    return recipeCollections;
  }

  @override
  Future<GeneratedRecipe> getRecipe(String id) async {
    final GeneratedRecipe? recipe = savedRecipe;
    if (recipe == null) {
      throw UnimplementedError();
    }
    return recipe;
  }

  @override
  Future<void> setRecipeFavorite(String id, bool isFavorite) async {}

  @override
  Future<RecipeCollection> createRecipeCollection(String name) async {
    final RecipeCollection collection = RecipeCollection(
      id: 'collection-${recipeCollections.length + 1}',
      name: name,
    );
    recipeCollections.add(collection);
    return collection;
  }

  @override
  Future<RecipeCollection> renameRecipeCollection(
    String id,
    String name,
  ) async {
    final int index = recipeCollections.indexWhere(
      (collection) => collection.id == id,
    );
    final RecipeCollection collection = RecipeCollection(id: id, name: name);
    if (index != -1) {
      recipeCollections[index] = collection;
    }
    return collection;
  }

  @override
  Future<void> deleteRecipeCollection(String id) async {
    recipeCollections.removeWhere((collection) => collection.id == id);
  }

  @override
  Future<void> setRecipeCollection(String id, String? collectionId) async {}

  @override
  Future<void> deleteRecipe(String id) async {
    deletedRecipeIds.add(id);
  }

  @override
  Future<void> deleteAllRecipes() async {
    deleteAllRecipesCallCount += 1;
    final Object? error = deleteAllRecipesError;
    if (error != null) {
      throw error;
    }
    recipeSummaries.clear();
    recipeCollections.clear();
  }
}

class _FakeThemeModeStore implements ThemeModeStore {
  final List<ThemeMode> savedModes = <ThemeMode>[];

  @override
  Future<ThemeMode> loadThemeMode() async {
    return ThemeMode.light;
  }

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    savedModes.add(themeMode);
  }
}

class _FakeLocaleStore implements LocaleStore {
  final List<Locale> savedLocales = <Locale>[];

  @override
  Future<Locale> loadLocale() async {
    return const Locale('en');
  }

  @override
  Future<void> saveLocale(Locale locale) async {
    savedLocales.add(locale);
  }
}

AuthController _buildAuthenticatedAuthController() {
  return AuthController(
    authClient: _FakeAuthClient(),
    sessionStore: _MemorySessionStore(
      initialSession: AuthSession(
        user: const AuthUser(
          id: 'user-1',
          fullName: 'Ada Lovelace',
          email: 'ada@example.com',
        ),
        accessToken: 'access-token',
        accessTokenExpiresAt: DateTime.now().toUtc().add(
          const Duration(minutes: 15),
        ),
        refreshToken: 'refresh-token',
        refreshTokenExpiresAt: DateTime.now().toUtc().add(
          const Duration(days: 30),
        ),
      ),
    ),
  );
}

class _FakeAuthClient implements AuthClient {
  String? deletedAccountAccessToken;

  @override
  void close() {}

  @override
  Future<void> checkEmail({required String email}) async {}

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return _buildSession();
  }

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<void> deleteAccount({required String accessToken}) async {
    deletedAccountAccessToken = accessToken;
  }

  @override
  Future<AuthSession> refresh({required String refreshToken}) async {
    return _buildSession();
  }

  @override
  Future<AuthSession> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return _buildSession();
  }
}

class _MemorySessionStore implements AuthSessionStore {
  _MemorySessionStore({AuthSession? initialSession})
    : _session = initialSession;

  AuthSession? _session;

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<AuthSession?> loadSession() async {
    return _session;
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    _session = session;
  }
}

AuthSession _buildSession() {
  return AuthSession(
    user: const AuthUser(
      id: 'user-1',
      fullName: 'Ada Lovelace',
      email: 'ada@example.com',
    ),
    accessToken: 'access-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(
      const Duration(minutes: 15),
    ),
    refreshToken: 'refresh-token',
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
  );
}
