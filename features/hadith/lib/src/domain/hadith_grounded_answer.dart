import 'hadith_finder_result.dart';

enum HadithGroundedAnswerStatus {
  answered,
  related,
  noEvidence,
}

class HadithGroundedAnswer {
  const HadithGroundedAnswer({
    required this.query,
    required this.status,
    required this.headline,
    required this.answerText,
    required this.guidanceText,
    required this.citations,
    required this.confidence,
    required this.usedLanguageFallback,
  });

  final String query;
  final HadithGroundedAnswerStatus status;
  final String headline;
  final String answerText;
  final String guidanceText;
  final List<HadithFinderResult> citations;
  final double confidence;
  final bool usedLanguageFallback;

  bool get hasCitations => citations.isNotEmpty;
}
