import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_identity_store.dart';

void main() {
  test('migrates legacy shared-preferences app user id into secure storage', () async {
    final _InMemorySecureValueStore secureStore = _InMemorySecureValueStore();
    final _InMemoryKeyValueStore legacyStore = _InMemoryKeyValueStore()
      ..values['revenuecat_app_user_id_v1'] = 'ummah_legacy_user_id';
    final SecureAppIdentityStore store = SecureAppIdentityStore(
      secureValueStore: secureStore,
      legacyKeyValueStore: legacyStore,
      random: Random(1),
    );

    final String? value = await store.readAppUserId();

    expect(value, 'ummah_legacy_user_id');
    expect(
      await secureStore.readSecret('revenuecat_app_user_id_v1'),
      'ummah_legacy_user_id',
    );
    expect(legacyStore.values.containsKey('revenuecat_app_user_id_v1'), isFalse);
  });

  test('generates and stores new app user ids in secure storage', () async {
    final _InMemorySecureValueStore secureStore = _InMemorySecureValueStore();
    final SecureAppIdentityStore store = SecureAppIdentityStore(
      secureValueStore: secureStore,
      legacyKeyValueStore: _InMemoryKeyValueStore(),
      random: Random(7),
    );

    final String value = await store.ensureAppUserId();

    expect(value, startsWith('ummah_'));
    expect(value, hasLength(38));
    expect(
      await secureStore.readSecret('revenuecat_app_user_id_v1'),
      value,
    );
  });
}

class _InMemorySecureValueStore implements SecureValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> removeSecret(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> readSecret(String key) async => _values[key];

  @override
  Future<void> writeSecret(String key, String value) async {
    _values[key] = value;
  }
}

class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}
