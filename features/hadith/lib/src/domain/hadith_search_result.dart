class HadithSearchResult {
  const HadithSearchResult({
    required this.id,
    required this.languageCode,
    required this.title,
    required this.hadithText,
    required this.explanation,
    required this.attribution,
    required this.grade,
  });

  final int id;
  final String languageCode;
  final String title;
  final String hadithText;
  final String explanation;
  final String attribution;
  final String grade;
}
