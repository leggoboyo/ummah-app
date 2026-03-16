import 'dart:math';

import 'package:core/core.dart';

import 'flutter_secure_value_store.dart';
import 'shared_preferences_key_value_store.dart';

abstract interface class AppIdentityStore {
  Future<String> ensureAppUserId();

  Future<String?> readAppUserId();

  Future<String> ensureRevenueCatAppUserId();

  Future<String?> readRevenueCatAppUserId();
}

class SecureAppIdentityStore implements AppIdentityStore {
  SecureAppIdentityStore({
    SecureValueStore? secureValueStore,
    KeyValueStore? legacyKeyValueStore,
    Random? random,
  })  : _secureValueStore = secureValueStore ?? FlutterSecureValueStore(),
        _legacyKeyValueStore =
            legacyKeyValueStore ?? SharedPreferencesKeyValueStore(),
        _random = random ?? Random.secure();

  static const String _revenueCatAppUserIdKey = 'revenuecat_app_user_id_v1';

  final SecureValueStore _secureValueStore;
  final KeyValueStore _legacyKeyValueStore;
  final Random _random;

  @override
  Future<String> ensureAppUserId() async {
    final String? existing = await readAppUserId();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final String generated = _generateAppUserId();
    await _secureValueStore.writeSecret(_revenueCatAppUserIdKey, generated);
    return generated;
  }

  @override
  Future<String?> readAppUserId() async {
    final String? secureValue =
        await _secureValueStore.readSecret(_revenueCatAppUserIdKey);
    if (secureValue != null && secureValue.isNotEmpty) {
      return secureValue;
    }

    final String? legacyValue =
        await _legacyKeyValueStore.readString(_revenueCatAppUserIdKey);
    if (legacyValue == null || legacyValue.isEmpty) {
      return null;
    }

    await _secureValueStore.writeSecret(_revenueCatAppUserIdKey, legacyValue);
    await _legacyKeyValueStore.remove(_revenueCatAppUserIdKey);
    return legacyValue;
  }

  @override
  Future<String> ensureRevenueCatAppUserId() {
    return ensureAppUserId();
  }

  @override
  Future<String?> readRevenueCatAppUserId() {
    return readAppUserId();
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
