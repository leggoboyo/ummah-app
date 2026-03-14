import 'dart:math';

import 'package:core/core.dart';

import 'shared_preferences_key_value_store.dart';

abstract interface class AppIdentityStore {
  Future<String> ensureRevenueCatAppUserId();

  Future<String?> readRevenueCatAppUserId();
}

class SharedPreferencesAppIdentityStore implements AppIdentityStore {
  SharedPreferencesAppIdentityStore({
    KeyValueStore? keyValueStore,
    Random? random,
  })  : _keyValueStore = keyValueStore ?? SharedPreferencesKeyValueStore(),
        _random = random ?? Random.secure();

  static const String _revenueCatAppUserIdKey = 'revenuecat_app_user_id_v1';

  final KeyValueStore _keyValueStore;
  final Random _random;

  @override
  Future<String> ensureRevenueCatAppUserId() async {
    final String? existing = await readRevenueCatAppUserId();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final String generated = _generateAppUserId();
    await _keyValueStore.writeString(_revenueCatAppUserIdKey, generated);
    return generated;
  }

  @override
  Future<String?> readRevenueCatAppUserId() {
    return _keyValueStore.readString(_revenueCatAppUserIdKey);
  }

  String _generateAppUserId() {
    final StringBuffer buffer = StringBuffer('ummah_');
    for (int index = 0; index < 16; index += 1) {
      final int value = _random.nextInt(256);
      buffer.write(value.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
