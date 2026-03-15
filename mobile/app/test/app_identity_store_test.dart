import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_identity_store.dart';

void main() {
  test(
      'migrates the existing app user id from shared preferences to secure storage',
      () async {
    final _InMemorySecureValueStore secureStore = _InMemorySecureValueStore();
    final _InMemoryKeyValueStore keyValueStore = _InMemoryKeyValueStore()
      ..values['revenuecat_app_user_id_v1'] =
          'ummah_0123456789abcdef0123456789abcdef';

    final SecureAppIdentityStore store = SecureAppIdentityStore(
      secureValueStore: secureStore,
      keyValueStore: keyValueStore,
      random: Random(1),
    );

    final String? migrated = await store.readRevenueCatAppUserId();

    expect(migrated, 'ummah_0123456789abcdef0123456789abcdef');
    expect(
      secureStore.values['revenuecat_app_user_id_v1'],
      'ummah_0123456789abcdef0123456789abcdef',
    );
    expect(
        keyValueStore.values.containsKey('revenuecat_app_user_id_v1'), isFalse);
  });

  test('generates new ids directly into secure storage', () async {
    final _InMemorySecureValueStore secureStore = _InMemorySecureValueStore();
    final _InMemoryKeyValueStore keyValueStore = _InMemoryKeyValueStore();
    final SecureAppIdentityStore store = SecureAppIdentityStore(
      secureValueStore: secureStore,
      keyValueStore: keyValueStore,
      random: Random(7),
    );

    final String generated = await store.ensureRevenueCatAppUserId();

    expect(generated, startsWith('ummah_'));
    expect(generated.length, 38);
    expect(secureStore.values['revenuecat_app_user_id_v1'], generated);
    expect(keyValueStore.values, isEmpty);
  });
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

class _InMemorySecureValueStore implements SecureValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> readSecret(String key) async => values[key];

  @override
  Future<void> removeSecret(String key) async {
    values.remove(key);
  }

  @override
  Future<void> writeSecret(String key, String value) async {
    values[key] = value;
  }
}
