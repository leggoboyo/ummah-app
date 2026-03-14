import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_profile.dart';

abstract interface class AppProfileStore {
  Future<AppProfile> load();

  Future<void> save(AppProfile profile);
}

class SharedPreferencesAppProfileStore implements AppProfileStore {
  SharedPreferencesAppProfileStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _profileKey = 'app_profile_v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppProfile> load() async {
    final String? raw = await _preferences.getString(_profileKey);
    if (raw == null || raw.isEmpty) {
      return AppProfile.defaults();
    }

    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      return AppProfile.fromJson(json);
    } catch (_) {
      return AppProfile.defaults();
    }
  }

  @override
  Future<void> save(AppProfile profile) {
    return _preferences.setString(_profileKey, jsonEncode(profile.toJson()));
  }
}

class InMemoryAppProfileStore implements AppProfileStore {
  InMemoryAppProfileStore([AppProfile? initialProfile])
      : _profile = initialProfile ?? AppProfile.defaults();

  AppProfile _profile;

  @override
  Future<AppProfile> load() async => _profile;

  @override
  Future<void> save(AppProfile profile) async {
    _profile = profile;
  }
}
