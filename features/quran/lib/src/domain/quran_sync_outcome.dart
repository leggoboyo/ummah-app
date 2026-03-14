class QuranSyncOutcome {
  const QuranSyncOutcome({
    required this.insertedVerses,
    required this.completedSurahs,
    required this.totalSurahs,
  });

  final int insertedVerses;
  final int completedSurahs;
  final int totalSurahs;

  bool get completed => completedSurahs >= totalSurahs;
}
