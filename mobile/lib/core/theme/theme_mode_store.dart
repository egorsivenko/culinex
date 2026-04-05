import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ThemeModeStore {
  Future<ThemeMode> loadThemeMode();

  Future<void> saveThemeMode(ThemeMode themeMode);
}

class SharedPreferencesThemeModeStore implements ThemeModeStore {
  SharedPreferencesThemeModeStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _themeModeKey = 'ui.theme_mode';

  final SharedPreferencesAsync _preferences;

  @override
  Future<ThemeMode> loadThemeMode() async {
    final String? value = await _preferences.getString(_themeModeKey);

    return switch (value) {
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) {
    return _preferences.setString(_themeModeKey, themeMode.name);
  }
}
