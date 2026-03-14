import 'hadith_search_result.dart';

class HadithFinderResult {
  const HadithFinderResult({
    required this.result,
    required this.score,
    required this.matchReasons,
    required this.usedLanguageFallback,
  });

  final HadithSearchResult result;
  final double score;
  final List<String> matchReasons;
  final bool usedLanguageFallback;
}
