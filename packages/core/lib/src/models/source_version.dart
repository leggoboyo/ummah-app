class SourceVersion {
  const SourceVersion({
    required this.providerKey,
    required this.contentKey,
    required this.languageCode,
    required this.version,
    required this.attribution,
    this.lastSyncedAt,
  });

  final String providerKey;
  final String contentKey;
  final String languageCode;
  final String version;
  final String attribution;
  final DateTime? lastSyncedAt;

  SourceVersion copyWith({
    String? providerKey,
    String? contentKey,
    String? languageCode,
    String? version,
    String? attribution,
    DateTime? lastSyncedAt,
  }) {
    return SourceVersion(
      providerKey: providerKey ?? this.providerKey,
      contentKey: contentKey ?? this.contentKey,
      languageCode: languageCode ?? this.languageCode,
      version: version ?? this.version,
      attribution: attribution ?? this.attribution,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
