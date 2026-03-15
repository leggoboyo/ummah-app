import 'retrieved_passage.dart';
import 'source_version.dart';

enum AssistantCorpus {
  quran,
  hadith,
}

abstract interface class AssistantSourcePort {
  Future<List<RetrievedPassage>> retrieve({
    required AssistantCorpus corpus,
    required String query,
    required String preferredLanguageCode,
  });

  Future<List<SourceVersion>> getSourceVersions({
    required AssistantCorpus corpus,
    required String preferredLanguageCode,
  });

  Future<void> dispose();
}
