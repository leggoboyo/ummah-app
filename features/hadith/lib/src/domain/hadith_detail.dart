class HadithDetail {
  const HadithDetail({
    required this.id,
    required this.languageCode,
    required this.title,
    required this.hadithText,
    required this.attribution,
    required this.grade,
    required this.explanation,
    required this.hints,
    required this.categoryIds,
    required this.translations,
    required this.hadithIntro,
    required this.hadithArabic,
    required this.hadithIntroArabic,
    required this.explanationArabic,
    required this.hintsArabic,
    required this.wordsMeaningsArabic,
    required this.attributionArabic,
    required this.gradeArabic,
    this.lastSyncedAt,
  });

  final int id;
  final String languageCode;
  final String title;
  final String hadithText;
  final String attribution;
  final String grade;
  final String explanation;
  final List<String> hints;
  final List<int> categoryIds;
  final List<String> translations;
  final String hadithIntro;
  final String hadithArabic;
  final String hadithIntroArabic;
  final String explanationArabic;
  final List<String> hintsArabic;
  final List<String> wordsMeaningsArabic;
  final String attributionArabic;
  final String gradeArabic;
  final DateTime? lastSyncedAt;
}
