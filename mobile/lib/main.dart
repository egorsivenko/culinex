import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/theme/theme_mode_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ThemeModeStore themeModeStore = SharedPreferencesThemeModeStore();
  final ThemeMode initialThemeMode = await themeModeStore.loadThemeMode();

  runApp(
    CulinexApp(
      initialThemeMode: initialThemeMode,
      themeModeStore: themeModeStore,
    ),
  );
}
