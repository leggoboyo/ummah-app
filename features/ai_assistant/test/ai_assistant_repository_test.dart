import 'package:ai_assistant/ai_assistant.dart';
import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('returns insufficient-evidence response when no local sources match',
      () async {
    final AiAssistantRepository repository = AiAssistantRepository(
      retriever: _FakeRetriever(
        sources: const <RetrievedPassage>[],
        sourceVersions: const <SourceVersion>[],
      ),
      client: _FakeOpenAiResponsesClient(
        responseText: 'Answer:\nUnused\n\nCommentary:\nUnused',
      ),
    );

    final AssistantResponse response = await repository.askQuestion(
      mode: AssistantMode.quran,
      question: 'What does this say about a topic with no cached evidence?',
      apiKey: 'sk-test',
      preferredLanguageCode: 'en',
    );

    expect(
      response.answer,
      AiAssistantRepository.insufficientEvidenceMessage,
    );
    expect(response.hasSufficientEvidence, isFalse);
    expect(response.sources, isEmpty);
  });

  test('adds high-risk safety review for context-heavy questions', () async {
    final AiAssistantRepository repository = AiAssistantRepository(
      retriever: _FakeRetriever(
        sources: const <RetrievedPassage>[
          RetrievedPassage(
            sourceKind: RetrievedPassageSourceKind.quran,
            reference: 'Qur\'an 4:35',
            title: 'An-Nisa',
            quote: 'If you fear a breach between the two...',
            attribution: 'Tanzil + translation',
            languageCode: 'en',
          ),
        ],
        sourceVersions: const <SourceVersion>[],
      ),
      client: _FakeOpenAiResponsesClient(
        responseText:
            'Answer:\nI don\'t know from the current sources.\n\nCommentary:\nThis requires qualified scholarly and professional support.',
      ),
    );

    final AssistantResponse response = await repository.askQuestion(
      mode: AssistantMode.quran,
      question: 'Can I get divorced in this situation?',
      apiKey: 'sk-test',
      preferredLanguageCode: 'en',
    );

    expect(response.safetyReview.isHighRisk, isTrue);
    expect(response.safetyReview.notice, contains('High-risk topic'));
    expect(response.commentary, contains('qualified scholarly'));
  });

  test('parses answer and commentary while preserving verbatim sources',
      () async {
    const RetrievedPassage source = RetrievedPassage(
      sourceKind: RetrievedPassageSourceKind.hadith,
      reference: 'HadeethEnc #2962',
      title: 'Bloodshed rights',
      quote:
          'The first cases to be settled among people on the Day of Judgement will be the cases of blood.',
      attribution: 'Agreed upon • Authentic',
      languageCode: 'en',
    );

    final AiAssistantRepository repository = AiAssistantRepository(
      retriever: _FakeRetriever(
        sources: const <RetrievedPassage>[source],
        sourceVersions: const <SourceVersion>[
          SourceVersion(
            providerKey: 'hadeethenc',
            contentKey: 'cached_hadiths',
            languageCode: 'en',
            version: 'API/v1',
            attribution: 'HadeethEnc.com',
          ),
        ],
      ),
      client: _FakeOpenAiResponsesClient(
        responseText:
            'Answer:\nBloodshed is treated with extreme seriousness in the retrieved hadith.\n\nCommentary:\nThis commentary is limited to the cited hadith and should not be treated as a full legal ruling.',
      ),
    );

    final AssistantResponse response = await repository.askQuestion(
      mode: AssistantMode.hadith,
      question: 'What do the sources say about bloodshed?',
      apiKey: 'sk-test',
      preferredLanguageCode: 'en',
    );

    expect(response.answer, contains('extreme seriousness'));
    expect(
        response.commentary, contains('not be treated as a full legal ruling'));
    expect(response.sources.single.quote, source.quote);
    expect(response.sourceVersions.single.attribution, 'HadeethEnc.com');
  });
}

class _FakeRetriever implements IslamicSourceRetriever {
  _FakeRetriever({
    required this.sources,
    required this.sourceVersions,
  });

  final List<RetrievedPassage> sources;
  final List<SourceVersion> sourceVersions;

  @override
  Future<void> dispose() async {}

  @override
  Future<List<SourceVersion>> getSourceVersions({
    required AssistantMode mode,
    required String preferredLanguageCode,
  }) async {
    return sourceVersions;
  }

  @override
  Future<List<RetrievedPassage>> retrieve({
    required AssistantMode mode,
    required String query,
    required String preferredLanguageCode,
  }) async {
    return sources;
  }
}

class _FakeOpenAiResponsesClient extends OpenAiResponsesClient {
  _FakeOpenAiResponsesClient({
    required this.responseText,
  });

  final String responseText;

  @override
  Future<String> generateCommentary({
    required String apiKey,
    required AssistantMode mode,
    required String question,
    required List<RetrievedPassage> sources,
    required bool highRisk,
  }) async {
    return responseText;
  }

  @override
  void dispose() {}
}
