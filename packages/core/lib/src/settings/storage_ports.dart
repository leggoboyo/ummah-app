abstract interface class KeyValueStore {
  Future<void> writeString(String key, String value);

  Future<String?> readString(String key);

  Future<void> remove(String key);
}

abstract interface class SecureValueStore {
  Future<void> writeSecret(String key, String value);

  Future<String?> readSecret(String key);

  Future<void> removeSecret(String key);
}

abstract interface class LocalDatabasePort {
  Future<void> execute(String statement);
}
