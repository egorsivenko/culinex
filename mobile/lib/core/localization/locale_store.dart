import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';

abstract interface class LocaleStore {
  Future<Locale> loadLocale();

  Future<void> saveLocale(Locale locale);
}

class SharedPreferencesLocaleStore implements LocaleStore {
  SharedPreferencesLocaleStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _localeKey = 'ui.locale';

  final SharedPreferencesAsync _preferences;

  @override
  Future<Locale> loadLocale() async {
    final String? value = await _preferences.getString(_localeKey);
    if (value == null || value.isEmpty) {
      return AppLocale.english;
    }

    return AppLocale.normalize(Locale(value));
  }

  @override
  Future<void> saveLocale(Locale locale) {
    return _preferences.setString(
      _localeKey,
      AppLocale.normalize(locale).languageCode,
    );
  }
}
