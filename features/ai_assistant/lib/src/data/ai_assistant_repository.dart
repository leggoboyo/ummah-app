import 'package:core/core.dart';

import '../domain/assistant_mode.dart';
import '../domain/assistant_response.dart';
import '../domain/assistant_safety_review.dart';
import '../domain/retrieved_passage.dart';
import 'islamic_source_retriever.dart';
import 'openai_responses_client.dart';

class AiAssistantRepository {
  AiAssistantRepository({
    IslamicSourceRetriever? retriever,
    OpenAiResponsesClient? client,
  })  : _retriever = retriever ?? LocalIslamicSourceRetriever(),
        _client = client ?? OpenAiResponsesClient();

  static const String insufficientEvidenceMessage =
      'I don\'t know from the current sources.';

  final IslamicSourceRetriever _retriever;
  final OpenAiResponsesClient _client;

  Future<AssistantResponse> askQuestion({
    required AssistantMode mode,
    required String question,
    required String apiKey,
    required String preferredLanguageCode,
  }) async {
    final AssistantSafetyReview safetyReview =
        AssistantSafetyReview.review(question);
    final List<RetrievedPassage> sources = await _retriever.retrieve(
      mode: mode,
      query: question,
      preferredLanguageCode: preferredLanguageCode,
    );
    final List<SourceVersion> sourceVersions =
        await _retriever.getSourceVersions(
      mode: mode,
      preferredLanguageCode: preferredLanguageCode,
    );

    if (apiKey.trim().isEmpty) {
      return AssistantResponse(
        answer: 'Add your OpenAI API key to use BYOK mode.',
        commentary:
            'The app retrieved local sources but will not send anything to OpenAI until you save a BYOK API key in secure storage.',
        sources: sources,
        sourceVersions: sourceVersions,
        safetyReview: safetyReview,
        generatedAt: DateTime.now(),
        hasSufficientEvidence: sources.isNotEmpty,
      );
    }

    if (sources.isEmpty) {
      return AssistantResponse(
        answer: insufficientEvidenceMessage,
        commentary:
            'No relevant local ${mode.label.toLowerCase()} passages were found on this device. Rephrase the question, download more local source content, or consult a qualified scholar for a context-specific answer.',
        sources: const <RetrievedPassage>[],
        sourceVersions: sourceVersions,
        safetyReview: safetyReview,
        generatedAt: DateTime.now(),
        hasSufficientEvidence: false,
      );
    }

    final String rawResponse = await _client.generateCommentary(
      apiKey: apiKey,
      mode: mode,
      question: question,
      sources: sources,
      highRisk: safetyReview.isHighRisk,
    );
    final _ParsedAssistantSections parsed = _parseSections(rawResponse);

    return AssistantResponse(
      answer: parsed.answer,
      commentary: parsed.commentary,
      sources: sources,
      sourceVersions: sourceVersions,
      safetyReview: safetyReview,
      generatedAt: DateTime.now(),
      hasSufficientEvidence:
          parsed.answer != insufficientEvidenceMessage && sources.isNotEmpty,
    );
  }

  Future<void> dispose() async {
    await _retriever.dispose();
    _client.dispose();
  }

  _ParsedAssistantSections _parseSections(String raw) {
    final RegExp answerPattern = RegExp(
      r'Answer:\s*(.*?)\s*Commentary:',
      dotAll: true,
      caseSensitive: false,
    );
    final RegExp commentaryPattern = RegExp(
      r'Commentary:\s*(.*)$',
      dotAll: true,
      caseSensitive: false,
    );
    final RegExpMatch? answerMatch = answerPattern.firstMatch(raw);
    final RegExpMatch? commentaryMatch = commentaryPattern.firstMatch(raw);

    final String answer = answerMatch?.group(1)?.trim().isNotEmpty == true
        ? answerMatch!.group(1)!.trim()
        : insufficientEvidenceMessage;
    final String commentary =
        commentaryMatch?.group(1)?.trim().isNotEmpty == true
            ? commentaryMatch!.group(1)!.trim()
            : raw.trim();

    return _ParsedAssistantSections(
      answer: answer,
      commentary: commentary,
    );
  }
}

class _ParsedAssistantSections {
  const _ParsedAssistantSections({
    required this.answer,
    required this.commentary,
  });

  final String answer;
  final String commentary;
}
