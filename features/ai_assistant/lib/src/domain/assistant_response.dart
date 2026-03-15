import 'package:core/core.dart';

import 'assistant_safety_review.dart';

class AssistantResponse {
  const AssistantResponse({
    required this.answer,
    required this.commentary,
    required this.sources,
    required this.sourceVersions,
    required this.safetyReview,
    required this.generatedAt,
    this.hasSufficientEvidence = true,
  });

  final String answer;
  final String commentary;
  final List<RetrievedPassage> sources;
  final List<SourceVersion> sourceVersions;
  final AssistantSafetyReview safetyReview;
  final DateTime generatedAt;
  final bool hasSufficientEvidence;
}
