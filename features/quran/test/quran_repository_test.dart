import 'dart:convert';

import 'package:core/core.dart';
import 'package:quran/quran.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Database database;
  late QuranRepository repository;

  setUp(() async {
    database = sqlite3.openInMemory();
    repository = QuranRepository(
      database: database,
      seedDataSource: _FakeSeedDataSource(),
      remoteDataSource: _FakeRemoteDataSource(),
    );
    await repository.initialize();
  });

  tearDown(() async {
    await repository.dispose();
  });

  test('seeds bundled surahs and Arabic source version', () async {
    final List<SurahSummary> surahs = await repository.getSurahs();
    final sourceVersion = await repository.getArabicSourceVersion();

    expect(surahs, hasLength(2));
    expect(surahs.first.englishName, 'The Opening');
    expect(sourceVersion?.providerKey, 'tanzil');
    expect(sourceVersion?.version, '1.1');
  });

  test('reads bundled Arabic ayahs without any network sync', () async {
    final List<QuranAyah> ayahs = await repository.getSurahAyahs(1);

    expect(ayahs, hasLength(2));
    expect(ayahs.first.arabicText, contains('بِسْمِ ٱللَّهِ'));
    expect(ayahs.first.translationText, isNull);
  });

  test('search returns Arabic and translation matches from SQLite FTS',
      () async {
    await repository.refreshTranslationCatalog(languageCode: 'en');
    await repository.syncTranslationSurahs(
      translationKey: 'english_test',
      surahNumbers: const <int>[1],
    );

    final List<QuranSearchResult> arabicResults =
        await repository.search('ٱلرَّحِيمِ');
    final List<QuranSearchResult> translationResults = await repository.search(
      'Merciful',
      translationKey: 'english_test',
    );

    expect(arabicResults, isNotEmpty);
    expect(translationResults, isNotEmpty);
    expect(
      translationResults.first.matchScope,
      QuranSearchScope.translation,
    );
  });

  test('stores downloaded translation text verbatim', () async {
    await repository.refreshTranslationCatalog(languageCode: 'en');
    await repository.syncTranslationSurahs(
      translationKey: 'english_test',
      surahNumbers: const <int>[1],
    );

    final List<QuranAyah> ayahs = await repository.getSurahAyahs(
      1,
      translationKey: 'english_test',
    );

    expect(
      ayahs.first.translationText,
      'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
    );
    expect(
      ayahs.first.footnotes,
      '[1] Verbatim footnote.',
    );
  });

  test('tracks partial versus full translation download state', () async {
    await repository.refreshTranslationCatalog(languageCode: 'en');
    await repository.syncTranslationSurahs(
      translationKey: 'english_test',
      surahNumbers: const <int>[1],
    );

    final List<QuranTranslationInfo> translations =
        await repository.getLocalTranslations(languageCode: 'en');

    expect(translations.single.isDownloaded, isTrue);
    expect(translations.single.isFullyDownloaded, isFalse);

    await repository.syncEntireTranslation(translationKey: 'english_test');

    final List<QuranTranslationInfo> afterFullSync =
        await repository.getLocalTranslations(languageCode: 'en');
    expect(afterFullSync.single.isFullyDownloaded, isTrue);
  });

  test('removes a downloaded translation cleanly', () async {
    await repository.refreshTranslationCatalog(languageCode: 'en');
    await repository.syncEntireTranslation(translationKey: 'english_test');

    await repository.removeTranslation(translationKey: 'english_test');

    final List<QuranTranslationInfo> translations =
        await repository.getLocalTranslations(languageCode: 'en');
    final SourceVersion? sourceVersion =
        await repository.getTranslationSourceVersion(
      'english_test',
      languageCode: 'en',
    );

    expect(translations.single.isDownloaded, isFalse);
    expect(translations.single.cachedAyahCount, 0);
    expect(sourceVersion, isNull);
  });

  test('can cancel full translation sync between surahs', () async {
    await repository.refreshTranslationCatalog(languageCode: 'en');

    final QuranSyncOutcome outcome = await repository.syncEntireTranslation(
      translationKey: 'english_test',
      shouldCancel: () => true,
    );

    expect(outcome.completed, isFalse);
    expect(outcome.completedSurahs, 0);
    expect(outcome.insertedVerses, 0);
  });

  test('suggests a nearby local query when exact search text misses', () async {
    await repository.refreshTranslationCatalog(languageCode: 'en');
    await repository.syncTranslationSurahs(
      translationKey: 'english_test',
      surahNumbers: const <int>[1],
    );

    final String? suggestion = await repository.suggestQuery(
      'mercifl',
      translationKey: 'english_test',
    );

    expect(suggestion, contains('merciful'));
  });
}

class _FakeSeedDataSource implements QuranSeedDataSource {
  @override
  String get arabicAttribution => 'Tanzil Project (tanzil.net)';

  @override
  String get arabicVersion => '1.1';

  @override
  Future<String> loadArabicCorpus() async {
    return '1|1|بِسْمِ ٱللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\n'
        '1|2|ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ\n'
        '2|1|الٓمٓ\n';
  }

  @override
  Future<String> loadMetadata() async {
    return jsonEncode(<Map<String, Object?>>[
      <String, Object?>{
        'number': 1,
        'arabic_name': 'الفاتحة',
        'transliteration': 'Al-Faatiha',
        'english_name': 'The Opening',
        'ayah_count': 2,
        'revelation_type': 'Meccan',
        'revelation_order': 5,
        'rukus': 1,
      },
      <String, Object?>{
        'number': 2,
        'arabic_name': 'البقرة',
        'transliteration': 'Al-Baqara',
        'english_name': 'The Cow',
        'ayah_count': 1,
        'revelation_type': 'Medinan',
        'revelation_order': 87,
        'rukus': 40,
      },
    ]);
  }
}

class _FakeRemoteDataSource implements QuranTranslationRemoteDataSource {
  @override
  Future<List<QuranTranslationVerse>> fetchSurah({
    required String translationKey,
    required int surahNumber,
  }) async {
    if (surahNumber == 1) {
      return const <QuranTranslationVerse>[
        QuranTranslationVerse(
          surahNumber: 1,
          ayahNumber: 1,
          arabicText: 'بِسْمِ ٱللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          translationText:
              'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
          footnotes: '[1] Verbatim footnote.',
        ),
        QuranTranslationVerse(
          surahNumber: 1,
          ayahNumber: 2,
          arabicText: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
          translationText: 'All praise is due to Allah, Lord of the worlds.',
          footnotes: '',
        ),
      ];
    }

    return const <QuranTranslationVerse>[
      QuranTranslationVerse(
        surahNumber: 2,
        ayahNumber: 1,
        arabicText: 'الٓمٓ',
        translationText: 'Alif, Lam, Meem.',
        footnotes: '',
      ),
    ];
  }

  @override
  Future<List<QuranTranslationInfo>> listTranslations({
    required String languageCode,
    String localization = 'en',
  }) async {
    return <QuranTranslationInfo>[
      QuranTranslationInfo(
        key: 'english_test',
        languageCode: 'en',
        version: '1.0.0',
        title: 'English Test Translation',
        description: 'Test translation for repository coverage.',
        direction: 'ltr',
        attribution: 'QuranEnc - English Test Translation',
        lastRemoteUpdate: DateTime(2025, 1, 1),
      ),
    ];
  }
}
