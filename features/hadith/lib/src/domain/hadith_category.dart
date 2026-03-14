class HadithCategory {
  const HadithCategory({
    required this.id,
    required this.languageCode,
    required this.title,
    required this.hadithCount,
    this.parentId,
    this.cachedHadithCount = 0,
    this.lastSyncedAt,
  });

  final int id;
  final String languageCode;
  final String title;
  final int hadithCount;
  final int? parentId;
  final int cachedHadithCount;
  final DateTime? lastSyncedAt;

  bool get isDownloaded => cachedHadithCount >= hadithCount && hadithCount > 0;

  HadithCategory copyWith({
    int? id,
    String? languageCode,
    String? title,
    int? hadithCount,
    int? parentId,
    int? cachedHadithCount,
    DateTime? lastSyncedAt,
  }) {
    return HadithCategory(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      title: title ?? this.title,
      hadithCount: hadithCount ?? this.hadithCount,
      parentId: parentId ?? this.parentId,
      cachedHadithCount: cachedHadithCount ?? this.cachedHadithCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
