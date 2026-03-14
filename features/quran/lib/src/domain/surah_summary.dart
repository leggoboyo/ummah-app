class SurahSummary {
  const SurahSummary({
    required this.number,
    required this.arabicName,
    required this.transliteration,
    required this.englishName,
    required this.ayahCount,
    required this.revelationType,
    required this.revelationOrder,
    required this.rukus,
  });

  final int number;
  final String arabicName;
  final String transliteration;
  final String englishName;
  final int ayahCount;
  final String revelationType;
  final int revelationOrder;
  final int rukus;
}
