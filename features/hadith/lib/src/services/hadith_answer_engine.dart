import '../domain/hadith_finder_result.dart';
import '../domain/hadith_grounded_answer.dart';

class HadithAnswerEngine {
  const HadithAnswerEngine();

  HadithGroundedAnswer build({
    required String query,
    required int significantTokenCount,
    required List<HadithFinderResult> candidates,
  }) {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.length < 2 || significantTokenCount == 0) {
      return HadithGroundedAnswer(
        query: trimmedQuery,
        status: HadithGroundedAnswerStatus.noEvidence,
        headline: 'Ask a clearer hadith question',
        answerText:
            'I could not read a clear hadith question from that text yet.',
        guidanceText:
            'Try a short topic phrase like "anger with parents", "honesty in trade", or "forgiveness after sin".',
        citations: const <HadithFinderResult>[],
        confidence: 0,
        usedLanguageFallback: false,
      );
    }

    if (candidates.isEmpty) {
      return HadithGroundedAnswer(
        query: trimmedQuery,
        status: HadithGroundedAnswerStatus.noEvidence,
        headline: 'No reliable hadith found',
        answerText:
            'I could not find a reliable hadith in the installed packs that directly addresses this question.',
        guidanceText:
            'Try a clearer topic phrase, install another hadith pack, or consult a qualified scholar for a context-specific answer.',
        citations: const <HadithFinderResult>[],
        confidence: 0,
        usedLanguageFallback: false,
      );
    }

    final List<HadithFinderResult> reliableCandidates = candidates
        .where(
          (HadithFinderResult candidate) => _isReliableEnough(
            candidate,
            significantTokenCount: significantTokenCount,
          ),
        )
        .take(3)
        .toList(growable: false);

    if (reliableCandidates.isEmpty) {
      return HadithGroundedAnswer(
        query: trimmedQuery,
        status: HadithGroundedAnswerStatus.noEvidence,
        headline: 'No direct hadith found in this pack',
        answerText:
            'I could not find a reliable hadith in the installed packs that directly addresses this question.',
        guidanceText:
            'Try a clearer topic phrase, install another hadith pack, or consult a qualified scholar for a context-specific answer.',
        citations: const <HadithFinderResult>[],
        confidence: 0,
        usedLanguageFallback: false,
      );
    }

    final HadithFinderResult top = reliableCandidates.first;
    final HadithFinderResult? second =
        reliableCandidates.length > 1 ? reliableCandidates[1] : null;
    final double confidence = _confidenceFor(
      top,
      significantTokenCount: significantTokenCount,
    );
    final HadithGroundedAnswerStatus status = _classify(
      top,
      second: second,
      significantTokenCount: significantTokenCount,
    );
    final List<HadithFinderResult> citations =
        status == HadithGroundedAnswerStatus.noEvidence
            ? const <HadithFinderResult>[]
            : reliableCandidates;

    switch (status) {
      case HadithGroundedAnswerStatus.answered:
        return HadithGroundedAnswer(
          query: trimmedQuery,
          status: status,
          headline: 'Answer from cited hadith',
          answerText: _summaryFor(top),
          guidanceText:
              'Open a source below for the full hadith, explanation, and source.',
          citations: citations,
          confidence: confidence,
          usedLanguageFallback: top.usedLanguageFallback,
        );
      case HadithGroundedAnswerStatus.related:
        return HadithGroundedAnswer(
          query: trimmedQuery,
          status: status,
          headline: 'Closest related guidance',
          answerText:
              'I could not find a clear direct hadith for this exact question.',
          guidanceText:
              'I found related hadith below that may still help as references.',
          citations: citations,
          confidence: confidence,
          usedLanguageFallback: top.usedLanguageFallback,
        );
      case HadithGroundedAnswerStatus.noEvidence:
        return HadithGroundedAnswer(
          query: trimmedQuery,
          status: status,
          headline: 'No clear hadith found',
          answerText:
              'I could not find a reliable hadith in the installed packs that directly answers this question.',
          guidanceText:
              'Try rephrasing the topic, installing another hadith pack, or asking a qualified scholar for a context-specific answer.',
          citations: const <HadithFinderResult>[],
          confidence: confidence,
          usedLanguageFallback: top.usedLanguageFallback,
        );
    }
  }

  HadithGroundedAnswerStatus _classify(
    HadithFinderResult top, {
    required HadithFinderResult? second,
    required int significantTokenCount,
  }) {
    final double coverage =
        _termCoverage(top, significantTokenCount: significantTokenCount);
    final double gap = second == null ? top.score : top.score - second.score;
    final bool strongField = _hasStrongGrounding(top);

    if (top.exactPhraseMatch && top.score >= 40) {
      return HadithGroundedAnswerStatus.answered;
    }
    if (top.score >= 48 && strongField && top.matchedTopics.length >= 2) {
      return HadithGroundedAnswerStatus.answered;
    }
    if (top.score >= 72 && coverage >= 0.5 && strongField) {
      return HadithGroundedAnswerStatus.answered;
    }
    if (top.score >= 52 &&
        coverage >= 0.67 &&
        strongField &&
        (gap >= 8 || second == null)) {
      return HadithGroundedAnswerStatus.answered;
    }
    if (top.score >= 36 &&
        (coverage >= 0.34 || top.matchedTopics.isNotEmpty || strongField)) {
      return HadithGroundedAnswerStatus.related;
    }
    return HadithGroundedAnswerStatus.noEvidence;
  }

  bool _isReliableEnough(
    HadithFinderResult result, {
    required int significantTokenCount,
  }) {
    if (result.exactPhraseMatch) {
      return true;
    }
    if (result.score < 28) {
      return false;
    }
    return _termCoverage(result,
                significantTokenCount: significantTokenCount) >=
            0.34 ||
        result.matchedTopics.isNotEmpty;
  }

  double _termCoverage(
    HadithFinderResult result, {
    required int significantTokenCount,
  }) {
    if (significantTokenCount <= 0) {
      return 0;
    }
    return result.matchedTerms.length / significantTokenCount;
  }

  double _confidenceFor(
    HadithFinderResult result, {
    required int significantTokenCount,
  }) {
    final double scoreSignal = (result.score / 90).clamp(0, 1).toDouble();
    final double coverageSignal =
        _termCoverage(result, significantTokenCount: significantTokenCount)
            .clamp(0, 1)
            .toDouble();
    final double topicSignal = result.matchedTopics.isEmpty ? 0 : 0.1;
    final double phraseSignal = result.exactPhraseMatch ? 0.15 : 0;
    return (scoreSignal * 0.6 +
            coverageSignal * 0.3 +
            topicSignal +
            phraseSignal)
        .clamp(0, 1)
        .toDouble();
  }

  bool _hasStrongGrounding(HadithFinderResult result) {
    return result.matchReasons.any(
      (String reason) =>
          reason == 'Matched in title' ||
          reason == 'Matched in hadith text' ||
          reason == 'Matched in explanation',
    );
  }

  String _summaryFor(HadithFinderResult result) {
    final String title = _cleanSummary(result.result.title);
    if (title.isNotEmpty && !_looksTooGeneric(title)) {
      return _ensureSentence(title);
    }
    final String explanation = _firstSentence(result.result.explanation);
    if (explanation.isNotEmpty && !_looksTooGeneric(explanation)) {
      return explanation;
    }
    final String hadithText = _firstSentence(result.result.hadithText);
    if (hadithText.isNotEmpty) {
      return hadithText;
    }
    return _ensureSentence(result.result.title.trim());
  }

  String _firstSentence(String value) {
    final String trimmed = _cleanSummary(value);
    if (trimmed.isEmpty) {
      return '';
    }
    final Match? match =
        RegExp(r'^(.{1,220}?[.!?])(?:\s|$)').firstMatch(trimmed);
    if (match != null) {
      return match.group(1)!.trim();
    }
    if (trimmed.length <= 220) {
      return trimmed;
    }
    return '${trimmed.substring(0, 217).trim()}...';
  }

  String _cleanSummary(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _looksTooGeneric(String value) {
    final String normalized = value.toLowerCase();
    return normalized.startsWith('this hadith ') ||
        normalized.startsWith('this great hadith ') ||
        normalized.contains('important themes and facts') ||
        normalized == 'hadith' ||
        normalized == 'guidance';
  }

  String _ensureSentence(String value) {
    if (value.isEmpty) {
      return value;
    }
    if (value.endsWith('.') || value.endsWith('!') || value.endsWith('?')) {
      return value;
    }
    return '$value.';
  }
}
