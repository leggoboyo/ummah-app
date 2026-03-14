import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hadith/hadith.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');

  late Database database;
  late Directory tempDirectory;

  setUp(() async {
    database = sqlite3.openInMemory();
    tempDirectory = await Directory.systemTemp.createTemp('hadith_repo_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (MethodCall call) async {
      switch (call.method) {
        case 'getTemporaryDirectory':
        case 'getApplicationSupportDirectory':
          return tempDirectory.path;
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
    database.close();
  });

  test('installs bundled pack, records metadata, and searches offline',
      () async {
    final _PackFixture fixture = _PackFixture.singleLanguage(
      languageCode: 'en',
      languageName: 'English',
      version: '1.0.0',
      records: <Map<String, Object?>>[
        <String, Object?>{
          'id': 101,
          'title': 'Kindness to parents',
          'title_arabic': 'بر الوالدين',
          'hadith_text':
              'The pleasure of the Lord lies in the pleasure of the parents.',
          'hadith_text_arabic': 'رضا الرب في رضا الوالدين',
          'explanation':
              'This hadith highlights caring for parents with mercy and obedience.',
          'explanation_arabic': 'يدل الحديث على البر والرحمة بالوالدين.',
          'benefits': <String>['Mercy toward parents is a major virtue.'],
          'benefits_arabic': <String>['الرحمة بالوالدين من اعظم الفضائل.'],
          'words_meanings_arabic': <String>[],
          'grade': 'Authentic',
          'grade_arabic': 'صحيح',
          'source_reference': 'Reported by al-Tirmidhi',
          'source_reference_arabic': 'رواه الترمذي',
          'source_url': 'https://example.test/hadith/101',
        },
      ],
    );
    final HadithRepository repository = HadithRepository(
      database: database,
      assetBundle: fixture.assetBundle,
    );

    await repository.initialize();
    final HadithPackInstall install = await repository.installBundledPack(
      languageCode: 'en',
    );
    final List<HadithFinderResult> results = await repository.findForUseCase(
      query: 'parents mercy',
      preferredLanguageCode: 'en',
    );
    final List<SourceVersion> versions = await repository.getSourceVersions();

    expect(install.languageCode, 'en');
    expect(install.isComplete, isTrue);
    expect(results, isNotEmpty);
    expect(results.first.result.id, 101);
    expect(
        results.first.result.matchReasons, contains('Matched in explanation'));
    expect(versions.single.version, '1.0.0');
    expect(versions.single.contentKey, 'sunni_pack_en');
  });

  test(
      'suggests typo-corrected phrases from the local deterministic vocabulary',
      () async {
    final _PackFixture fixture = _PackFixture.singleLanguage(
      languageCode: 'en',
      languageName: 'English',
      version: '1.0.0',
      records: <Map<String, Object?>>[
        <String, Object?>{
          'id': 201,
          'title': 'Mercy between believers',
          'title_arabic': 'الرحمة بين المؤمنين',
          'hadith_text': 'The merciful are shown mercy by the Most Merciful.',
          'hadith_text_arabic': 'الراحمون يرحمهم الرحمن',
          'explanation':
              'This hadith encourages mercy, compassion, and kindness.',
          'explanation_arabic': 'فيه الحث على الرحمة والرفق.',
          'benefits': <String>['Mercy is beloved to Allah.'],
          'benefits_arabic': <String>['الرحمة محبوبة الى الله.'],
          'words_meanings_arabic': <String>[],
          'grade': 'Authentic',
          'grade_arabic': 'صحيح',
          'source_reference': 'Reported by Abu Dawud',
          'source_reference_arabic': 'رواه ابو داود',
          'source_url': 'https://example.test/hadith/201',
        },
      ],
    );
    final HadithRepository repository = HadithRepository(
      database: database,
      assetBundle: fixture.assetBundle,
    );

    await repository.initialize();
    await repository.installBundledPack(languageCode: 'en');

    final String? suggestion = await repository.suggestQuery(
      query: 'mercyy',
      preferredLanguageCode: 'en',
    );

    expect(suggestion, 'mercy');
  });

  test('rejects corrupted bundled packs when the file hash does not match',
      () async {
    final _PackFixture fixture = _PackFixture.singleLanguage(
      languageCode: 'en',
      languageName: 'English',
      version: '1.0.0',
      records: <Map<String, Object?>>[
        <String, Object?>{
          'id': 301,
          'title': 'Prayer is light',
          'title_arabic': 'الصلاة نور',
          'hadith_text': 'Prayer is light.',
          'hadith_text_arabic': 'الصلاة نور',
          'explanation': 'A short test record.',
          'explanation_arabic': 'سجل اختبار قصير.',
          'benefits': <String>['Prayer remains central.'],
          'benefits_arabic': <String>['الصلاة اصل.'],
          'words_meanings_arabic': <String>[],
          'grade': 'Authentic',
          'grade_arabic': 'صحيح',
          'source_reference': 'Reported by Muslim',
          'source_reference_arabic': 'رواه مسلم',
          'source_url': 'https://example.test/hadith/301',
        },
      ],
      overrideFileHash: 'not-a-real-hash',
    );
    final HadithRepository repository = HadithRepository(
      database: database,
      assetBundle: fixture.assetBundle,
    );

    await repository.initialize();

    expect(
      () => repository.installBundledPack(languageCode: 'en'),
      throwsA(isA<StateError>()),
    );
  });

  test('reports update availability when the bundled manifest version changes',
      () async {
    final _PackFixture initialFixture = _PackFixture.singleLanguage(
      languageCode: 'en',
      languageName: 'English',
      version: '1.0.0',
      records: <Map<String, Object?>>[
        <String, Object?>{
          'id': 401,
          'title': 'Knowledge before speech',
          'title_arabic': 'العلم قبل القول',
          'hadith_text': 'Knowledge comes before speech and action.',
          'hadith_text_arabic': 'العلم قبل القول والعمل',
          'explanation': 'Used for update detection.',
          'explanation_arabic': 'يستخدم لاختبار التحديث.',
          'benefits': <String>['Seek knowledge.'],
          'benefits_arabic': <String>['اطلب العلم.'],
          'words_meanings_arabic': <String>[],
          'grade': 'Authentic',
          'grade_arabic': 'صحيح',
          'source_reference': 'Reported by al-Bukhari',
          'source_reference_arabic': 'رواه البخاري',
          'source_url': 'https://example.test/hadith/401',
        },
      ],
    );
    final HadithRepository installRepository = HadithRepository(
      database: database,
      assetBundle: initialFixture.assetBundle,
    );

    await installRepository.initialize();
    await installRepository.installBundledPack(languageCode: 'en');

    final _PackFixture updatedFixture = _PackFixture.singleLanguage(
      languageCode: 'en',
      languageName: 'English',
      version: '1.1.0',
      records: <Map<String, Object?>>[
        <String, Object?>{
          'id': 401,
          'title': 'Knowledge before speech',
          'title_arabic': 'العلم قبل القول',
          'hadith_text': 'Knowledge comes before speech and action.',
          'hadith_text_arabic': 'العلم قبل القول والعمل',
          'explanation': 'Used for update detection.',
          'explanation_arabic': 'يستخدم لاختبار التحديث.',
          'benefits': <String>['Seek knowledge.'],
          'benefits_arabic': <String>['اطلب العلم.'],
          'words_meanings_arabic': <String>[],
          'grade': 'Authentic',
          'grade_arabic': 'صحيح',
          'source_reference': 'Reported by al-Bukhari',
          'source_reference_arabic': 'رواه البخاري',
          'source_url': 'https://example.test/hadith/401',
        },
      ],
    );
    final HadithRepository checkRepository = HadithRepository(
      database: database,
      assetBundle: updatedFixture.assetBundle,
    );

    await checkRepository.initialize();
    final List<HadithPackManifest> updates =
        await checkRepository.getAvailablePackUpdates();

    expect(updates.single.languageCode, 'en');
    expect(updates.single.version, '1.1.0');
  });

  test('reads incomplete installs without marking them as complete', () async {
    final HadithRepository repository = HadithRepository(
      database: database,
      assetBundle: _PackFixture.singleLanguage(
        languageCode: 'en',
        languageName: 'English',
        version: '1.0.0',
        records: const <Map<String, Object?>>[],
      ).assetBundle,
    );

    await repository.initialize();
    database.execute(
      '''
      INSERT INTO hadith_pack_installs (
        language_code, language_name, provider_key, version,
        source_url, download_url, file_hash, record_count,
        pack_size_bytes, installed_at, is_complete
      ) VALUES (
        'en', 'English', 'hadeethenc', '1.0.0',
        'https://hadeethenc.com/en/home', 'https://example.test/en.xlsx',
        'hash', 10, 1024, '2026-03-13T21:00:00', 0
      )
      ''',
    );

    final List<HadithPackInstall> installs =
        await repository.getInstalledPacks();

    expect(installs.single.isComplete, isFalse);
  });

  test(
      'installs a remote pack, stores archive metadata, and removes it cleanly',
      () async {
    final _PackFixture fixture = _PackFixture.singleLanguage(
      languageCode: 'en',
      languageName: 'English',
      version: '1.2.0',
      records: <Map<String, Object?>>[
        <String, Object?>{
          'id': 501,
          'title': 'Truthfulness in trade',
          'title_arabic': 'الصدق في البيع',
          'hadith_text': 'The truthful merchant will be with the truthful.',
          'hadith_text_arabic': 'التاجر الصدوق مع الصديقين',
          'explanation': 'Truthfulness in trade is a major virtue.',
          'explanation_arabic': 'الصدق في التجارة من اعظم الفضائل.',
          'benefits': <String>['Truthfulness matters in business.'],
          'benefits_arabic': <String>['الصدق مهم في التجارة.'],
          'words_meanings_arabic': <String>[],
          'grade': 'Authentic',
          'grade_arabic': 'صحيح',
          'source_reference': 'Reported by al-Tirmidhi',
          'source_reference_arabic': 'رواه الترمذي',
          'source_url': 'https://example.test/hadith/501',
        },
      ],
    );
    final Uint8List remoteBytes =
        Uint8List.fromList(fixture.assets.values.last);
    final HadithRepository repository = HadithRepository(
      database: database,
      assetBundle: fixture.assetBundle,
      packRemoteDataSource: _FakeRemoteDataSource(
        manifests: <HadithPackManifest>[
          HadithPackManifest(
            providerKey: 'hadeethenc',
            packId: 'hadith_pack:en',
            module: ContentModule.hadithPack,
            languageCode: 'en',
            languageName: 'English',
            version: '1.2.0',
            sourceUrl: 'https://hadeethenc.com/en/home',
            downloadUrl: '',
            objectKey: 'hadith/en/v1.2.0/pack.json.gz',
            fileHash: sha256.convert(remoteBytes).toString(),
            recordCount: 1,
            packSizeBytes: remoteBytes.lengthInBytes,
            lastUpdatedAt: DateTime.parse('2026-03-13T21:00:00'),
            isStarterFreeEligible: true,
            manifestUrl: 'https://packs.example.test/v1/packs/manifest',
            requiredEntitlementKey: 'hadith_plus',
          ),
        ],
        archiveBytes: remoteBytes,
      ),
    );

    await repository.initialize();
    final HadithPackInstall install = await repository.installRemotePack(
      languageCode: 'en',
      appUserId: 'ummah_test',
      platform: 'android',
      environment: 'staging',
    );
    final File archiveFile = File(install.archivePath!);

    expect(install.sourceType, 'remote');
    expect(install.installedFileHash, sha256.convert(remoteBytes).toString());
    expect(archiveFile.existsSync(), isTrue);

    await repository.removePack(languageCode: 'en');

    expect(archiveFile.existsSync(), isFalse);
    expect(await repository.getInstalledPacks(), isEmpty);
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

class _PackFixture {
  _PackFixture({
    required this.assetBundle,
    required this.assets,
  });

  factory _PackFixture.singleLanguage({
    required String languageCode,
    required String languageName,
    required String version,
    required List<Map<String, Object?>> records,
    String? overrideFileHash,
  }) {
    final String packAssetPath =
        'packages/hadith/assets/packs/hadeethenc_${languageCode}_v$version.json.gz';
    final Map<String, Object?> packPayload = <String, Object?>{
      'provider_key': 'hadeethenc',
      'language_code': languageCode,
      'language_name': languageName,
      'version': version,
      'source_url': 'https://hadeethenc.com/$languageCode/home',
      'download_url': 'https://example.test/$languageCode.xlsx',
      'last_updated_at': '2026-03-13T21:00:00',
      'records': records,
    };
    final List<int> gzBytes = gzip.encode(
      utf8.encode(jsonEncode(packPayload)),
    );
    final String fileHash =
        overrideFileHash ?? sha256.convert(gzBytes).toString();
    final Map<String, Object?> manifest = <String, Object?>{
      'provider_key': 'hadeethenc',
      'generated_at': '2026-03-13T21:00:00Z',
      'packs': <Object?>[
        <String, Object?>{
          'provider_key': 'hadeethenc',
          'language_code': languageCode,
          'language_name': languageName,
          'version': version,
          'source_url': 'https://hadeethenc.com/$languageCode/home',
          'download_url': 'https://example.test/$languageCode.xlsx',
          'asset_path': packAssetPath,
          'file_hash': fileHash,
          'record_count': records.length,
          'pack_size_bytes': gzBytes.length,
          'last_updated_at': '2026-03-13T21:00:00',
          'is_bundled': true,
        },
      ],
    };
    return _PackFixture(
      assetBundle: _MapAssetBundle(
        <String, List<int>>{
          'packages/hadith/assets/packs/manifest.json': utf8.encode(
            jsonEncode(manifest),
          ),
          packAssetPath: gzBytes,
        },
      ),
      assets: <String, List<int>>{
        'packages/hadith/assets/packs/manifest.json': utf8.encode(
          jsonEncode(manifest),
        ),
        packAssetPath: gzBytes,
      },
    );
  }

  final AssetBundle assetBundle;
  final Map<String, List<int>> assets;
}

class _MapAssetBundle extends CachingAssetBundle {
  _MapAssetBundle(this._assets);

  final Map<String, List<int>> _assets;

  @override
  Future<ByteData> load(String key) async {
    final List<int>? bytes = _assets[key];
    if (bytes == null) {
      throw StateError('Missing asset: $key');
    }
    final Uint8List data = Uint8List.fromList(bytes);
    return ByteData.view(data.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final List<int>? bytes = _assets[key];
    if (bytes == null) {
      throw StateError('Missing asset: $key');
    }
    return utf8.decode(bytes);
  }
}

class _FakeRemoteDataSource implements HadithPackRemoteDataSource {
  _FakeRemoteDataSource({
    required this.manifests,
    required this.archiveBytes,
  });

  final List<HadithPackManifest> manifests;
  final Uint8List archiveBytes;

  @override
  bool get isConfigured => true;

  @override
  Future<Uint8List> downloadPack(Uri downloadUrl) async => archiveBytes;

  @override
  Future<List<HadithPackManifest>> fetchManifest() async => manifests;

  @override
  Future<HadithPackAccessGrant> requestAccess({
    required String packId,
    required String appUserId,
    required String platform,
    required String environment,
  }) async {
    return HadithPackAccessGrant(
      packId: packId,
      downloadUrl: Uri.parse('https://example.test/download/$packId'),
      expiresAt: DateTime.parse('2026-03-13T21:00:00Z'),
      fileHash: sha256.convert(archiveBytes).toString(),
      sizeBytes: archiveBytes.lengthInBytes,
      version: manifests.first.version,
      isFree: true,
    );
  }
}
