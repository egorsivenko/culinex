import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/feedback/haptics_store.dart';
import 'core/feedback/sounds_store.dart';
import 'core/localization/locale_store.dart';
import 'core/theme/theme_mode_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);

  final ThemeModeStore themeModeStore = SharedPreferencesThemeModeStore();
  final LocaleStore localeStore = SharedPreferencesLocaleStore();
  final HapticsStore hapticsStore = SharedPreferencesHapticsStore();
  final SoundsStore soundsStore = SharedPreferencesSoundsStore();
  final Future<ThemeMode> initialThemeModeFuture = themeModeStore
      .loadThemeMode();
  final Future<Locale> initialLocaleFuture = localeStore.loadLocale();
  final Future<bool> initialHapticsEnabledFuture = hapticsStore
      .loadHapticsEnabled();
  final Future<bool> initialSoundsEnabledFuture = soundsStore
      .loadSoundsEnabled();
  final ThemeMode initialThemeMode = await initialThemeModeFuture;
  final Locale initialLocale = await initialLocaleFuture;
  final bool initialHapticsEnabled = await initialHapticsEnabledFuture;
  final bool initialSoundsEnabled = await initialSoundsEnabledFuture;

  runApp(
    CulinexApp(
      initialThemeMode: initialThemeMode,
      themeModeStore: themeModeStore,
      initialLocale: initialLocale,
      localeStore: localeStore,
      initialHapticsEnabled: initialHapticsEnabled,
      hapticsStore: hapticsStore,
      initialSoundsEnabled: initialSoundsEnabled,
      soundsStore: soundsStore,
    ),
  );
}
