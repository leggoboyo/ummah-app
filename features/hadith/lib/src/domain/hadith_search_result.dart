class HadithSearchResult {
  const HadithSearchResult({
    required this.id,
    required this.languageCode,
    required this.title,
    required this.hadithText,
    required this.explanation,
    required this.attribution,
    required this.grade,
    this.sourceReference = '',
    this.sourceUrl = '',
    this.matchReasons = const <String>[],
  });

  final int id;
  final String languageCode;
  final String title;
  final String hadithText;
  final String explanation;
  final String attribution;
  final String grade;
  final String sourceReference;
  final String sourceUrl;
  final List<String> matchReasons;
}
