import 'package:hadith/hadith.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Database database;
  late HadithRepository repository;

  setUp(() async {
    database = sqlite3.openInMemory();
    repository = HadithRepository(
      database: database,
      remoteDataSource: _FakeRemoteDataSource(),
    );
    await repository.initialize();
  });

  tearDown(() async {
    await repository.dispose();
  });

  test('syncs categories and cached hadith details from HadeethEnc data', () async {
    await repository.refreshLanguages();
    await repository.refreshRootCategories(languageCode: 'en');
    final HadithCategorySyncResult result = await repository.syncCategory(
      languageCode: 'en',
      categoryId: 1,
    );

    final List<HadithCategory> categories =
        await repository.getRootCategories(languageCode: 'en');
    final sourceVersions = await repository.getSourceVersions();

    expect(result.hadithCount, 2);
    expect(categories.first.cachedHadithCount, 2);
    expect(sourceVersions.single.version, 'API/v1');
  });

  test('search finds cached hadith text offline', () async {
    await repository.refreshRootCategories(languageCode: 'en');
    await repository.syncCategory(languageCode: 'en', categoryId: 1);

    final List<HadithSearchResult> results = await repository.search(
      query: 'blood',
      languageCode: 'en',
    );

    expect(results, isNotEmpty);
    expect(results.first.id, 2962);
  });

  test('stores hadith detail verbatim after sync', () async {
    await repository.refreshRootCategories(languageCode: 'en');
    await repository.syncCategory(languageCode: 'en', categoryId: 1);

    final HadithDetail? detail = await repository.getHadithDetail(
      languageCode: 'en',
      hadithId: 2962,
    );

    expect(detail, isNotNull);
    expect(
      detail!.hadithText,
      'The first cases to be settled among people on the Day of Judgement will be the cases of blood (homicide).',
    );
    expect(detail.hints.first, 'The significance of blood-related rights.');
  });

  test('placeholder shia pack stays in coming soon state', () async {
    const PlaceholderShiaHadithPackProvider provider =
        PlaceholderShiaHadithPackProvider();

    final ShiaHadithPackAvailability availability =
        await provider.getAvailability();

    expect(availability.status, ShiaHadithPackStatus.comingSoon);
    expect(availability.message, contains('licensed content'));
  });
}

class _FakeRemoteDataSource implements HadeethEncRemoteDataSource {
  @override
  Future<HadithDetail> fetchHadith({
    required String languageCode,
    required int hadithId,
  }) async {
    if (hadithId == 2962) {
      return const HadithDetail(
        id: 2962,
        languageCode: 'en',
        title:
            'The first cases to be settled among people on the Day of Judgement will be the cases of blood (homicide)',
        hadithText:
            'The first cases to be settled among people on the Day of Judgement will be the cases of blood (homicide).',
        attribution: 'Agreed upon',
        grade: 'Authentic',
        explanation:
            'The Prophet mentioned that the first injustices settled among people will include homicide and bloodshed.',
        hints: <String>['The significance of blood-related rights.'],
        categoryIds: <int>[1],
        translations: <String>['ar', 'en'],
        hadithIntro: 'Reported from Ibn Masud:',
        hadithArabic: 'أَوَّلُ مَا يُقْضَى بَيْنَ النَّاسِ...',
        hadithIntroArabic: 'عن ابن مسعود رضي الله عنه قال:',
        explanationArabic: 'ذكر النبي صلى الله عليه وسلم...',
        hintsArabic: <String>['عظم أمر الدماء.'],
        wordsMeaningsArabic: <String>[],
        attributionArabic: 'متفق عليه',
        gradeArabic: 'صحيح',
      );
    }

    return const HadithDetail(
      id: 5907,
      languageCode: 'en',
      title:
          'Keep on reciting this Quran, for it slips away faster than camels escaping their ropes',
      hadithText:
          'Keep on reciting this Quran, for it slips away faster than camels escaping their ropes.',
      attribution: 'Agreed upon',
      grade: 'Authentic',
      explanation:
          'The hadith emphasizes continuous revision and recitation so memorization is not lost.',
      hints: <String>['Revision protects memorization.'],
      categoryIds: <int>[1],
      translations: <String>['ar', 'en'],
      hadithIntro: 'The Messenger of Allah said:',
      hadithArabic: 'تَعَاهَدُوا هَذَا الْقُرْآنَ...',
      hadithIntroArabic: 'قال رسول الله صلى الله عليه وسلم:',
      explanationArabic: 'فيه الحث على التعاهد.',
      hintsArabic: <String>['الحث على المراجعة.'],
      wordsMeaningsArabic: <String>[],
      attributionArabic: 'متفق عليه',
      gradeArabic: 'صحيح',
    );
  }

  @override
  Future<List<HadithLanguage>> listLanguages() async {
    return const <HadithLanguage>[
      HadithLanguage(code: 'ar', nativeName: 'العربية'),
      HadithLanguage(code: 'en', nativeName: 'English'),
      HadithLanguage(code: 'ur', nativeName: 'اردو'),
    ];
  }

  @override
  Future<HadithListPage> listHadiths({
    required String languageCode,
    required int categoryId,
    required int page,
    int perPage = 50,
  }) async {
    return const HadithListPage(
      items: <HadithListItem>[
        HadithListItem(
          id: 2962,
          title:
              'The first cases to be settled among people on the Day of Judgement will be the cases of blood (homicide)',
          availableTranslations: <String>['ar', 'en'],
        ),
        HadithListItem(
          id: 5907,
          title:
              'Keep on reciting this Quran, for it slips away faster than camels escaping their ropes',
          availableTranslations: <String>['ar', 'en'],
        ),
      ],
      currentPage: 1,
      lastPage: 1,
      totalItems: 2,
      perPage: 50,
    );
  }

  @override
  Future<List<HadithCategory>> listRootCategories({
    required String languageCode,
  }) async {
    return const <HadithCategory>[
      HadithCategory(
        id: 1,
        languageCode: 'en',
        title: 'The Noble Qur\'an and Qur\'anic Sciences',
        hadithCount: 2,
      ),
    ];
  }
}
