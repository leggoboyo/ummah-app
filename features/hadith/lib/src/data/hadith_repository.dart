import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/hadith_category.dart';
import '../domain/hadith_detail.dart';
import '../domain/hadith_language.dart';
import '../domain/hadith_search_result.dart';
import 'hadeethenc_remote_data_source.dart';

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

class HadithRepository {
  HadithRepository({
    HadeethEncRemoteDataSource? remoteDataSource,
    Database? database,
    Future<String> Function()? databasePathResolver,
  })  : _remoteDataSource = remoteDataSource ?? HadeethEncApiDataSource(),
        _providedDatabase = database,
        _databasePathResolver = databasePathResolver;

  static const String _providerKey = 'hadeethenc';
  static const String _providerVersion = 'API/v1';
  static const String _providerAttribution = 'HadeethEnc.com';

  final HadeethEncRemoteDataSource _remoteDataSource;
  final Database? _providedDatabase;
  final Future<String> Function()? _databasePathResolver;

  Database? _database;

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
    }).toList();
  }

  Future<List<HadithLanguage>> refreshLanguages() async {
    final List<HadithLanguage> languages = await _remoteDataSource.listLanguages();
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
        statement.dispose();
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

    return rows.map(_categoryFromRow).toList();
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
        statement.dispose();
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
            DateTime.now().toIso8601String(),
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
            DateTime.now().toIso8601String(),
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
            lastSyncedAt: DateTime.now(),
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

  Future<List<HadithSearchResult>> search({
    required String query,
    required String languageCode,
    int limit = 30,
  }) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <HadithSearchResult>[];
    }

    final Database db = await _db;
    final String ftsQuery = _buildFtsQuery(trimmed);
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
      return rows.map(_searchResultFromRow).toList();
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

    return fallback.map(_searchResultFromRow).toList();
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

    return rows.map(_searchResultFromRow).toList();
  }

  Future<HadithDetail?> getHadithDetail({
    required String languageCode,
    required int hadithId,
  }) async {
    final Database db = await _db;
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
    return _detailFromRow(rows.first);
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

  HadithSearchResult _searchResultFromRow(Row row) {
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

  HadithDetail _detailFromRow(Row row) {
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
        .toList();
  }

  List<int> _decodeIntList(Object? raw) {
    if (raw == null) {
      return const <int>[];
    }
    return (jsonDecode(raw as String) as List<dynamic>)
        .map((dynamic item) => int.tryParse(item.toString()) ?? 0)
        .where((int item) => item > 0)
        .toList();
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

  DateTime? _readDateTime(Object? value) {
    final String? raw = value as String?;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.parse(raw).toLocal();
  }

  Future<String> _resolveDatabasePath() async {
    if (_databasePathResolver != null) {
      return _databasePathResolver();
    }

    final Directory directory = await getApplicationSupportDirectory();
    return path.join(directory.path, 'hadith_v1.sqlite');
  }
}
