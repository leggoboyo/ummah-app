import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/quran_translation_info.dart';

class QuranTranslationVerse {
  const QuranTranslationVerse({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabicText,
    required this.translationText,
    required this.footnotes,
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabicText;
  final String translationText;
  final String footnotes;
}

abstract interface class QuranTranslationRemoteDataSource {
  Future<List<QuranTranslationInfo>> listTranslations({
    required String languageCode,
    String localization = 'en',
  });

  Future<List<QuranTranslationVerse>> fetchSurah({
    required String translationKey,
    required int surahNumber,
  });
}

class QuranEncRemoteDataSource implements QuranTranslationRemoteDataSource {
  QuranEncRemoteDataSource({
    http.Client? client,
  }) : _client = client ?? http.Client();

  static final Uri _baseUri = Uri.parse('https://quranenc.com/api/v1/');

  final http.Client _client;

  @override
  Future<List<QuranTranslationInfo>> listTranslations({
    required String languageCode,
    String localization = 'en',
  }) async {
    final Uri uri = _baseUri.resolve(
      'translations/list/$languageCode?localization=$localization',
    );
    final http.Response response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'QuranEnc translation catalog failed with ${response.statusCode}.',
      );
    }

    final Map<String, dynamic> payload =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> rawTranslations =
        payload['translations'] as List<dynamic>? ?? <dynamic>[];
    return rawTranslations
        .cast<Map<String, dynamic>>()
        .map(_translationFromJson)
        .toList();
  }

  @override
  Future<List<QuranTranslationVerse>> fetchSurah({
    required String translationKey,
    required int surahNumber,
  }) async {
    final Uri uri = _baseUri.resolve(
      'translation/sura/$translationKey/$surahNumber',
    );
    final http.Response response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'QuranEnc surah sync failed with ${response.statusCode}.',
      );
    }

    final Map<String, dynamic> payload =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> rawResult =
        payload['result'] as List<dynamic>? ?? <dynamic>[];

    return rawResult
        .cast<Map<String, dynamic>>()
        .map((Map<String, dynamic> row) {
      return QuranTranslationVerse(
        surahNumber: int.parse(row['sura'] as String),
        ayahNumber: int.parse(row['aya'] as String),
        arabicText: row['arabic_text'] as String? ?? '',
        translationText: row['translation'] as String? ?? '',
        footnotes: row['footnotes'] as String? ?? '',
      );
    }).toList();
  }

  QuranTranslationInfo _translationFromJson(Map<String, dynamic> row) {
    final String title = row['title'] as String? ?? row['key'] as String? ?? '';
    final String description = row['description'] as String? ?? '';
    return QuranTranslationInfo(
      key: row['key'] as String? ?? '',
      languageCode: row['language_iso_code'] as String? ?? '',
      version: row['version'] as String? ?? 'unknown',
      title: title,
      description: description,
      direction: row['direction'] as String? ?? 'ltr',
      attribution: 'QuranEnc - $title',
      lastRemoteUpdate: DateTime.fromMillisecondsSinceEpoch(
        ((row['last_update'] as num?)?.toInt() ?? 0) * 1000,
        isUtc: true,
      ).toLocal(),
      databaseUrl: row['database_url'] as String?,
      databaseUncompressedUrl: row['database_uncompressed_url'] as String?,
    );
  }
}
