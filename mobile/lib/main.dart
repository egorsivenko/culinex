import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/localization/locale_store.dart';
import 'core/theme/theme_mode_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ThemeModeStore themeModeStore = SharedPreferencesThemeModeStore();
  final LocaleStore localeStore = SharedPreferencesLocaleStore();
  final Future<ThemeMode> initialThemeModeFuture = themeModeStore
      .loadThemeMode();
  final Future<Locale> initialLocaleFuture = localeStore.loadLocale();
  final ThemeMode initialThemeMode = await initialThemeModeFuture;
  final Locale initialLocale = await initialLocaleFuture;

  runApp(
    CulinexApp(
      initialThemeMode: initialThemeMode,
      themeModeStore: themeModeStore,
      initialLocale: initialLocale,
      localeStore: localeStore,
    ),
  );
}
