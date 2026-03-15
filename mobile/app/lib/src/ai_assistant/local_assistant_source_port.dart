import 'package:core/core.dart';
import 'package:hadith/hadith.dart';
import 'package:quran/quran.dart';

class LocalAssistantSourcePort implements AssistantSourcePort {
  LocalAssistantSourcePort({
    QuranRepository? quranRepository,
    HadithRepository? hadithRepository,
  })  : _quranRepository = quranRepository ?? QuranRepository(),
        _hadithRepository = hadithRepository ?? HadithRepository();

  final QuranRepository _quranRepository;
  final HadithRepository _hadithRepository;

  @override
  Future<List<SourceVersion>> getSourceVersions({
    required AssistantCorpus corpus,
    required String preferredLanguageCode,
  }) {
    switch (corpus) {
      case AssistantCorpus.quran:
        return _quranRepository.getSourceVersions();
      case AssistantCorpus.hadith:
        return _hadithRepository.getSourceVersions();
    }
  }

  @override
  Future<List<RetrievedPassage>> retrieve({
    required AssistantCorpus corpus,
    required String query,
    required String preferredLanguageCode,
  }) {
    switch (corpus) {
      case AssistantCorpus.quran:
        return _retrieveQuran(
          query: query,
          preferredLanguageCode: preferredLanguageCode,
        );
      case AssistantCorpus.hadith:
        return _retrieveHadith(
          query: query,
          preferredLanguageCode: preferredLanguageCode,
        );
    }
  }

  @override
  Future<void> dispose() async {
    await _quranRepository.dispose();
    await _hadithRepository.dispose();
  }

  Future<List<RetrievedPassage>> _retrieveQuran({
    required String query,
    required String preferredLanguageCode,
  }) async {
    await _quranRepository.initialize();
    final List<QuranTranslationInfo> translations =
        await _quranRepository.getLocalTranslations(
      languageCode: preferredLanguageCode,
    );
    final QuranTranslationInfo? selectedTranslation =
        _pickDownloadedTranslation(translations) ??
            _pickDownloadedTranslation(
              await _quranRepository.getLocalTranslations(),
            );

    final List<QuranSearchResult> results = await _quranRepository.search(
      query,
      translationKey: selectedTranslation?.key,
      limit: 3,
    );

    return results.map((QuranSearchResult result) {
      final String quote = result.translationText == null ||
              result.translationText!.trim().isEmpty
          ? result.arabicText
          : '${result.arabicText}\n${result.translationText!}';
      final String attribution = selectedTranslation == null
          ? 'Tanzil Uthmani Arabic text'
          : 'Tanzil Uthmani Arabic text + ${selectedTranslation.attribution}';
      return RetrievedPassage(
        sourceKind: RetrievedPassageSourceKind.quran,
        reference: 'Qur\'an ${result.surahNumber}:${result.ayahNumber}',
        title: result.surahEnglishName,
        quote: quote,
        attribution: attribution,
        languageCode: selectedTranslation?.languageCode ?? 'ar',
        note: selectedTranslation == null
            ? 'No downloaded translation was available for this query.'
            : 'Translation version ${selectedTranslation.version}',
      );
    }).toList(growable: false);
  }

  Future<List<RetrievedPassage>> _retrieveHadith({
    required String query,
    required String preferredLanguageCode,
  }) async {
    await _hadithRepository.initialize();
    String activeLanguageCode = preferredLanguageCode;
    List<HadithSearchResult> results = await _hadithRepository.search(
      query: query,
      languageCode: activeLanguageCode,
      limit: 3,
    );

    if (results.isEmpty && preferredLanguageCode != 'en') {
      activeLanguageCode = 'en';
      results = await _hadithRepository.search(
        query: query,
        languageCode: activeLanguageCode,
        limit: 3,
      );
    }

    return results.map((HadithSearchResult result) {
      return RetrievedPassage(
        sourceKind: RetrievedPassageSourceKind.hadith,
        reference: 'HadeethEnc #${result.id}',
        title: result.title,
        quote: result.hadithText,
        attribution: '${result.attribution} • ${result.grade}',
        languageCode: result.languageCode,
        note: result.explanation,
      );
    }).toList(growable: false);
  }

  QuranTranslationInfo? _pickDownloadedTranslation(
    List<QuranTranslationInfo> translations,
  ) {
    for (final QuranTranslationInfo translation in translations) {
      if (translation.isDownloaded) {
        return translation;
      }
    }
    return null;
  }
}
