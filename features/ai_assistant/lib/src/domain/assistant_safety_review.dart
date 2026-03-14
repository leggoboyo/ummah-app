class AssistantSafetyReview {
  const AssistantSafetyReview({
    required this.isHighRisk,
    required this.notice,
    required this.nextStep,
  });

  static const AssistantSafetyReview standard = AssistantSafetyReview(
    isHighRisk: false,
    notice:
        'This assistant is a study aid. It is not a scholar or mufti, and it should be used with source awareness.',
    nextStep:
        'Review the cited sources and consult a qualified scholar when your situation is specific or complicated.',
  );

  final bool isHighRisk;
  final String notice;
  final String nextStep;

  factory AssistantSafetyReview.review(String query) {
    final String normalized = query.toLowerCase();
    const List<String> highRiskKeywords = <String>[
      'divorce',
      'talaq',
      'suicide',
      'self harm',
      'kill',
      'violence',
      'abuse',
      'medical',
      'doctor',
      'pregnant',
      'pregnancy',
      'abortion',
      'court',
      'legal',
      'lawyer',
      'crime',
      'police',
      'visa',
      'custody',
      'marriage contract',
    ];

    for (final String keyword in highRiskKeywords) {
      if (normalized.contains(keyword)) {
        return const AssistantSafetyReview(
          isHighRisk: true,
          notice:
              'High-risk topic detected. This assistant cannot give definitive rulings for divorce, violence, suicide, medical, legal, or similarly context-heavy cases.',
          nextStep:
              'Use the cited sources as a starting point, then consult a qualified scholar and, where relevant, a licensed medical or legal professional.',
        );
      }
    }

    return standard;
  }
}
