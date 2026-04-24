import 'package:shared_preferences/shared_preferences.dart';

abstract interface class HapticsStore {
  Future<bool> loadHapticsEnabled();

  Future<void> saveHapticsEnabled(bool isEnabled);
}

class SharedPreferencesHapticsStore implements HapticsStore {
  SharedPreferencesHapticsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _hapticsEnabledKey = 'ui.haptics_enabled';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> loadHapticsEnabled() async {
    return await _preferences.getBool(_hapticsEnabledKey) ?? true;
  }

  @override
  Future<void> saveHapticsEnabled(bool isEnabled) {
    return _preferences.setBool(_hapticsEnabledKey, isEnabled);
  }
}
