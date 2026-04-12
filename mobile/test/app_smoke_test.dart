import 'package:culinex/app/app.dart';
import 'package:culinex/core/localization/locale_store.dart';
import 'package:culinex/core/network/culinex_repository.dart';
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

void main() {
  testWidgets('app opens on the welcome screen', (tester) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );

    await tester.pumpWidget(CulinexApp(controller: controller));

    expect(find.text('Culinex'), findsOneWidget);
    expect(find.text('Use the camera'), findsOneWidget);
    expect(find.text('Type ingredients'), findsOneWidget);
    expect(find.text('Enter ingredients manually'), findsOneWidget);
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
  });

  testWidgets('manual entry button opens the ingredient screen', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );

    await tester.pumpWidget(CulinexApp(controller: controller));
    await tester.ensureVisible(find.text('Type ingredients'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Type ingredients'));
    await tester.pumpAndSettle();

    expect(find.text('Manual entry'), findsOneWidget);
    expect(find.text('Add your ingredients'), findsOneWidget);
    expect(find.text('No ingredients added yet'), findsOneWidget);
    expect(find.text('View original photo'), findsNothing);

    controller.dispose();
  });

  testWidgets('language toggle switches between English and Ukrainian', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );

    await tester.pumpWidget(CulinexApp(controller: controller));

    MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en'));
    expect(find.text('Use the camera'), findsOneWidget);
    expect(find.text('Використати камеру'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('language-toggle-button')),
    );
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('uk'));
    expect(find.text('Use the camera'), findsNothing);
    expect(find.text('Використати камеру'), findsOneWidget);
    expect(find.text('Ввести інгредієнти'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('theme toggle switches between light and dark modes on welcome', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );

    await tester.pumpWidget(CulinexApp(controller: controller));

    MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
    expect(find.text('Use the camera'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('theme-toggle-button')));
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsNothing);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.text('Use the camera'), findsOneWidget);
    expect(find.text('Type ingredients'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('app can start in dark mode from persisted theme', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );

    await tester.pumpWidget(
      CulinexApp(controller: controller, initialThemeMode: ThemeMode.dark),
    );

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.themeMode, ThemeMode.dark);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsNothing);

    controller.dispose();
  });

  testWidgets('app can start in Ukrainian from persisted locale', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );

    await tester.pumpWidget(
      CulinexApp(controller: controller, initialLocale: const Locale('uk')),
    );

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.locale, const Locale('uk'));
    expect(find.text('Використати камеру'), findsOneWidget);
    expect(find.text('Ввести інгредієнти'), findsOneWidget);
    expect(find.text('Use the camera'), findsNothing);

    controller.dispose();
  });

  testWidgets('theme toggle persists the selected theme', (tester) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final _FakeThemeModeStore themeModeStore = _FakeThemeModeStore();

    await tester.pumpWidget(
      CulinexApp(controller: controller, themeModeStore: themeModeStore),
    );

    await tester.tap(find.byKey(const ValueKey<String>('theme-toggle-button')));
    await tester.pumpAndSettle();

    expect(themeModeStore.savedModes, <ThemeMode>[ThemeMode.dark]);

    controller.dispose();
  });

  testWidgets('language toggle persists the selected locale', (tester) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );
    final _FakeLocaleStore localeStore = _FakeLocaleStore();

    await tester.pumpWidget(
      CulinexApp(controller: controller, localeStore: localeStore),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('language-toggle-button')),
    );
    await tester.pumpAndSettle();

    expect(localeStore.savedLocales, <Locale>[const Locale('uk')]);

    controller.dispose();
  });
}

class _NoopRepository implements CulinexRepository {
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
