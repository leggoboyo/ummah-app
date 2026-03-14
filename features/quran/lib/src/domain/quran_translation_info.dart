class QuranTranslationInfo {
  const QuranTranslationInfo({
    required this.key,
    required this.languageCode,
    required this.version,
    required this.title,
    required this.description,
    required this.direction,
    required this.attribution,
    required this.lastRemoteUpdate,
    this.databaseUrl,
    this.databaseUncompressedUrl,
    this.isDownloaded = false,
    this.cachedAyahCount = 0,
    this.totalAyahCount = 0,
    this.lastSyncedAt,
  });

  final String key;
  final String languageCode;
  final String version;
  final String title;
  final String description;
  final String direction;
  final String attribution;
  final DateTime lastRemoteUpdate;
  final String? databaseUrl;
  final String? databaseUncompressedUrl;
  final bool isDownloaded;
  final int cachedAyahCount;
  final int totalAyahCount;
  final DateTime? lastSyncedAt;

  bool get isFullyDownloaded =>
      totalAyahCount > 0 && cachedAyahCount >= totalAyahCount;

  QuranTranslationInfo copyWith({
    String? key,
    String? languageCode,
    String? version,
    String? title,
    String? description,
    String? direction,
    String? attribution,
    DateTime? lastRemoteUpdate,
    String? databaseUrl,
    String? databaseUncompressedUrl,
    bool? isDownloaded,
    int? cachedAyahCount,
    int? totalAyahCount,
    DateTime? lastSyncedAt,
  }) {
    return QuranTranslationInfo(
      key: key ?? this.key,
      languageCode: languageCode ?? this.languageCode,
      version: version ?? this.version,
      title: title ?? this.title,
      description: description ?? this.description,
      direction: direction ?? this.direction,
      attribution: attribution ?? this.attribution,
      lastRemoteUpdate: lastRemoteUpdate ?? this.lastRemoteUpdate,
      databaseUrl: databaseUrl ?? this.databaseUrl,
      databaseUncompressedUrl:
          databaseUncompressedUrl ?? this.databaseUncompressedUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      cachedAyahCount: cachedAyahCount ?? this.cachedAyahCount,
      totalAyahCount: totalAyahCount ?? this.totalAyahCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
