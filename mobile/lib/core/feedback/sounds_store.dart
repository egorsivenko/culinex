import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SoundsStore {
  Future<bool> loadSoundsEnabled();

  Future<void> saveSoundsEnabled(bool isEnabled);
}

class SharedPreferencesSoundsStore implements SoundsStore {
  SharedPreferencesSoundsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _soundsEnabledKey = 'ui.sounds_enabled';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> loadSoundsEnabled() async {
    return await _preferences.getBool(_soundsEnabledKey) ?? true;
  }

  @override
  Future<void> saveSoundsEnabled(bool isEnabled) {
    return _preferences.setBool(_soundsEnabledKey, isEnabled);
  }
}
