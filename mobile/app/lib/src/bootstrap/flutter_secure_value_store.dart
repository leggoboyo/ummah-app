import 'package:core/core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FlutterSecureValueStore implements SecureValueStore {
  FlutterSecureValueStore({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> removeSecret(String key) {
    return _storage.delete(key: key);
  }

  @override
  Future<String?> readSecret(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> writeSecret(String key, String value) {
    return _storage.write(key: key, value: value);
  }
}
