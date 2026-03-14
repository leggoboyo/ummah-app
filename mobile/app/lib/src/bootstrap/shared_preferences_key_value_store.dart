import 'package:core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences;

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _resolvedPreferences =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<String?> readString(String key) {
    return _resolvedPreferences.getString(key);
  }

  @override
  Future<void> remove(String key) {
    return _resolvedPreferences.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) {
    return _resolvedPreferences.setString(key, value);
  }
}
