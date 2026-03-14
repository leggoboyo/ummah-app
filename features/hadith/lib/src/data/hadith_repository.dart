import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/hadith_category.dart';
import '../domain/hadith_detail.dart';
import '../domain/hadith_finder_result.dart';
import '../domain/hadith_language.dart';
import '../domain/hadith_pack_access_grant.dart';
import '../domain/hadith_pack_install.dart';
import '../domain/hadith_pack_manifest.dart';
import '../domain/hadith_search_result.dart';
import 'hadeethenc_remote_data_source.dart';
import 'hadith_pack_remote_data_source.dart';

class HadithCategorySyncResult {
  const HadithCategorySyncResult({
    required this.categoryId,
    required this.languageCode,
    required this.hadithCount,
  });

  final int categoryId;
  final String languageCode;
  final int hadithCount;
}

class HadithPackAccessDeniedException implements Exception {
  const HadithPackAccessDeniedException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HadithPackUnavailableException implements Exception {
  const HadithPackUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HadithRepository {
  HadithRepository({
    HadeethEncRemoteDataSource? remoteDataSource,
    HadithPackRemoteDataSource? packRemoteDataSource,
    Database? database,
    Future<String> Function()? databasePathResolver,
    AssetBundle? assetBundle,
    DateTime Function()? clock,
  })  : _remoteDataSource = remoteDataSource ?? HadeethEncApiDataSource(),
        _packRemoteDataSource =
            packRemoteDataSource ?? _defaultPackRemoteDataSource(),
        _providedDatabase = database,
        _databasePathResolver = databasePathResolver,
        _assetBundle = assetBundle ?? rootBundle,
        _clock = clock ?? DateTime.now;

  static const String _providerKey = 'hadeethenc';
  static const String _providerVersion = 'API/v1';
  static const String _providerAttribution = 'HadeethEnc.com';
  static const String _packContentKeyPrefix = 'sunni_pack_';
  static const String _packArchiveDirectory = 'hadith_packs';
  static const String _packManifestAsset =
      'packages/hadith/assets/packs/manifest.json';

  static final RegExp _arabicDiacritics = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED]',
  );
  static final RegExp _nonSearchCharacters = RegExp(
    r'[^0-9a-z\u0600-\u06FF]+',
  );
  static final RegExp _multiWhitespace = RegExp(r'\s+');

  static const Set<String> _stopWords = <String>{
    'a',
    'an',
    'and',
    'are',
    'about',
    'for',
    'from',
    'how',
    'i',
    'if',
    'in',
    'is',
    'it',
    'of',
    'on',
    'or',
    'the',
    'to',
    'what',
    'when',
    'where',
    'with',
  };

  static const Map<String, List<String>> _synonymGroups =
      <String, List<String>>{
    'prayer': <String>[
      'prayer',
      'pray',
      'praying',
      'salah',
      'salat',
      'namaz',
      'صلاة',
      'صلاه',
      'نماز',
    ],
    'ablution': <String>[
      'ablution',
      'wudu',
      'wudhu',
      'وضوء',
      'وضو',
    ],
    'fasting': <String>[
      'fast',
      'fasting',
      'sawm',
      'roza',
      'صوم',
      'روزہ',
      'روزه',
    ],
    'charity': <String>[
      'charity',
      'zakat',
      'sadaqah',
      'زكاة',
      'زکاة',
      'صدقة',
      'صدقہ',
    ],
    'intention': <String>[
      'intention',
      'niyyah',
      'نية',
      'نیت',
    ],
    'mercy': <String>[
      'mercy',
      'compassion',
      'kindness',
      'رحمة',
      'رحمت',
    ],
    'parents': <String>[
      'parents',
      'parent',
      'mother',
      'father',
      'family',
      'والدين',
      'والدین',
      'ماں',
      'باپ',
    ],
    'marriage': <String>[
      'marriage',
      'marry',
      'nikah',
      'نكاح',
      'نکاح',
    ],
    'divorce': <String>[
      'divorce',
      'talaq',
      'طلاق',
    ],
    'business': <String>[
      'business',
      'trade',
      'buying',
      'selling',
      'sale',
      'شراء',
      'بيع',
      'تجارت',
    ],
    'lying': <String>[
      'lying',
      'lie',
      'false',
      'falsehood',
      'كذب',
      'جھوٹ',
    ],
    'anger': <String>[
      'anger',
      'angry',
      'ghadab',
      'غضب',
    ],
    'neighbor': <String>[
      'neighbor',
      'neighbour',
      'جار',
      'ہمسایہ',
    ],
    'knowledge': <String>[
      'knowledge',
      'learn',
      'learning',
      'علم',
    ],
    'quran': <String>[
      'quran',
      'quran',
      'قرآن',
      'قران',
    ],
  };

  static final Map<String, String> _synonymIndex =
      _buildSynonymIndex(_synonymGroups);
  static final Set<String> _suggestionVocabulary = <String>{
    ..._stopWords,
    ..._synonymGroups.keys,
    ..._synonymIndex.keys,
  };

  final HadeethEncRemoteDataSource _remoteDataSource;
  final HadithPackRemoteDataSource _packRemoteDataSource;
  final Database? _providedDatabase;
  final Future<String> Function()? _databasePathResolver;
  final AssetBundle _assetBundle;
  final DateTime Function() _clock;

  Database? _database;
  List<HadithPackManifest>? _availablePackCache;

  Future<void> initialize() async {
    if (_database != null) {
      return;
    }

    _database = _providedDatabase ?? sqlite3.open(await _resolveDatabasePath());
    _createSchema(_database!);
  }

  Future<List<HadithLanguage>> getLocalLanguages() async {
    final Database db = await _db;
    final ResultSet rows = db.select(
      'SELECT code, native_name FROM languages ORDER BY code',
    );
    return rows.map((Row row) {
      return HadithLanguage(
        code: row['code'] as String,
        nativeName: row['native_name'] as String,
      );
    }).toList(growable: false);
  }

  Future<List<HadithLanguage>> refreshLanguages() async {
    final List<HadithLanguage> languages =
        await _remoteDataSource.listLanguages();
    final Database db = await _db;
    _runInTransaction(db, () {
      final PreparedStatement statement = db.prepare(
        '''
        INSERT INTO languages (code, native_name)
        VALUES (?1, ?2)
        ON CONFLICT(code) DO UPDATE SET
          native_name = excluded.native_name
        ''',
      );
      try {
        for (final HadithLanguage language in languages) {
          statement.execute(<Object?>[
            language.code,
            language.nativeName,
          ]);
        }
      } finally {
        statement.close();
      }
    });
    return getLocalLanguages();
  }

  Future<List<HadithCategory>> getRootCategories({
    required String languageCode,
  }) async {
    final Database db = await _db;
    final ResultSet rows = db.select(
      '''
      SELECT c.category_id, c.language_code, c.title, c.hadith_count, c.parent_id,
             c.last_synced_at,
             COUNT(ch.hadith_id) AS cached_count
      FROM categories c
      LEFT JOIN category_hadiths ch
        ON ch.language_code = c.language_code
       AND ch.category_id = c.category_id
      WHERE c.language_code = ?1
      GROUP BY c.category_id, c.language_code, c.title, c.hadith_count, c.parent_id, c.last_synced_at
      ORDER BY c.category_id
      ''',
      <Object?>[languageCode],
    );

    return rows.map(_categoryFromRow).toList(growable: false);
  }

  Future<List<HadithCategory>> refreshRootCategories({
    required String languageCode,
  }) async {
    final List<HadithCategory> categories =
        await _remoteDataSource.listRootCategories(languageCode: languageCode);
    final Database db = await _db;
    _runInTransaction(db, () {
      final PreparedStatement statement = db.prepare(
        '''
        INSERT INTO categories (
          category_id,
          language_code,
          title,
          hadith_count,
          parent_id,
          last_synced_at
        )
        VALUES (?1, ?2, ?3, ?4, ?5,
          COALESCE(
            (SELECT last_synced_at FROM categories WHERE category_id = ?1 AND language_code = ?2),
            NULL
          )
        )
        ON CONFLICT(category_id, language_code) DO UPDATE SET
          title = excluded.title,
          hadith_count = excluded.hadith_count,
          parent_id = excluded.parent_id
        ''',
      );
      try {
        for (final HadithCategory category in categories) {
          statement.execute(<Object?>[
            category.id,
            category.languageCode,
            category.title,
            category.hadithCount,
            category.parentId,
          ]);
        }
      } finally {
        statement.close();
      }
    });

    return getRootCategories(languageCode: languageCode);
  }

  Future<HadithCategorySyncResult> syncCategory({
    required String languageCode,
    required int categoryId,
    int perPage = 50,
  }) async {
    await initialize();
    final Database db = await _db;

    int page = 1;
    int lastPage = 1;
    int insertedCount = 0;
    final List<HadithListItem> listItems = <HadithListItem>[];

    do {
      final HadithListPage response = await _remoteDataSource.listHadiths(
        languageCode: languageCode,
        categoryId: categoryId,
        page: page,
        perPage: perPage,
      );
      listItems.addAll(response.items);
      lastPage = response.lastPage;
      page += 1;
    } while (page <= lastPage);

    _runInTransaction(db, () {
      db.execute(
        '''
        DELETE FROM category_hadiths
        WHERE language_code = ?1 AND category_id = ?2
        ''',
        <Object?>[languageCode, categoryId],
      );
    });

    for (final HadithListItem item in listItems) {
      final HadithDetail detail = await _remoteDataSource.fetchHadith(
        languageCode: languageCode,
        hadithId: item.id,
      );
      final String hintsText = detail.hints.join('\n');

      _runInTransaction(db, () {
        db.execute(
          '''
          INSERT INTO hadith_details (
            hadith_id, language_code, title, hadith_text, attribution, grade,
            explanation, hints_json, categories_json, translations_json,
            hadith_intro, hadith_arabic, hadith_intro_arabic, explanation_arabic,
            hints_arabic_json, words_meanings_arabic_json, attribution_arabic,
            grade_arabic, last_synced_at
          ) VALUES (
            ?1, ?2, ?3, ?4, ?5, ?6,
            ?7, ?8, ?9, ?10,
            ?11, ?12, ?13, ?14,
            ?15, ?16, ?17, ?18, ?19
          )
          ON CONFLICT(hadith_id, language_code) DO UPDATE SET
            title = excluded.title,
            hadith_text = excluded.hadith_text,
            attribution = excluded.attribution,
            grade = excluded.grade,
            explanation = excluded.explanation,
            hints_json = excluded.hints_json,
            categories_json = excluded.categories_json,
            translations_json = excluded.translations_json,
            hadith_intro = excluded.hadith_intro,
            hadith_arabic = excluded.hadith_arabic,
            hadith_intro_arabic = excluded.hadith_intro_arabic,
            explanation_arabic = excluded.explanation_arabic,
            hints_arabic_json = excluded.hints_arabic_json,
            words_meanings_arabic_json = excluded.words_meanings_arabic_json,
            attribution_arabic = excluded.attribution_arabic,
            grade_arabic = excluded.grade_arabic,
            last_synced_at = excluded.last_synced_at
          ''',
          <Object?>[
            detail.id,
            detail.languageCode,
            detail.title,
            detail.hadithText,
            detail.attribution,
            detail.grade,
            detail.explanation,
            jsonEncode(detail.hints),
            jsonEncode(detail.categoryIds),
            jsonEncode(detail.translations),
            detail.hadithIntro,
            detail.hadithArabic,
            detail.hadithIntroArabic,
            detail.explanationArabic,
            jsonEncode(detail.hintsArabic),
            jsonEncode(detail.wordsMeaningsArabic),
            detail.attributionArabic,
            detail.gradeArabic,
            _clock().toIso8601String(),
          ],
        );
        db.execute(
          '''
          DELETE FROM hadith_fts
          WHERE hadith_id = ?1 AND language_code = ?2
          ''',
          <Object?>[
            detail.id,
            detail.languageCode,
          ],
        );
        db.execute(
          '''
          INSERT INTO hadith_fts (
            hadith_id, language_code, title, hadith_text,
            explanation, attribution, grade, hints_text
          ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
          ''',
          <Object?>[
            detail.id,
            detail.languageCode,
            detail.title,
            detail.hadithText,
            detail.explanation,
            detail.attribution,
            detail.grade,
            hintsText,
          ],
        );
        db.execute(
          '''
          INSERT OR REPLACE INTO category_hadiths (
            category_id, language_code, hadith_id
          ) VALUES (?1, ?2, ?3)
          ''',
          <Object?>[
            categoryId,
            languageCode,
            detail.id,
          ],
        );
        db.execute(
          '''
          UPDATE categories
          SET last_synced_at = ?3
          WHERE category_id = ?1 AND language_code = ?2
          ''',
          <Object?>[
            categoryId,
            languageCode,
            _clock().toIso8601String(),
          ],
        );
        _upsertSourceVersion(
          db,
          SourceVersion(
            providerKey: _providerKey,
            contentKey: 'sunni_$languageCode',
            languageCode: languageCode,
            version: _providerVersion,
            attribution: _providerAttribution,
            lastSyncedAt: _clock(),
          ),
        );
      });
      insertedCount += 1;
    }

    return HadithCategorySyncResult(
      categoryId: categoryId,
      languageCode: languageCode,
      hadithCount: insertedCount,
    );
  }

  Future<List<HadithPackManifest>> getAvailablePacks() async {
    if (_availablePackCache != null) {
      return _availablePackCache!;
    }

    try {
      if (_packRemoteDataSource.isConfigured) {
        _availablePackCache = await _packRemoteDataSource.fetchManifest()
          ..sort((HadithPackManifest a, HadithPackManifest b) {
            return a.languageCode.compareTo(b.languageCode);
          });
        return _availablePackCache!;
      }
    } catch (error) {
      final List<HadithPackManifest>? bundled =
          await _loadBundledPackManifest();
      if (bundled != null && bundled.isNotEmpty) {
        _availablePackCache = bundled
          ..sort((HadithPackManifest a, HadithPackManifest b) {
            return a.languageCode.compareTo(b.languageCode);
          });
        return _availablePackCache!;
      }
      throw HadithPackUnavailableException(
        'Remote Hadith pack delivery is not available in this build yet: $error',
      );
    }

    final List<HadithPackManifest>? bundled = await _loadBundledPackManifest();
    if (bundled != null && bundled.isNotEmpty) {
      _availablePackCache = bundled
        ..sort((HadithPackManifest a, HadithPackManifest b) {
          return a.languageCode.compareTo(b.languageCode);
        });
      return _availablePackCache!;
    }

    throw const HadithPackUnavailableException(
      'Remote Hadith pack delivery is not configured in this build yet.',
    );
  }

  Future<HadithPackManifest?> getPackForLanguage(String languageCode) async {
    final String target = _canonicalizeLanguageCode(languageCode);
    final List<HadithPackManifest> packs = await getAvailablePacks();
    for (final HadithPackManifest pack in packs) {
      if (pack.languageCode == target) {
        return pack;
      }
    }
    return null;
  }

  Future<HadithPackManifest?> getRecommendedPack({
    required String preferredLanguageCode,
  }) async {
    final List<HadithPackManifest> packs = await getAvailablePacks();
    final String canonical = _canonicalizeLanguageCode(preferredLanguageCode);
    for (final HadithPackManifest pack in packs) {
      if (pack.languageCode == canonical) {
        return pack;
      }
    }
    for (final HadithPackManifest pack in packs) {
      if (pack.languageCode == 'en') {
        return pack;
      }
    }
    return packs.isEmpty ? null : packs.first;
  }

  Future<List<HadithPackInstall>> getInstalledPacks() async {
    final Database db = await _db;
    final ResultSet rows = db.select(
      '''
      SELECT language_code, language_name, version, provider_key, installed_at,
             file_hash, installed_file_hash, record_count, pack_size_bytes,
             is_complete, source_type, last_validated_at, archive_version,
             archive_path
      FROM hadith_pack_installs
      ORDER BY language_code
      ''',
    );
    return rows.map((Row row) {
      return HadithPackInstall(
        languageCode: row['language_code'] as String,
        languageName: row['language_name'] as String,
        version: row['version'] as String,
        providerKey: row['provider_key'] as String,
        sourceType: row['source_type'] as String? ?? 'bundled',
        installedAt: DateTime.tryParse(row['installed_at'] as String? ?? '')
                ?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        fileHash: row['file_hash'] as String,
        installedFileHash: row['installed_file_hash'] as String? ??
            (row['file_hash'] as String? ?? ''),
        recordCount: row['record_count'] as int,
        packSizeBytes: row['pack_size_bytes'] as int,
        isComplete: (row['is_complete'] as int) == 1,
        lastValidatedAt: DateTime.tryParse(
          row['last_validated_at'] as String? ?? '',
        )?.toLocal(),
        archiveVersion: row['archive_version'] as String?,
        archivePath: row['archive_path'] as String?,
      );
    }).toList(growable: false);
  }

  Future<HadithPackInstall> installBundledPack({
    required String languageCode,
  }) async {
    final HadithPackManifest? manifest = await getPackForLanguage(languageCode);
    if (manifest == null) {
      throw StateError(
          'No bundled Hadith pack is available for $languageCode.');
    }

    final Map<String, dynamic> payload = await _loadPackPayload(manifest);
    return _installPackPayload(
      manifest: manifest,
      payload: payload,
      sourceType: 'bundled',
      installedFileHash: manifest.fileHash,
      lastValidatedAt: _clock(),
      archiveVersion: manifest.version,
      archivePath: null,
    );
  }

  Future<HadithPackInstall> installRemotePack({
    required String languageCode,
    required String appUserId,
    required String platform,
    required String environment,
  }) async {
    final HadithPackManifest? manifest = await getPackForLanguage(languageCode);
    if (manifest == null) {
      throw HadithPackUnavailableException(
        'No remote Hadith pack is available for $languageCode.',
      );
    }

    final HadithPackAccessGrant grant;
    try {
      grant = await _packRemoteDataSource.requestAccess(
        packId: manifest.packId,
        appUserId: appUserId,
        platform: platform,
        environment: environment,
      );
    } catch (error) {
      final String message = '$error';
      if (message.contains('denied') || message.contains('(403)')) {
        throw const HadithPackAccessDeniedException(
          'This Sunni Hadith pack is not unlocked for the current device account.',
        );
      }
      throw HadithPackUnavailableException(
        'Remote Hadith pack access could not be prepared: $error',
      );
    }

    final Uint8List archiveBytes = await _packRemoteDataSource.downloadPack(
      grant.downloadUrl,
    );
    final String archiveHash = sha256.convert(archiveBytes).toString();
    if (archiveHash != manifest.fileHash || archiveHash != grant.fileHash) {
      throw StateError(
        'Downloaded Hadith pack failed integrity verification for ${manifest.languageCode}.',
      );
    }
    if (archiveBytes.lengthInBytes != manifest.packSizeBytes ||
        archiveBytes.lengthInBytes != grant.sizeBytes) {
      throw StateError(
        'Downloaded Hadith pack size did not match the manifest for ${manifest.languageCode}.',
      );
    }

    final File tempArchive = await _writePackTempArchive(
      packId: manifest.packId,
      bytes: archiveBytes,
    );
    final File archiveFile = await _persistPackArchive(
      packId: manifest.packId,
      version: manifest.version,
      bytes: archiveBytes,
    );

    try {
      final Map<String, dynamic> payload =
          _decodePackArchiveBytes(archiveBytes);
      return await _installPackPayload(
        manifest: manifest,
        payload: payload,
        sourceType: 'remote',
        installedFileHash: archiveHash,
        lastValidatedAt: _clock(),
        archiveVersion: grant.version,
        archivePath: archiveFile.path,
      );
    } finally {
      if (tempArchive.existsSync()) {
        await tempArchive.delete();
      }
    }
  }

  Future<HadithPackInstall> _installPackPayload({
    required HadithPackManifest manifest,
    required Map<String, dynamic> payload,
    required String sourceType,
    required String installedFileHash,
    required DateTime lastValidatedAt,
    required String archiveVersion,
    required String? archivePath,
  }) async {
    final List<dynamic> rawRecords =
        payload['records'] as List<dynamic>? ?? const <dynamic>[];
    final DateTime installedAt = _clock();
    final Database db = await _db;

    _runInTransaction(db, () {
      db.execute(
        'DELETE FROM hadith_pack_fts WHERE language_code = ?1',
        <Object?>[manifest.languageCode],
      );
      db.execute(
        'DELETE FROM hadith_pack_entries WHERE language_code = ?1',
        <Object?>[manifest.languageCode],
      );
      db.execute(
        'DELETE FROM hadith_pack_installs WHERE language_code = ?1',
        <Object?>[manifest.languageCode],
      );

      final PreparedStatement entryStatement = db.prepare(
        '''
        INSERT INTO hadith_pack_entries (
          hadith_id, language_code, language_name, provider_key, version,
          title, title_arabic, hadith_text, hadith_text_arabic,
          explanation, explanation_arabic, benefits_json, benefits_arabic_json,
          words_meanings_arabic_json, grade, grade_arabic,
          source_reference, source_reference_arabic, source_url, installed_at
        ) VALUES (
          ?1, ?2, ?3, ?4, ?5,
          ?6, ?7, ?8, ?9,
          ?10, ?11, ?12, ?13,
          ?14, ?15, ?16,
          ?17, ?18, ?19, ?20
        )
        ''',
      );
      final PreparedStatement ftsStatement = db.prepare(
        '''
        INSERT INTO hadith_pack_fts (
          hadith_id, language_code, title, hadith_text,
          explanation, benefits_text, source_reference, synonyms_text
        ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
        ''',
      );

      try {
        for (final Map<String, dynamic> record
            in rawRecords.whereType<Map<String, dynamic>>()) {
          final List<String> benefits = _readStringList(record['benefits']);
          final List<String> benefitsArabic =
              _readStringList(record['benefits_arabic']);
          final List<String> wordsMeaningsArabic =
              _readStringList(record['words_meanings_arabic']);
          final String searchableText = <String>[
            record['title'] as String? ?? '',
            record['title_arabic'] as String? ?? '',
            record['hadith_text'] as String? ?? '',
            record['hadith_text_arabic'] as String? ?? '',
            record['explanation'] as String? ?? '',
            record['explanation_arabic'] as String? ?? '',
            ...benefits,
            ...benefitsArabic,
            ...wordsMeaningsArabic,
            record['source_reference'] as String? ?? '',
            record['source_reference_arabic'] as String? ?? '',
          ].join('\n');
          final List<String> canonicalTags =
              _canonicalTagsForSearchableText(searchableText);

          entryStatement.execute(<Object?>[
            (record['id'] as num).toInt(),
            manifest.languageCode,
            manifest.languageName,
            manifest.providerKey,
            manifest.version,
            record['title'] as String? ?? '',
            record['title_arabic'] as String? ?? '',
            record['hadith_text'] as String? ?? '',
            record['hadith_text_arabic'] as String? ?? '',
            record['explanation'] as String? ?? '',
            record['explanation_arabic'] as String? ?? '',
            jsonEncode(benefits),
            jsonEncode(benefitsArabic),
            jsonEncode(wordsMeaningsArabic),
            record['grade'] as String? ?? '',
            record['grade_arabic'] as String? ?? '',
            record['source_reference'] as String? ?? '',
            record['source_reference_arabic'] as String? ?? '',
            record['source_url'] as String? ?? '',
            installedAt.toIso8601String(),
          ]);
          ftsStatement.execute(<Object?>[
            (record['id'] as num).toInt(),
            manifest.languageCode,
            record['title'] as String? ?? '',
            record['hadith_text'] as String? ?? '',
            record['explanation'] as String? ?? '',
            benefits.join('\n'),
            record['source_reference'] as String? ?? '',
            canonicalTags.join(' '),
          ]);
        }
      } finally {
        entryStatement.close();
        ftsStatement.close();
      }

      db.execute(
        '''
        INSERT INTO hadith_pack_installs (
          language_code, language_name, provider_key, version,
          source_url, download_url, file_hash, record_count,
          pack_size_bytes, installed_at, is_complete, source_type,
          installed_file_hash, last_validated_at, archive_version, archive_path
        ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, 1, ?11, ?12, ?13, ?14, ?15)
        ''',
        <Object?>[
          manifest.languageCode,
          manifest.languageName,
          manifest.providerKey,
          manifest.version,
          manifest.sourceUrl,
          manifest.downloadUrl,
          manifest.fileHash,
          manifest.recordCount,
          manifest.packSizeBytes,
          installedAt.toIso8601String(),
          sourceType,
          installedFileHash,
          lastValidatedAt.toIso8601String(),
          archiveVersion,
          archivePath,
        ],
      );
      db.execute(
        '''
        INSERT INTO languages (code, native_name)
        VALUES (?1, ?2)
        ON CONFLICT(code) DO UPDATE SET
          native_name = excluded.native_name
        ''',
        <Object?>[
          manifest.languageCode,
          manifest.languageName,
        ],
      );
      _upsertSourceVersion(
        db,
        SourceVersion(
          providerKey: manifest.providerKey,
          contentKey: '$_packContentKeyPrefix${manifest.languageCode}',
          languageCode: manifest.languageCode,
          version: manifest.version,
          attribution: '$_providerAttribution • ${manifest.languageName}',
          lastSyncedAt: installedAt,
        ),
      );
    });

    return (await getInstalledPacks()).firstWhere(
      (HadithPackInstall pack) => pack.languageCode == manifest.languageCode,
    );
  }

  Future<void> removePack({
    required String languageCode,
  }) async {
    final HadithPackInstall? existing = await _findInstalledPack(languageCode);
    final Database db = await _db;
    _runInTransaction(db, () {
      db.execute(
        'DELETE FROM hadith_pack_fts WHERE language_code = ?1',
        <Object?>[languageCode],
      );
      db.execute(
        'DELETE FROM hadith_pack_entries WHERE language_code = ?1',
        <Object?>[languageCode],
      );
      db.execute(
        'DELETE FROM hadith_pack_installs WHERE language_code = ?1',
        <Object?>[languageCode],
      );
      db.execute(
        '''
        DELETE FROM source_versions
        WHERE provider_key = ?1 AND content_key = ?2 AND language_code = ?3
        ''',
        <Object?>[
          _providerKey,
          '$_packContentKeyPrefix$languageCode',
          languageCode,
        ],
      );
    });
    if (existing?.archivePath case final String archivePath?
        when archivePath.isNotEmpty) {
      final File archiveFile = File(archivePath);
      if (archiveFile.existsSync()) {
        await archiveFile.delete();
      }
    }
  }

  Future<List<HadithPackManifest>> getAvailablePackUpdates() async {
    final List<HadithPackManifest> manifests = await getAvailablePacks();
    final Map<String, HadithPackInstall> installs = <String, HadithPackInstall>{
      for (final HadithPackInstall install in await getInstalledPacks())
        install.languageCode: install,
    };
    return manifests.where((HadithPackManifest manifest) {
      final HadithPackInstall? installed = installs[manifest.languageCode];
      if (installed == null) {
        return false;
      }
      return installed.version != manifest.version ||
          installed.fileHash != manifest.fileHash ||
          !installed.isComplete;
    }).toList(growable: false);
  }

  Future<List<HadithFinderResult>> findForUseCase({
    required String query,
    required String preferredLanguageCode,
    int limit = 20,
  }) async {
    final _FinderQuery finderQuery = _FinderQuery.fromRaw(
      query,
      stopWords: _stopWords,
      synonymIndex: _synonymIndex,
    );
    if (finderQuery.tokens.isEmpty) {
      return const <HadithFinderResult>[];
    }

    final List<HadithPackInstall> installedPacks = await getInstalledPacks();
    if (installedPacks.isEmpty) {
      return const <HadithFinderResult>[];
    }

    final String primaryLanguage = _resolveSearchLanguage(
      preferredLanguageCode: preferredLanguageCode,
      installedPacks: installedPacks,
    );
    final List<HadithFinderResult> primaryResults = await _searchPackLanguage(
      finderQuery: finderQuery,
      languageCode: primaryLanguage,
      limit: limit,
      usedLanguageFallback:
          primaryLanguage != _canonicalizeLanguageCode(preferredLanguageCode),
    );
    if (primaryResults.isNotEmpty) {
      return primaryResults;
    }

    if (primaryLanguage != 'en' &&
        installedPacks
            .any((HadithPackInstall pack) => pack.languageCode == 'en')) {
      return _searchPackLanguage(
        finderQuery: finderQuery,
        languageCode: 'en',
        limit: limit,
        usedLanguageFallback: true,
      );
    }

    return const <HadithFinderResult>[];
  }

  Future<String?> suggestQuery({
    required String query,
    required String preferredLanguageCode,
  }) async {
    final _FinderQuery finderQuery = _FinderQuery.fromRaw(
      query,
      stopWords: _stopWords,
      synonymIndex: _synonymIndex,
    );
    if (finderQuery.rawNormalized.isEmpty) {
      return null;
    }

    final List<String> corrected = <String>[];
    bool changed = false;
    for (final String token in finderQuery.rawNormalized.split(' ')) {
      if (token.isEmpty) {
        continue;
      }
      if (_suggestionVocabulary.contains(token)) {
        corrected.add(token);
        continue;
      }
      final String? suggestion = _bestSuggestion(token);
      if (suggestion == null) {
        corrected.add(token);
        continue;
      }
      corrected.add(suggestion);
      changed = true;
    }

    if (!changed) {
      return null;
    }

    final String suggestion = corrected.join(' ');
    final List<HadithFinderResult> results = await findForUseCase(
      query: suggestion,
      preferredLanguageCode: preferredLanguageCode,
      limit: 5,
    );
    return results.isEmpty ? null : suggestion;
  }

  Future<List<HadithSearchResult>> search({
    required String query,
    required String languageCode,
    int limit = 30,
  }) async {
    final List<HadithFinderResult> packResults = await findForUseCase(
      query: query,
      preferredLanguageCode: languageCode,
      limit: limit,
    );
    if (packResults.isNotEmpty) {
      return packResults
          .map((HadithFinderResult result) => result.result)
          .toList(growable: false);
    }

    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <HadithSearchResult>[];
    }

    final Database db = await _db;
    final String ftsQuery = _buildLegacyFtsQuery(trimmed);
    final ResultSet rows = db.select(
      '''
      SELECT hadith_id, language_code, title, hadith_text, explanation, attribution, grade
      FROM hadith_fts
      WHERE hadith_fts MATCH ?1
        AND language_code = ?2
      ORDER BY bm25(hadith_fts), hadith_id
      LIMIT ?3
      ''',
      <Object?>[ftsQuery, languageCode, limit],
    );

    if (rows.isNotEmpty) {
      return rows.map(_legacySearchResultFromRow).toList(growable: false);
    }

    final ResultSet fallback = db.select(
      '''
      SELECT hadith_id, language_code, title, hadith_text, explanation, attribution, grade
      FROM hadith_details
      WHERE language_code = ?1
        AND (
          title LIKE ?2 OR
          hadith_text LIKE ?2 OR
          explanation LIKE ?2 OR
          attribution LIKE ?2 OR
          grade LIKE ?2
        )
      ORDER BY hadith_id
      LIMIT ?3
      ''',
      <Object?>[languageCode, '%$trimmed%', limit],
    );

    return fallback.map(_legacySearchResultFromRow).toList(growable: false);
  }

  Future<List<HadithSearchResult>> getCachedHadithsForCategory({
    required String languageCode,
    required int categoryId,
    int limit = 120,
  }) async {
    final Database db = await _db;
    final ResultSet rows = db.select(
      '''
      SELECT d.hadith_id, d.language_code, d.title, d.hadith_text,
             d.explanation, d.attribution, d.grade
      FROM category_hadiths c
      JOIN hadith_details d
        ON d.hadith_id = c.hadith_id
       AND d.language_code = c.language_code
      WHERE c.language_code = ?1
        AND c.category_id = ?2
      ORDER BY d.hadith_id
      LIMIT ?3
      ''',
      <Object?>[languageCode, categoryId, limit],
    );

    return rows.map(_legacySearchResultFromRow).toList(growable: false);
  }

  Future<HadithDetail?> getHadithDetail({
    required String languageCode,
    required int hadithId,
  }) async {
    final Database db = await _db;
    final ResultSet packRows = db.select(
      '''
      SELECT *
      FROM hadith_pack_entries
      WHERE language_code = ?1
        AND hadith_id = ?2
      LIMIT 1
      ''',
      <Object?>[languageCode, hadithId],
    );
    if (packRows.isNotEmpty) {
      final List<String> translations = db
          .select(
            '''
            SELECT language_code
            FROM hadith_pack_entries
            WHERE hadith_id = ?1
            ORDER BY language_code
            ''',
            <Object?>[hadithId],
          )
          .map((Row row) => row['language_code'] as String)
          .toList(growable: false);
      return _packDetailFromRow(packRows.first, translations: translations);
    }

    final ResultSet rows = db.select(
      '''
      SELECT *
      FROM hadith_details
      WHERE language_code = ?1
        AND hadith_id = ?2
      LIMIT 1
      ''',
      <Object?>[languageCode, hadithId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _legacyDetailFromRow(rows.first);
  }

  Future<List<SourceVersion>> getSourceVersions() async {
    final Database db = await _db;
    final ResultSet rows = db.select(
      '''
      SELECT provider_key, content_key, language_code, version, attribution, last_synced_at
      FROM source_versions
      ORDER BY provider_key, content_key, language_code
      ''',
    );

    return rows.map((Row row) {
      return SourceVersion(
        providerKey: row['provider_key'] as String,
        contentKey: row['content_key'] as String,
        languageCode: row['language_code'] as String,
        version: row['version'] as String,
        attribution: row['attribution'] as String,
        lastSyncedAt: _readDateTime(row['last_synced_at']),
      );
    }).toList(growable: false);
  }

  Future<void> dispose() async {
    _database?.close();
    _database = null;
  }

  Future<Database> get _db async {
    await initialize();
    return _database!;
  }

  static HadithPackRemoteDataSource _defaultPackRemoteDataSource() {
    const String baseUrl =
        String.fromEnvironment('apiBaseUrl', defaultValue: '');
    const String environment =
        String.fromEnvironment('appFlavor', defaultValue: 'dev');
    if (baseUrl.isEmpty) {
      return const UnconfiguredHadithPackRemoteDataSource();
    }
    return HadithPackApiDataSource(
      baseUrl: baseUrl,
      environment: environment,
    );
  }

  Future<List<HadithPackManifest>?> _loadBundledPackManifest() async {
    try {
      final String rawManifest =
          await _assetBundle.loadString(_packManifestAsset);
      final Map<String, dynamic> payload =
          jsonDecode(rawManifest) as Map<String, dynamic>;
      return (payload['packs'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(HadithPackManifest.fromJson)
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _loadPackPayload(
      HadithPackManifest manifest) async {
    final String? assetPath = manifest.assetPath;
    if (assetPath == null || assetPath.isEmpty) {
      throw StateError(
        'Bundled Hadith pack asset path is missing for ${manifest.languageCode}.',
      );
    }
    final ByteData packData = await _assetBundle.load(assetPath);
    final Uint8List rawBytes = packData.buffer.asUint8List(
      packData.offsetInBytes,
      packData.lengthInBytes,
    );
    return _decodePackArchiveBytes(rawBytes, manifest: manifest);
  }

  Map<String, dynamic> _decodePackArchiveBytes(
    Uint8List rawBytes, {
    HadithPackManifest? manifest,
  }) {
    final String actualHash = sha256.convert(rawBytes).toString();
    if (manifest != null && actualHash != manifest.fileHash) {
      throw StateError(
        'Hadith pack hash mismatch for ${manifest.languageCode}.',
      );
    }

    final Map<String, dynamic> payload =
        jsonDecode(utf8.decode(gzip.decode(rawBytes))) as Map<String, dynamic>;
    final int recordCount =
        (payload['records'] as List<dynamic>? ?? const <dynamic>[]).length;
    if (manifest != null && recordCount != manifest.recordCount) {
      throw StateError(
        'Hadith pack record count mismatch for ${manifest.languageCode}.',
      );
    }
    return payload;
  }

  Future<File> _writePackTempArchive({
    required String packId,
    required Uint8List bytes,
  }) async {
    final Directory tempDirectory = await getTemporaryDirectory();
    final String safePackId =
        packId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final File file = File(
      path.join(tempDirectory.path,
          '$safePackId-${DateTime.now().microsecondsSinceEpoch}.json.gz'),
    );
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> _persistPackArchive({
    required String packId,
    required String version,
    required Uint8List bytes,
  }) async {
    final String directoryPath = await _packArchiveDirectoryPath();
    final String safePackId =
        packId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final String safeVersion =
        version.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final Directory directory =
        Directory(path.join(directoryPath, safePackId, safeVersion));
    await directory.create(recursive: true);
    final File archive = File(path.join(directory.path, 'pack.json.gz'));
    await archive.writeAsBytes(bytes, flush: true);
    return archive;
  }

  Future<String> _packArchiveDirectoryPath() async {
    final Directory supportDirectory = await getApplicationSupportDirectory();
    final Directory archiveDirectory =
        Directory(path.join(supportDirectory.path, _packArchiveDirectory));
    await archiveDirectory.create(recursive: true);
    return archiveDirectory.path;
  }

  Future<HadithPackInstall?> _findInstalledPack(String languageCode) async {
    final String canonical = _canonicalizeLanguageCode(languageCode);
    for (final HadithPackInstall install in await getInstalledPacks()) {
      if (install.languageCode == canonical) {
        return install;
      }
    }
    return null;
  }

  Future<List<HadithFinderResult>> _searchPackLanguage({
    required _FinderQuery finderQuery,
    required String languageCode,
    required int limit,
    required bool usedLanguageFallback,
  }) async {
    final Database db = await _db;
    final Set<String> searchTerms = <String>{
      ...finderQuery.tokens,
      ...finderQuery.expandedTokens,
      ...finderQuery.canonicalTerms,
    };
    final String? ftsQuery = _buildPackFtsQuery(searchTerms);
    List<Row> rows;
    if (ftsQuery == null) {
      rows = const <Row>[];
    } else {
      rows = db.select(
        '''
        SELECT e.*, f.synonyms_text
        FROM hadith_pack_fts f
        JOIN hadith_pack_entries e
          ON e.hadith_id = f.hadith_id
         AND e.language_code = f.language_code
        WHERE f.hadith_pack_fts MATCH ?1
          AND e.language_code = ?2
        ORDER BY bm25(hadith_pack_fts), e.hadith_id
        LIMIT ?3
        ''',
        <Object?>[ftsQuery, languageCode, limit * 4],
      );
    }

    if (rows.isEmpty) {
      rows = db.select(
        '''
        SELECT e.*, '' AS synonyms_text
        FROM hadith_pack_entries e
        WHERE e.language_code = ?1
          AND (
            e.title LIKE ?2 OR
            e.hadith_text LIKE ?2 OR
            e.explanation LIKE ?2 OR
            e.source_reference LIKE ?2
          )
        ORDER BY e.hadith_id
        LIMIT ?3
        ''',
        <Object?>[languageCode, '%${finderQuery.original.trim()}%', limit * 4],
      );
    }

    final List<HadithFinderResult> scored = <HadithFinderResult>[];
    for (final Row row in rows) {
      final _ScoredPackRow? scoredRow = _scorePackRow(
        row: row,
        finderQuery: finderQuery,
        usedLanguageFallback: usedLanguageFallback,
      );
      if (scoredRow != null) {
        scored.add(scoredRow.result);
      }
    }

    scored.sort((HadithFinderResult a, HadithFinderResult b) {
      final int scoreOrder = b.score.compareTo(a.score);
      if (scoreOrder != 0) {
        return scoreOrder;
      }
      return a.result.id.compareTo(b.result.id);
    });
    if (scored.length <= limit) {
      return scored;
    }
    return scored.take(limit).toList(growable: false);
  }

  _ScoredPackRow? _scorePackRow({
    required Row row,
    required _FinderQuery finderQuery,
    required bool usedLanguageFallback,
  }) {
    final String title = row['title'] as String? ?? '';
    final String hadithText = row['hadith_text'] as String? ?? '';
    final String explanation = row['explanation'] as String? ?? '';
    final String sourceReference = row['source_reference'] as String? ?? '';
    final List<String> benefits = _decodeStringList(row['benefits_json']);
    final String benefitsText = benefits.join(' ');
    final String synonymsText = row['synonyms_text'] as String? ?? '';

    final String normalizedTitle = _normalizeForSearch(title);
    final String normalizedHadithText = _normalizeForSearch(hadithText);
    final String normalizedExplanation = _normalizeForSearch(explanation);
    final String normalizedBenefits = _normalizeForSearch(benefitsText);
    final String normalizedSourceReference =
        _normalizeForSearch(sourceReference);
    final String normalizedSynonyms = _normalizeForSearch(synonymsText);
    final String normalizedPhrase = finderQuery.rawNormalized;

    double score = 0;
    final Set<String> reasons = <String>{};

    if (normalizedPhrase.isNotEmpty &&
        normalizedTitle.contains(normalizedPhrase)) {
      score += 60;
      reasons.add('Matched in title');
    }
    if (normalizedPhrase.isNotEmpty &&
        normalizedHadithText.contains(normalizedPhrase)) {
      score += 42;
      reasons.add('Matched in hadith text');
    }
    if (normalizedPhrase.isNotEmpty &&
        normalizedExplanation.contains(normalizedPhrase)) {
      score += 36;
      reasons.add('Matched in explanation');
    }
    if (normalizedPhrase.isNotEmpty &&
        normalizedBenefits.contains(normalizedPhrase)) {
      score += 24;
      reasons.add('Matched in lessons and benefits');
    }

    for (final String token in finderQuery.tokens) {
      if (normalizedTitle.contains(token)) {
        score += 18;
        reasons.add('Matched in title');
      }
      if (normalizedHadithText.contains(token)) {
        score += 14;
        reasons.add('Matched in hadith text');
      }
      if (normalizedExplanation.contains(token)) {
        score += 10;
        reasons.add('Matched in explanation');
      }
      if (normalizedBenefits.contains(token)) {
        score += 8;
        reasons.add('Matched in lessons and benefits');
      }
      if (normalizedSourceReference.contains(token)) {
        score += 6;
        reasons.add('Matched in source reference');
      }
    }

    for (final String canonical in finderQuery.canonicalTerms) {
      if (normalizedSynonyms.contains(canonical)) {
        score += 12;
        reasons.add('Related to $canonical');
      }
    }

    if (score <= 0) {
      return null;
    }

    final HadithSearchResult result = HadithSearchResult(
      id: row['hadith_id'] as int,
      languageCode: row['language_code'] as String,
      title: title,
      hadithText: hadithText,
      explanation: explanation,
      attribution: _providerAttribution,
      grade: row['grade'] as String? ?? '',
      sourceReference: sourceReference,
      sourceUrl: row['source_url'] as String? ?? '',
      matchReasons: reasons.toList(growable: false),
    );
    return _ScoredPackRow(
      result: HadithFinderResult(
        result: result,
        score: score,
        matchReasons: reasons.toList(growable: false),
        usedLanguageFallback: usedLanguageFallback,
      ),
    );
  }

  HadithCategory _categoryFromRow(Row row) {
    return HadithCategory(
      id: row['category_id'] as int,
      languageCode: row['language_code'] as String,
      title: row['title'] as String,
      hadithCount: row['hadith_count'] as int,
      parentId: row['parent_id'] as int?,
      cachedHadithCount: row['cached_count'] as int,
      lastSyncedAt: _readDateTime(row['last_synced_at']),
    );
  }

  HadithSearchResult _legacySearchResultFromRow(Row row) {
    return HadithSearchResult(
      id: row['hadith_id'] as int,
      languageCode: row['language_code'] as String,
      title: row['title'] as String,
      hadithText: row['hadith_text'] as String,
      explanation: row['explanation'] as String,
      attribution: row['attribution'] as String,
      grade: row['grade'] as String,
    );
  }

  HadithDetail _packDetailFromRow(
    Row row, {
    required List<String> translations,
  }) {
    final List<String> benefits = _decodeStringList(row['benefits_json']);
    final List<String> benefitsArabic =
        _decodeStringList(row['benefits_arabic_json']);
    final List<String> wordsMeaningsArabic =
        _decodeStringList(row['words_meanings_arabic_json']);
    final String title = row['title'] as String? ?? '';
    final String titleArabic = row['title_arabic'] as String? ?? title;
    final String hadithText = row['hadith_text'] as String? ?? '';
    final String hadithTextArabic =
        row['hadith_text_arabic'] as String? ?? hadithText;
    final String explanation = row['explanation'] as String? ?? '';
    final String explanationArabic =
        row['explanation_arabic'] as String? ?? explanation;

    return HadithDetail(
      id: row['hadith_id'] as int,
      languageCode: row['language_code'] as String,
      title: title,
      hadithText: hadithText,
      attribution: _providerAttribution,
      grade: row['grade'] as String? ?? '',
      explanation: explanation,
      hints: const <String>[],
      categoryIds: const <int>[],
      translations: translations,
      hadithIntro: title,
      hadithArabic: hadithTextArabic,
      hadithIntroArabic: titleArabic,
      explanationArabic: explanationArabic,
      hintsArabic: const <String>[],
      wordsMeaningsArabic: wordsMeaningsArabic,
      attributionArabic: _providerAttribution,
      gradeArabic: row['grade_arabic'] as String? ?? '',
      titleArabic: titleArabic,
      benefits: benefits,
      benefitsArabic: benefitsArabic,
      sourceReference: row['source_reference'] as String? ?? '',
      sourceReferenceArabic: row['source_reference_arabic'] as String? ?? '',
      sourceUrl: row['source_url'] as String? ?? '',
      lastSyncedAt: _readDateTime(row['installed_at']),
    );
  }

  HadithDetail _legacyDetailFromRow(Row row) {
    return HadithDetail(
      id: row['hadith_id'] as int,
      languageCode: row['language_code'] as String,
      title: row['title'] as String,
      hadithText: row['hadith_text'] as String,
      attribution: row['attribution'] as String,
      grade: row['grade'] as String,
      explanation: row['explanation'] as String,
      hints: _decodeStringList(row['hints_json']),
      categoryIds: _decodeIntList(row['categories_json']),
      translations: _decodeStringList(row['translations_json']),
      hadithIntro: row['hadith_intro'] as String,
      hadithArabic: row['hadith_arabic'] as String,
      hadithIntroArabic: row['hadith_intro_arabic'] as String,
      explanationArabic: row['explanation_arabic'] as String,
      hintsArabic: _decodeStringList(row['hints_arabic_json']),
      wordsMeaningsArabic: _decodeStringList(
        row['words_meanings_arabic_json'],
      ),
      attributionArabic: row['attribution_arabic'] as String,
      gradeArabic: row['grade_arabic'] as String,
      lastSyncedAt: _readDateTime(row['last_synced_at']),
    );
  }

  List<String> _decodeStringList(Object? raw) {
    if (raw == null) {
      return const <String>[];
    }
    return (jsonDecode(raw as String) as List<dynamic>)
        .map((dynamic item) => item.toString())
        .toList(growable: false);
  }

  List<int> _decodeIntList(Object? raw) {
    if (raw == null) {
      return const <int>[];
    }
    return (jsonDecode(raw as String) as List<dynamic>)
        .map((dynamic item) => int.tryParse(item.toString()) ?? 0)
        .where((int item) => item > 0)
        .toList(growable: false);
  }

  void _createSchema(Database db) {
    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS languages (
        code TEXT PRIMARY KEY,
        native_name TEXT NOT NULL
      )
      ''',
    );
    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS categories (
        category_id INTEGER NOT NULL,
        language_code TEXT NOT NULL,
        title TEXT NOT NULL,
        hadith_count INTEGER NOT NULL,
        parent_id INTEGER,
        last_synced_at TEXT,
        PRIMARY KEY (category_id, language_code)
      )
      ''',
    );
    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS category_hadiths (
        category_id INTEGER NOT NULL,
        language_code TEXT NOT NULL,
        hadith_id INTEGER NOT NULL,
        PRIMARY KEY (category_id, language_code, hadith_id)
      )
      ''',
    );
    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS hadith_details (
        hadith_id INTEGER NOT NULL,
        language_code TEXT NOT NULL,
        title TEXT NOT NULL,
        hadith_text TEXT NOT NULL,
        attribution TEXT NOT NULL,
        grade TEXT NOT NULL,
        explanation TEXT NOT NULL,
        hints_json TEXT NOT NULL,
        categories_json TEXT NOT NULL,
        translations_json TEXT NOT NULL,
        hadith_intro TEXT NOT NULL,
        hadith_arabic TEXT NOT NULL,
        hadith_intro_arabic TEXT NOT NULL,
        explanation_arabic TEXT NOT NULL,
        hints_arabic_json TEXT NOT NULL,
        words_meanings_arabic_json TEXT NOT NULL,
        attribution_arabic TEXT NOT NULL,
        grade_arabic TEXT NOT NULL,
        last_synced_at TEXT,
        PRIMARY KEY (hadith_id, language_code)
      )
      ''',
    );
    db.execute(
      '''
      CREATE VIRTUAL TABLE IF NOT EXISTS hadith_fts USING fts5(
        hadith_id UNINDEXED,
        language_code UNINDEXED,
        title,
        hadith_text,
        explanation,
        attribution,
        grade,
        hints_text
      )
      ''',
    );
    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS hadith_pack_entries (
        hadith_id INTEGER NOT NULL,
        language_code TEXT NOT NULL,
        language_name TEXT NOT NULL,
        provider_key TEXT NOT NULL,
        version TEXT NOT NULL,
        title TEXT NOT NULL,
        title_arabic TEXT NOT NULL,
        hadith_text TEXT NOT NULL,
        hadith_text_arabic TEXT NOT NULL,
        explanation TEXT NOT NULL,
        explanation_arabic TEXT NOT NULL,
        benefits_json TEXT NOT NULL,
        benefits_arabic_json TEXT NOT NULL,
        words_meanings_arabic_json TEXT NOT NULL,
        grade TEXT NOT NULL,
        grade_arabic TEXT NOT NULL,
        source_reference TEXT NOT NULL,
        source_reference_arabic TEXT NOT NULL,
        source_url TEXT NOT NULL,
        installed_at TEXT NOT NULL,
        PRIMARY KEY (hadith_id, language_code)
      )
      ''',
    );
    db.execute(
      '''
      CREATE INDEX IF NOT EXISTS idx_hadith_pack_entries_language
      ON hadith_pack_entries(language_code, hadith_id)
      ''',
    );
    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS hadith_pack_installs (
        language_code TEXT PRIMARY KEY,
        language_name TEXT NOT NULL,
        provider_key TEXT NOT NULL,
        version TEXT NOT NULL,
        source_url TEXT NOT NULL,
        download_url TEXT NOT NULL,
        file_hash TEXT NOT NULL,
        record_count INTEGER NOT NULL,
        pack_size_bytes INTEGER NOT NULL,
        installed_at TEXT NOT NULL,
        is_complete INTEGER NOT NULL
      )
      ''',
    );
    _ensureColumn(
      db: db,
      table: 'hadith_pack_installs',
      column: 'source_type',
      definition: "TEXT NOT NULL DEFAULT 'bundled'",
    );
    _ensureColumn(
      db: db,
      table: 'hadith_pack_installs',
      column: 'installed_file_hash',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    _ensureColumn(
      db: db,
      table: 'hadith_pack_installs',
      column: 'last_validated_at',
      definition: 'TEXT',
    );
    _ensureColumn(
      db: db,
      table: 'hadith_pack_installs',
      column: 'archive_version',
      definition: 'TEXT',
    );
    _ensureColumn(
      db: db,
      table: 'hadith_pack_installs',
      column: 'archive_path',
      definition: 'TEXT',
    );
    db.execute(
      '''
      UPDATE hadith_pack_installs
      SET installed_file_hash = COALESCE(NULLIF(installed_file_hash, ''), file_hash),
          source_type = COALESCE(NULLIF(source_type, ''), 'bundled'),
          last_validated_at = COALESCE(last_validated_at, installed_at),
          archive_version = COALESCE(archive_version, version)
      ''',
    );
    db.execute(
      '''
      CREATE VIRTUAL TABLE IF NOT EXISTS hadith_pack_fts USING fts5(
        hadith_id UNINDEXED,
        language_code UNINDEXED,
        title,
        hadith_text,
        explanation,
        benefits_text,
        source_reference,
        synonyms_text
      )
      ''',
    );
    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS source_versions (
        provider_key TEXT NOT NULL,
        content_key TEXT NOT NULL,
        language_code TEXT NOT NULL,
        version TEXT NOT NULL,
        attribution TEXT NOT NULL,
        last_synced_at TEXT,
        PRIMARY KEY (provider_key, content_key, language_code)
      )
      ''',
    );
  }

  void _ensureColumn({
    required Database db,
    required String table,
    required String column,
    required String definition,
  }) {
    final ResultSet existing = db.select('PRAGMA table_info($table)');
    final bool hasColumn = existing.any(
      (Row row) => row['name'] == column,
    );
    if (!hasColumn) {
      db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  void _upsertSourceVersion(Database db, SourceVersion version) {
    db.execute(
      '''
      INSERT INTO source_versions (
        provider_key, content_key, language_code, version, attribution, last_synced_at
      ) VALUES (?1, ?2, ?3, ?4, ?5, ?6)
      ON CONFLICT(provider_key, content_key, language_code) DO UPDATE SET
        version = excluded.version,
        attribution = excluded.attribution,
        last_synced_at = excluded.last_synced_at
      ''',
      <Object?>[
        version.providerKey,
        version.contentKey,
        version.languageCode,
        version.version,
        version.attribution,
        version.lastSyncedAt?.toIso8601String(),
      ],
    );
  }

  void _runInTransaction(Database db, void Function() operation) {
    db.execute('BEGIN');
    try {
      operation();
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  String _buildLegacyFtsQuery(String rawQuery) {
    final List<String> tokens = rawQuery
        .split(RegExp(r'\s+'))
        .map((String token) => token.replaceAll('"', '').trim())
        .where((String token) => token.isNotEmpty)
        .toList(growable: false);

    if (tokens.isEmpty) {
      return rawQuery;
    }

    return tokens
        .map((String token) => '${token.replaceAll("'", "''")}*')
        .join(' AND ');
  }

  String? _buildPackFtsQuery(Set<String> tokens) {
    final List<String> sanitized = tokens
        .map(_sanitizeFtsToken)
        .where((String token) => token.isNotEmpty)
        .toList(growable: false);
    if (sanitized.isEmpty) {
      return null;
    }
    return sanitized.join(' OR ');
  }

  String _sanitizeFtsToken(String token) {
    final String cleaned = _normalizeForSearch(token)
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    if (cleaned.isEmpty) {
      return '';
    }
    return '$cleaned*';
  }

  String _resolveSearchLanguage({
    required String preferredLanguageCode,
    required List<HadithPackInstall> installedPacks,
  }) {
    final String preferred = _canonicalizeLanguageCode(preferredLanguageCode);
    for (final HadithPackInstall pack in installedPacks) {
      if (pack.languageCode == preferred) {
        return preferred;
      }
    }
    for (final HadithPackInstall pack in installedPacks) {
      if (pack.languageCode == 'en') {
        return 'en';
      }
    }
    return installedPacks.first.languageCode;
  }

  String _canonicalizeLanguageCode(String raw) {
    final String normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'en';
    }
    if (normalized.contains('_')) {
      return normalized.split('_').first;
    }
    if (normalized.contains('-')) {
      return normalized.split('-').first;
    }
    return normalized;
  }

  String _normalizeForSearch(String value) {
    return value
        .toLowerCase()
        .replaceAll(_arabicDiacritics, '')
        .replaceAll('’', "'")
        .replaceAll(_nonSearchCharacters, ' ')
        .replaceAll(_multiWhitespace, ' ')
        .trim();
  }

  List<String> _canonicalTagsForSearchableText(String value) {
    final String normalized = _normalizeForSearch(value);
    final Set<String> tags = <String>{};
    for (final MapEntry<String, List<String>> entry in _synonymGroups.entries) {
      for (final String synonym in entry.value) {
        final String normalizedSynonym = _normalizeForSearch(synonym);
        if (normalizedSynonym.isEmpty) {
          continue;
        }
        if (normalized.contains(normalizedSynonym)) {
          tags.add(entry.key);
          break;
        }
      }
    }
    return tags.toList(growable: false);
  }

  String? _bestSuggestion(String token) {
    String? bestMatch;
    int? bestDistance;
    for (final String candidate in _suggestionVocabulary) {
      if ((candidate.length - token.length).abs() > 2) {
        continue;
      }
      final int distance = _levenshtein(token, candidate);
      if (distance > 2) {
        continue;
      }
      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
        bestMatch = candidate;
      }
    }
    return bestMatch;
  }

  int _levenshtein(String source, String target) {
    if (source == target) {
      return 0;
    }
    if (source.isEmpty) {
      return target.length;
    }
    if (target.isEmpty) {
      return source.length;
    }

    final List<int> previous = List<int>.generate(
      target.length + 1,
      (int index) => index,
    );
    for (int i = 0; i < source.length; i += 1) {
      int current = i + 1;
      int diagonal = i;
      for (int j = 0; j < target.length; j += 1) {
        final int insertion = previous[j + 1] + 1;
        final int deletion = current + 1;
        final int substitution =
            diagonal + (source.codeUnitAt(i) == target.codeUnitAt(j) ? 0 : 1);
        diagonal = previous[j + 1];
        current = <int>[insertion, deletion, substitution]
            .reduce((int a, int b) => a < b ? a : b);
        previous[j + 1] = current;
      }
    }
    return previous.last;
  }

  DateTime? _readDateTime(Object? value) {
    final String? raw = value as String?;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

  List<String> _readStringList(Object? raw) {
    if (raw is List<dynamic>) {
      return raw
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  Future<String> _resolveDatabasePath() async {
    if (_databasePathResolver != null) {
      return _databasePathResolver();
    }

    final Directory directory = await getApplicationSupportDirectory();
    return path.join(directory.path, 'hadith_v2.sqlite');
  }
}

Map<String, String> _buildSynonymIndex(Map<String, List<String>> groups) {
  final Map<String, String> index = <String, String>{};
  for (final MapEntry<String, List<String>> entry in groups.entries) {
    index[entry.key] = entry.key;
    for (final String synonym in entry.value) {
      index[synonym] = entry.key;
    }
  }
  return index;
}

class _FinderQuery {
  const _FinderQuery({
    required this.original,
    required this.rawNormalized,
    required this.tokens,
    required this.expandedTokens,
    required this.canonicalTerms,
  });

  factory _FinderQuery.fromRaw(
    String raw, {
    required Set<String> stopWords,
    required Map<String, String> synonymIndex,
  }) {
    final String normalized = raw
        .toLowerCase()
        .replaceAll(HadithRepository._arabicDiacritics, '')
        .replaceAll('’', "'")
        .replaceAll(HadithRepository._nonSearchCharacters, ' ')
        .replaceAll(HadithRepository._multiWhitespace, ' ')
        .trim();
    final List<String> rawTokens = normalized
        .split(' ')
        .map((String token) => token.trim())
        .where((String token) => token.isNotEmpty)
        .toList(growable: false);
    final Set<String> tokens =
        rawTokens.where((String token) => !stopWords.contains(token)).toSet();
    final Set<String> canonicalTerms = <String>{};
    final Set<String> expandedTokens = <String>{};
    for (final String token in tokens) {
      expandedTokens.add(token);
      final String? canonical = synonymIndex[token];
      if (canonical != null) {
        canonicalTerms.add(canonical);
        expandedTokens.add(canonical);
        expandedTokens.addAll(
          HadithRepository._synonymGroups[canonical] ?? const <String>[],
        );
      }
    }

    return _FinderQuery(
      original: raw,
      rawNormalized: normalized,
      tokens: tokens.toList(growable: false),
      expandedTokens: expandedTokens
          .map((String token) => token.trim())
          .where((String token) => token.isNotEmpty)
          .toList(growable: false),
      canonicalTerms: canonicalTerms.toList(growable: false),
    );
  }

  final String original;
  final String rawNormalized;
  final List<String> tokens;
  final List<String> expandedTokens;
  final List<String> canonicalTerms;
}

class _ScoredPackRow {
  const _ScoredPackRow({
    required this.result,
  });

  final HadithFinderResult result;
}
