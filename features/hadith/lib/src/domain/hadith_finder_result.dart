import 'hadith_search_result.dart';

class HadithFinderResult {
  const HadithFinderResult({
    required this.result,
    required this.score,
    required this.confidence,
    required this.matchReasons,
    required this.matchedTerms,
    required this.matchedTopics,
    required this.exactPhraseMatch,
    required this.usedLanguageFallback,
  });

  final HadithSearchResult result;
  final double score;
  final double confidence;
  final List<String> matchReasons;
  final List<String> matchedTerms;
  final List<String> matchedTopics;
  final bool exactPhraseMatch;
  final bool usedLanguageFallback;
}
