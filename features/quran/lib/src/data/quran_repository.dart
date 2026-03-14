import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/quran_ayah.dart';
import '../domain/quran_search_result.dart';
import '../domain/quran_sync_outcome.dart';
import '../domain/quran_translation_info.dart';
import '../domain/surah_summary.dart';
import 'quran_asset_seed_data_source.dart';
import 'quran_enc_remote_data_source.dart';

class QuranRepository {
  QuranRepository({
    QuranSeedDataSource? seedDataSource,
    QuranTranslationRemoteDataSource? remoteDataSource,
    Database? database,
    Future<String> Function()? databasePathResolver,
  })  : _seedDataSource = seedDataSource ?? const QuranAssetSeedDataSource(),
        _remoteDataSource = remoteDataSource ?? QuranEncRemoteDataSource(),
        _providedDatabase = database,
        _databasePathResolver = databasePathResolver;

  final QuranSeedDataSource _seedDataSource;
  final QuranTranslationRemoteDataSource _remoteDataSource;
  final Database? _providedDatabase;
  final Future<String> Function()? _databasePathResolver;

  Database? _database;
  final Map<String, Map<String, int>> _termFrequencyCache =
      <String, Map<String, int>>{};

  Future<void> initialize() async {
    if (_database != null) {
      return;
    }

    _database = _providedDatabase ?? sqlite3.open(await _resolveDatabasePath());
    _createSchema(_database!);
    await _seedBundledCorpusIfNeeded();
  }

  Future<List<SurahSummary>> getSurahs() async {
    final Database db = await _db;
    final ResultSet rows = db.select(
      '''
      SELECT number, arabic_name, transliteration, english_name, ayah_count,
             revelation_type, revelation_order, rukus
      FROM surahs
      ORDER BY number
      ''',
    );

    return rows.map(_surahFromRow).toList();
  }

  Future<List<QuranAyah>> getSurahAyahs(
    int surahNumber, {
    String? translationKey,
  }) async {
    final Database db = await _db;
    final ResultSet rows = db.select(
      '''
      SELECT a.surah_number, a.ayah_number, a.text_arabic,
             t.translation_key, t.text_translation, t.footnotes
      FROM ayahs a
      LEFT JOIN translation_ayahs t
        ON t.surah_number = a.surah_number
       AND t.ayah_number = a.ayah_number
       AND (?1 IS NULL OR t.translation_key = ?1)
      WHERE a.surah_number = ?2
      ORDER BY a.ayah_number
      ''',
      <Object?>[translationKey, surahNumber],
    );

    return rows.map((Row row) {
      return QuranAyah(
        surahNumber: row['surah_number'] as int,
        ayahNumber: row['ayah_number'] as int,
        arabicText: row['text_arabic'] as String,
        translationKey: row['translation_key'] as String?,
        translationText: row['text_translation'] as String?,
        footnotes: row['footnotes'] as String?,
      );
    }).toList();
  }

  Future<List<QuranSearchResult>> search(
    String query, {
    String? translationKey,
    int limit = 30,
  }) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <QuranSearchResult>[];
    }

    final Database db = await _db;
    final String normalizedArabicQuery = _normalizeArabicForSearch(trimmed);
    final String arabicFtsQuery = _buildFtsQuery(
      normalizedArabicQuery.isEmpty ? trimmed : normalizedArabicQuery,
    );
    final String translationFtsQuery = _buildFtsQuery(trimmed);
    final Map<String, QuranSearchResult> deduped = <String, QuranSearchResult>{};

    final ResultSet arabicRows = db.select(
      '''
      SELECT a.surah_number, a.ayah_number, s.arabic_name, s.english_name,
             a.text_arabic, t.translation_key, t.text_translation, t.footnotes
      FROM ayah_fts f
      JOIN ayahs a
        ON a.surah_number = f.surah_number
       AND a.ayah_number = f.ayah_number
      JOIN surahs s ON s.number = a.surah_number
      LEFT JOIN translation_ayahs t
        ON t.surah_number = a.surah_number
       AND t.ayah_number = a.ayah_number
       AND (?1 IS NULL OR t.translation_key = ?1)
      WHERE ayah_fts MATCH ?2
      ORDER BY bm25(ayah_fts), a.surah_number, a.ayah_number
      LIMIT ?3
      ''',
      <Object?>[translationKey, arabicFtsQuery, limit],
    );

    for (final Row row in arabicRows) {
      final QuranSearchResult result = _searchResultFromRow(
        row,
        scope: QuranSearchScope.arabic,
      );
      deduped['${result.surahNumber}:${result.ayahNumber}'] = result;
    }

    if (deduped.isEmpty) {
      final ResultSet fallbackArabicRows = db.select(
        '''
        SELECT a.surah_number, a.ayah_number, s.arabic_name, s.english_name,
               a.text_arabic, t.translation_key, t.text_translation, t.footnotes
        FROM ayahs a
        JOIN surahs s ON s.number = a.surah_number
        LEFT JOIN translation_ayahs t
          ON t.surah_number = a.surah_number
         AND t.ayah_number = a.ayah_number
         AND (?1 IS NULL OR t.translation_key = ?1)
        JOIN ayah_fts f
          ON f.surah_number = a.surah_number
         AND f.ayah_number = a.ayah_number
        WHERE f.text_arabic LIKE ?2
        ORDER BY a.surah_number, a.ayah_number
        LIMIT ?3
        ''',
        <Object?>[
          translationKey,
          '%${normalizedArabicQuery.isEmpty ? trimmed : normalizedArabicQuery}%',
          limit,
        ],
      );

      for (final Row row in fallbackArabicRows) {
        final QuranSearchResult result = _searchResultFromRow(
          row,
          scope: QuranSearchScope.arabic,
        );
        deduped['${result.surahNumber}:${result.ayahNumber}'] = result;
      }
    }

    if (translationKey != null && translationKey.isNotEmpty) {
      final ResultSet translationRows = db.select(
        '''
        SELECT t.surah_number, t.ayah_number, s.arabic_name, s.english_name,
               a.text_arabic, t.translation_key, t.text_translation, t.footnotes
        FROM translation_fts f
        JOIN translation_ayahs t
          ON t.translation_key = f.translation_key
         AND t.surah_number = f.surah_number
         AND t.ayah_number = f.ayah_number
        JOIN ayahs a
          ON a.surah_number = t.surah_number
         AND a.ayah_number = t.ayah_number
        JOIN surahs s ON s.number = t.surah_number
        WHERE translation_fts MATCH ?1
          AND t.translation_key = ?2
        ORDER BY bm25(translation_fts), t.surah_number, t.ayah_number
        LIMIT ?3
        ''',
        <Object?>[translationFtsQuery, translationKey, limit],
      );

      for (final Row row in translationRows) {
        final QuranSearchResult result = _searchResultFromRow(
          row,
          scope: QuranSearchScope.translation,
        );
        deduped.putIfAbsent(
          '${result.surahNumber}:${result.ayahNumber}',
          () => result,
        );
      }

      if (translationRows.isEmpty) {
        final ResultSet fallbackTranslationRows = db.select(
          '''
          SELECT t.surah_number, t.ayah_number, s.arabic_name, s.english_name,
                 a.text_arabic, t.translation_key, t.text_translation, t.footnotes
          FROM translation_ayahs t
          JOIN ayahs a
            ON a.surah_number = t.surah_number
           AND a.ayah_number = t.ayah_number
          JOIN surahs s ON s.number = t.surah_number
          WHERE t.translation_key = ?1
            AND (
              t.text_translation LIKE ?2 OR
              t.footnotes LIKE ?2
            )
          ORDER BY t.surah_number, t.ayah_number
          LIMIT ?3
          ''',
          <Object?>[translationKey, '%$trimmed%', limit],
        );

        for (final Row row in fallbackTranslationRows) {
          final QuranSearchResult result = _searchResultFromRow(
            row,
            scope: QuranSearchScope.translation,
          );
          deduped.putIfAbsent(
            '${result.surahNumber}:${result.ayahNumber}',
            () => result,
          );
        }
      }
    }

    final List<QuranSearchResult> results = deduped.values.toList();
    results.sort((QuranSearchResult a, QuranSearchResult b) {
      final int surahComparison = a.surahNumber.compareTo(b.surahNumber);
      if (surahComparison != 0) {
        return surahComparison;
      }
      return a.ayahNumber.compareTo(b.ayahNumber);
    });
    return results.take(limit).toList();
  }

  Future<String?> suggestQuery(
    String query, {
    String? translationKey,
  }) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final List<String> tokens = _tokenizeSearchTerms(trimmed);
    if (tokens.isEmpty) {
      return null;
    }

    final Map<String, int> terms = await _loadSuggestionTerms(
      translationKey: translationKey,
    );
    if (terms.isEmpty) {
      return null;
    }

    bool changed = false;
    final List<String> suggestedTokens = <String>[];
    for (final String token in tokens) {
      if (terms.containsKey(token)) {
        suggestedTokens.add(token);
        continue;
      }

      final String? replacement = _bestReplacementForToken(
        token,
        terms,
      );
      if (replacement != null && replacement != token) {
        suggestedTokens.add(replacement);
        changed = true;
      } else {
        suggestedTokens.add(token);
      }
    }

    if (!changed) {
      return null;
    }

    final String suggestion = suggestedTokens.join(' ');
    if (suggestion.trim().isEmpty || suggestion == trimmed.toLowerCase()) {
      return null;
    }
    return suggestion;
  }

  Future<List<QuranTranslationInfo>> getLocalTranslations({
    String? languageCode,
  }) async {
    final Database db = await _db;
    final ResultSet rows = db.select(
      '''
      SELECT c.translation_key, c.language_code, c.version, c.title,
             c.description, c.direction, c.attribution, c.last_remote_update,
             c.database_url, c.database_uncompressed_url, c.last_synced_at,
             EXISTS(
               SELECT 1
               FROM translation_ayahs t
               WHERE t.translation_key = c.translation_key
               LIMIT 1
             ) AS is_downloaded,
             (
               SELECT COUNT(*)
               FROM translation_ayahs t
               WHERE t.translation_key = c.translation_key
             ) AS cached_ayah_count,
             (
               SELECT COUNT(*)
               FROM ayahs
             ) AS total_ayah_count
      FROM translation_catalog c
      WHERE (?1 IS NULL OR c.language_code = ?1)
      ORDER BY c.title
      ''',
      <Object?>[languageCode],
    );

    return rows.map(_translationInfoFromRow).toList();
  }

  Future<List<QuranTranslationInfo>> refreshTranslationCatalog({
    required String languageCode,
    String localization = 'en',
  }) async {
    await initialize();
    final List<QuranTranslationInfo> remoteTranslations =
        await _remoteDataSource.listTranslations(
      languageCode: languageCode,
      localization: localization,
    );

    final Database db = await _db;
    _runInTransaction(db, () {
      final PreparedStatement statement = db.prepare(
        '''
        INSERT INTO translation_catalog (
          translation_key,
          language_code,
          version,
          title,
          description,
          direction,
          attribution,
          last_remote_update,
          database_url,
          database_uncompressed_url,
          last_synced_at
        )
        VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10,
          COALESCE(
            (SELECT last_synced_at FROM translation_catalog WHERE translation_key = ?1),
            NULL
          )
        )
        ON CONFLICT(translation_key) DO UPDATE SET
          language_code = excluded.language_code,
          version = excluded.version,
          title = excluded.title,
          description = excluded.description,
          direction = excluded.direction,
          attribution = excluded.attribution,
          last_remote_update = excluded.last_remote_update,
          database_url = excluded.database_url,
          database_uncompressed_url = excluded.database_uncompressed_url
        ''',
      );

      try {
        for (final QuranTranslationInfo translation in remoteTranslations) {
          statement.execute(<Object?>[
            translation.key,
            translation.languageCode,
            translation.version,
            translation.title,
            translation.description,
            translation.direction,
            translation.attribution,
            translation.lastRemoteUpdate.toIso8601String(),
            translation.databaseUrl,
            translation.databaseUncompressedUrl,
          ]);
        }
      } finally {
        statement.dispose();
      }
    });

    return getLocalTranslations(languageCode: languageCode);
  }

  Future<int> syncTranslationSurahs({
    required String translationKey,
    required List<int> surahNumbers,
  }) async {
    await initialize();
    if (surahNumbers.isEmpty) {
      return 0;
    }

    final QuranTranslationInfo translation = await _requireTranslationInfo(
      translationKey,
    );
    final Database db = await _db;
    int insertedVerses = 0;
    _termFrequencyCache.remove(_translationCacheKey(translationKey));

    final SourceVersion? existingVersion = await getTranslationSourceVersion(
      translationKey,
      languageCode: translation.languageCode,
    );
    final bool versionChanged =
        existingVersion != null && existingVersion.version != translation.version;

    _runInTransaction(db, () {
      if (versionChanged) {
        db.execute(
          'DELETE FROM translation_ayahs WHERE translation_key = ?',
          <Object?>[translationKey],
        );
        db.execute(
          'DELETE FROM translation_fts WHERE translation_key = ?',
          <Object?>[translationKey],
        );
      }
    });

    for (final int surahNumber in surahNumbers) {
      final List<QuranTranslationVerse> verses =
          await _remoteDataSource.fetchSurah(
        translationKey: translationKey,
        surahNumber: surahNumber,
      );

      _runInTransaction(db, () {
        db.execute(
          'DELETE FROM translation_ayahs WHERE translation_key = ? AND surah_number = ?',
          <Object?>[translationKey, surahNumber],
        );
        db.execute(
          'DELETE FROM translation_fts WHERE translation_key = ? AND surah_number = ?',
          <Object?>[translationKey, surahNumber],
        );

        final PreparedStatement ayahStatement = db.prepare(
          '''
          INSERT INTO translation_ayahs (
            translation_key,
            surah_number,
            ayah_number,
            text_translation,
            footnotes
          ) VALUES (?1, ?2, ?3, ?4, ?5)
          ''',
        );
        final PreparedStatement ftsStatement = db.prepare(
          '''
          INSERT INTO translation_fts (
            translation_key,
            surah_number,
            ayah_number,
            text_translation,
            footnotes
          ) VALUES (?1, ?2, ?3, ?4, ?5)
          ''',
        );

        try {
          for (final QuranTranslationVerse verse in verses) {
            ayahStatement.execute(<Object?>[
              translationKey,
              verse.surahNumber,
              verse.ayahNumber,
              verse.translationText,
              verse.footnotes,
            ]);
            ftsStatement.execute(<Object?>[
              translationKey,
              verse.surahNumber,
              verse.ayahNumber,
              verse.translationText,
              verse.footnotes,
            ]);
          }
        } finally {
          ayahStatement.dispose();
          ftsStatement.dispose();
        }

        final String syncedAt = DateTime.now().toIso8601String();
        db.execute(
          '''
          UPDATE translation_catalog
          SET last_synced_at = ?2
          WHERE translation_key = ?1
          ''',
          <Object?>[translationKey, syncedAt],
        );
        _upsertSourceVersion(
          db,
          SourceVersion(
            providerKey: 'quranenc',
            contentKey: translationKey,
            languageCode: translation.languageCode,
            version: translation.version,
            attribution: translation.attribution,
            lastSyncedAt: DateTime.parse(syncedAt),
          ),
        );
      });

      insertedVerses += verses.length;
    }

    return insertedVerses;
  }

  Future<QuranSyncOutcome> syncEntireTranslation({
    required String translationKey,
    void Function(int completedSurahs, int totalSurahs)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final List<int> surahNumbers = (await getSurahs())
        .map((SurahSummary surah) => surah.number)
        .toList(growable: false);
    int insertedVerses = 0;
    int completedSurahs = 0;
    for (int index = 0; index < surahNumbers.length; index += 1) {
      if (shouldCancel?.call() ?? false) {
        break;
      }
      insertedVerses += await syncTranslationSurahs(
        translationKey: translationKey,
        surahNumbers: <int>[surahNumbers[index]],
      );
      completedSurahs = index + 1;
      onProgress?.call(completedSurahs, surahNumbers.length);
      await Future<void>.delayed(Duration.zero);
    }
    return QuranSyncOutcome(
      insertedVerses: insertedVerses,
      completedSurahs: completedSurahs,
      totalSurahs: surahNumbers.length,
    );
  }

  Future<SourceVersion?> getArabicSourceVersion() {
    return _getSourceVersion(
      providerKey: 'tanzil',
      contentKey: 'quran_arabic_uthmani',
      languageCode: 'ar',
    );
  }

  Future<SourceVersion?> getTranslationSourceVersion(
    String translationKey, {
    required String languageCode,
  }) {
    return _getSourceVersion(
      providerKey: 'quranenc',
      contentKey: translationKey,
      languageCode: languageCode,
    );
  }

  Future<List<SourceVersion>> getSourceVersions() async {
    final Database db = await _db;
    final ResultSet rows = db.select(
      '''
      SELECT provider_key, content_key, language_code, version,
             attribution, last_synced_at
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
    }).toList();
  }

  Future<void> dispose() async {
    _database?.dispose();
    _database = null;
  }

  Future<Database> get _db async {
    await initialize();
    return _database!;
  }

  Future<void> _seedBundledCorpusIfNeeded() async {
    final Database db = await _db;
    final ResultSet corpusCount = db.select(
      'SELECT COUNT(*) AS count FROM ayahs',
    );
    final int count = corpusCount.first['count'] as int;
    final SourceVersion? currentArabicVersion = await getArabicSourceVersion();
    final bool needsSeed = count == 0 ||
        currentArabicVersion?.version != _seedDataSource.arabicVersion;

    if (!needsSeed) {
      return;
    }

    final String corpus = await _seedDataSource.loadArabicCorpus();
    final List<dynamic> rawMetadata =
        jsonDecode(await _seedDataSource.loadMetadata()) as List<dynamic>;

    _runInTransaction(db, () {
      db.execute('DELETE FROM surahs');
      db.execute('DELETE FROM ayahs');
      db.execute('DELETE FROM ayah_fts');

      final PreparedStatement surahStatement = db.prepare(
        '''
        INSERT INTO surahs (
          number,
          arabic_name,
          transliteration,
          english_name,
          ayah_count,
          revelation_type,
          revelation_order,
          rukus
        ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
        ''',
      );
      final PreparedStatement ayahStatement = db.prepare(
        '''
        INSERT INTO ayahs (
          surah_number,
          ayah_number,
          text_arabic
        ) VALUES (?1, ?2, ?3)
        ''',
      );
      final PreparedStatement ayahFtsStatement = db.prepare(
        '''
        INSERT INTO ayah_fts (
          surah_number,
          ayah_number,
          text_arabic
        ) VALUES (?1, ?2, ?3)
        ''',
      );

      try {
        for (final Map<String, dynamic> surah
            in rawMetadata.cast<Map<String, dynamic>>()) {
          surahStatement.execute(<Object?>[
            surah['number'],
            surah['arabic_name'],
            surah['transliteration'],
            surah['english_name'],
            surah['ayah_count'],
            surah['revelation_type'],
            surah['revelation_order'],
            surah['rukus'],
          ]);
        }

        for (final String line in LineSplitter.split(corpus)) {
          final String trimmed = line.trim();
          if (trimmed.isEmpty) {
            continue;
          }

          final List<String> parts = trimmed.split('|');
          if (parts.length != 3) {
            continue;
          }

          final int surahNumber = int.parse(parts[0]);
          final int ayahNumber = int.parse(parts[1]);
          final String arabicText = parts[2];
          final String normalizedArabicText =
              _normalizeArabicForSearch(arabicText);

          ayahStatement.execute(<Object?>[
            surahNumber,
            ayahNumber,
            arabicText,
          ]);
          ayahFtsStatement.execute(<Object?>[
            surahNumber,
            ayahNumber,
            normalizedArabicText,
          ]);
        }
      } finally {
        surahStatement.dispose();
        ayahStatement.dispose();
        ayahFtsStatement.dispose();
      }

      _upsertSourceVersion(
        db,
        SourceVersion(
          providerKey: 'tanzil',
          contentKey: 'quran_arabic_uthmani',
          languageCode: 'ar',
          version: _seedDataSource.arabicVersion,
          attribution: _seedDataSource.arabicAttribution,
        ),
      );
    });
    _termFrequencyCache.remove(_arabicCacheKey);
  }

  Future<SourceVersion?> _getSourceVersion({
    required String providerKey,
    required String contentKey,
    required String languageCode,
  }) async {
    final Database db = await _db;
    final ResultSet rows = db.select(
      '''
      SELECT provider_key, content_key, language_code, version,
             attribution, last_synced_at
      FROM source_versions
      WHERE provider_key = ?1
        AND content_key = ?2
        AND language_code = ?3
      LIMIT 1
      ''',
      <Object?>[providerKey, contentKey, languageCode],
    );
    if (rows.isEmpty) {
      return null;
    }

    final Row row = rows.first;
    return SourceVersion(
      providerKey: row['provider_key'] as String,
      contentKey: row['content_key'] as String,
      languageCode: row['language_code'] as String,
      version: row['version'] as String,
      attribution: row['attribution'] as String,
      lastSyncedAt: _readDateTime(row['last_synced_at']),
    );
  }

  Future<QuranTranslationInfo> _requireTranslationInfo(String translationKey) async {
    final Database db = await _db;
    final ResultSet rows = db.select(
      '''
      SELECT translation_key, language_code, version, title, description,
             direction, attribution, last_remote_update, database_url,
             database_uncompressed_url, last_synced_at,
             EXISTS(
               SELECT 1 FROM translation_ayahs t
               WHERE t.translation_key = translation_catalog.translation_key
               LIMIT 1
             ) AS is_downloaded,
             (
               SELECT COUNT(*)
               FROM translation_ayahs t
               WHERE t.translation_key = translation_catalog.translation_key
             ) AS cached_ayah_count,
             (
               SELECT COUNT(*)
               FROM ayahs
             ) AS total_ayah_count
      FROM translation_catalog
      WHERE translation_key = ?1
      LIMIT 1
      ''',
      <Object?>[translationKey],
    );
    if (rows.isEmpty) {
      throw StateError(
        'Translation $translationKey is not in the local catalog. Refresh the catalog first.',
      );
    }
    return _translationInfoFromRow(rows.first);
  }

  QuranSearchResult _searchResultFromRow(
    Row row, {
    required QuranSearchScope scope,
  }) {
    return QuranSearchResult(
      surahNumber: row['surah_number'] as int,
      ayahNumber: row['ayah_number'] as int,
      surahArabicName: row['arabic_name'] as String,
      surahEnglishName: row['english_name'] as String,
      arabicText: row['text_arabic'] as String,
      translationKey: row['translation_key'] as String?,
      translationText: row['text_translation'] as String?,
      footnotes: row['footnotes'] as String?,
      matchScope: scope,
    );
  }

  SurahSummary _surahFromRow(Row row) {
    return SurahSummary(
      number: row['number'] as int,
      arabicName: row['arabic_name'] as String,
      transliteration: row['transliteration'] as String,
      englishName: row['english_name'] as String,
      ayahCount: row['ayah_count'] as int,
      revelationType: row['revelation_type'] as String,
      revelationOrder: row['revelation_order'] as int,
      rukus: row['rukus'] as int,
    );
  }

  QuranTranslationInfo _translationInfoFromRow(Row row) {
    return QuranTranslationInfo(
      key: row['translation_key'] as String,
      languageCode: row['language_code'] as String,
      version: row['version'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      direction: row['direction'] as String,
      attribution: row['attribution'] as String,
      lastRemoteUpdate:
          DateTime.parse(row['last_remote_update'] as String).toLocal(),
      databaseUrl: row['database_url'] as String?,
      databaseUncompressedUrl:
          row['database_uncompressed_url'] as String?,
      isDownloaded: (row['is_downloaded'] as int) == 1,
      cachedAyahCount: (row['cached_ayah_count'] as int?) ?? 0,
      totalAyahCount: (row['total_ayah_count'] as int?) ?? 0,
      lastSyncedAt: _readDateTime(row['last_synced_at']),
    );
  }

  void _createSchema(Database db) {
    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS surahs (
        number INTEGER PRIMARY KEY,
        arabic_name TEXT NOT NULL,
        transliteration TEXT NOT NULL,
        english_name TEXT NOT NULL,
        ayah_count INTEGER NOT NULL,
        revelation_type TEXT NOT NULL,
        revelation_order INTEGER NOT NULL,
        rukus INTEGER NOT NULL
      )
      ''',
    );
    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS ayahs (
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        text_arabic TEXT NOT NULL,
        PRIMARY KEY (surah_number, ayah_number)
      )
      ''',
    );
    db.execute(
      '''
      CREATE VIRTUAL TABLE IF NOT EXISTS ayah_fts USING fts5(
        surah_number UNINDEXED,
        ayah_number UNINDEXED,
        text_arabic
      )
      ''',
    );
    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS translation_catalog (
        translation_key TEXT PRIMARY KEY,
        language_code TEXT NOT NULL,
        version TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        direction TEXT NOT NULL,
        attribution TEXT NOT NULL,
        last_remote_update TEXT NOT NULL,
        database_url TEXT,
        database_uncompressed_url TEXT,
        last_synced_at TEXT
      )
      ''',
    );
    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS translation_ayahs (
        translation_key TEXT NOT NULL,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        text_translation TEXT NOT NULL,
        footnotes TEXT NOT NULL,
        PRIMARY KEY (translation_key, surah_number, ayah_number)
      )
      ''',
    );
    db.execute(
      '''
      CREATE VIRTUAL TABLE IF NOT EXISTS translation_fts USING fts5(
        translation_key UNINDEXED,
        surah_number UNINDEXED,
        ayah_number UNINDEXED,
        text_translation,
        footnotes
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

  void _upsertSourceVersion(Database db, SourceVersion version) {
    db.execute(
      '''
      INSERT INTO source_versions (
        provider_key,
        content_key,
        language_code,
        version,
        attribution,
        last_synced_at
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

  String _buildFtsQuery(String rawQuery) {
    final List<String> tokens = rawQuery
        .split(RegExp(r'\s+'))
        .map((String token) => token.replaceAll('"', '').trim())
        .where((String token) => token.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return rawQuery;
    }

    return tokens
        .map((String token) => '${token.replaceAll("'", "''")}*')
        .join(' AND ');
  }

  String _normalizeArabicForSearch(String value) {
    return value
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll('\u0640', '')
        .replaceAll(RegExp('[\u0622\u0623\u0625\u0671]'), '\u0627')
        .replaceAll('\u0649', '\u064A')
        .replaceAll('\u0629', '\u0647')
        .replaceAll(RegExp(r'[^\u0621-\u063A\u0641-\u064A0-9A-Za-z\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime? _readDateTime(Object? value) {
    final String? raw = value as String?;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.parse(raw).toLocal();
  }

  Future<Map<String, int>> _loadSuggestionTerms({
    String? translationKey,
  }) async {
    final String cacheKey = translationKey == null || translationKey.isEmpty
        ? _arabicCacheKey
        : _translationCacheKey(translationKey);
    final Map<String, int>? cached = _termFrequencyCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final Database db = await _db;
    final ResultSet rows = translationKey == null || translationKey.isEmpty
        ? db.select('SELECT text_arabic AS text FROM ayahs')
        : db.select(
            '''
            SELECT text_translation AS text
            FROM translation_ayahs
            WHERE translation_key = ?1
            ''',
            <Object?>[translationKey],
          );

    final Map<String, int> terms = <String, int>{};
    for (final Row row in rows) {
      final String text = row['text'] as String? ?? '';
      for (final String token in _tokenizeSearchTerms(text)) {
        terms.update(token, (int count) => count + 1, ifAbsent: () => 1);
      }
    }

    _termFrequencyCache[cacheKey] = terms;
    return terms;
  }

  String? _bestReplacementForToken(
    String token,
    Map<String, int> terms,
  ) {
    if (token.length < 3) {
      return null;
    }

    String? bestTerm;
    double bestScore = double.negativeInfinity;
    for (final MapEntry<String, int> entry in terms.entries) {
      final String candidate = entry.key;
      if ((candidate.length - token.length).abs() > 2) {
        continue;
      }
      if (candidate.runes.first != token.runes.first &&
          !_isArabicToken(token)) {
        continue;
      }

      final int distance = _levenshteinDistance(token, candidate);
      if (distance > 2) {
        continue;
      }

      final double score = (8 - distance).toDouble() +
          (candidate.startsWith(token.substring(0, 1)) ? 1.5 : 0) +
          (entry.value / 50.0);
      if (score > bestScore) {
        bestScore = score;
        bestTerm = candidate;
      }
    }

    return bestTerm;
  }

  List<String> _tokenizeSearchTerms(String value) {
    final String normalized = _isArabicToken(value)
        ? _normalizeArabicForSearch(value)
        : _normalizeLatinForSearch(value);
    return normalized
        .split(RegExp(r'\s+'))
        .map((String token) => token.trim())
        .where((String token) => token.length >= 2)
        .toList(growable: false);
  }

  bool _isArabicToken(String value) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(value);

  String _normalizeLatinForSearch(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _levenshteinDistance(String source, String target) {
    if (source == target) {
      return 0;
    }
    if (source.isEmpty) {
      return target.length;
    }
    if (target.isEmpty) {
      return source.length;
    }

    final List<int> costs = List<int>.generate(
      target.length + 1,
      (int index) => index,
    );

    for (int i = 1; i <= source.length; i += 1) {
      int previous = i - 1;
      costs[0] = i;
      for (int j = 1; j <= target.length; j += 1) {
        final int current = costs[j];
        final int substitution = source.codeUnitAt(i - 1) ==
                target.codeUnitAt(j - 1)
            ? previous
            : previous + 1;
        costs[j] = <int>[
          costs[j] + 1,
          costs[j - 1] + 1,
          substitution,
        ].reduce((int a, int b) => a < b ? a : b);
        previous = current;
      }
    }

    return costs.last;
  }

  String get _arabicCacheKey => 'arabic';

  String _translationCacheKey(String translationKey) =>
      'translation:$translationKey';

  Future<String> _resolveDatabasePath() async {
    if (_databasePathResolver != null) {
      return _databasePathResolver();
    }

    final Directory directory = await getApplicationSupportDirectory();
    return path.join(directory.path, 'quran_v1.sqlite');
  }
}
