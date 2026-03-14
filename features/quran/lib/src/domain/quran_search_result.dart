class QuranSearchResult {
  const QuranSearchResult({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahArabicName,
    required this.surahEnglishName,
    required this.arabicText,
    this.translationKey,
    this.translationText,
    this.footnotes,
    this.matchScope = QuranSearchScope.arabic,
  });

  final int surahNumber;
  final int ayahNumber;
  final String surahArabicName;
  final String surahEnglishName;
  final String arabicText;
  final String? translationKey;
  final String? translationText;
  final String? footnotes;
  final QuranSearchScope matchScope;
}

enum QuranSearchScope {
  arabic,
  translation,
}
