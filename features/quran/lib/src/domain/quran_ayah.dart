class QuranAyah {
  const QuranAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabicText,
    this.translationKey,
    this.translationText,
    this.footnotes,
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabicText;
  final String? translationKey;
  final String? translationText;
  final String? footnotes;
}
