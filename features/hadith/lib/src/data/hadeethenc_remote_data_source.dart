import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/hadith_category.dart';
import '../domain/hadith_detail.dart';
import '../domain/hadith_language.dart';

class HadithListPage {
  const HadithListPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.totalItems,
    required this.perPage,
  });

  final List<HadithListItem> items;
  final int currentPage;
  final int lastPage;
  final int totalItems;
  final int perPage;
}

class HadithListItem {
  const HadithListItem({
    required this.id,
    required this.title,
    required this.availableTranslations,
  });

  final int id;
  final String title;
  final List<String> availableTranslations;
}

abstract interface class HadeethEncRemoteDataSource {
  Future<List<HadithLanguage>> listLanguages();

  Future<List<HadithCategory>> listRootCategories({
    required String languageCode,
  });

  Future<HadithListPage> listHadiths({
    required String languageCode,
    required int categoryId,
    required int page,
    int perPage = 50,
  });

  Future<HadithDetail> fetchHadith({
    required String languageCode,
    required int hadithId,
  });
}

class HadeethEncApiDataSource implements HadeethEncRemoteDataSource {
  HadeethEncApiDataSource({
    http.Client? client,
  }) : _client = client ?? http.Client();

  static final Uri _baseUri = Uri.parse('https://hadeethenc.com/api/v1/');

  final http.Client _client;

  @override
  Future<List<HadithLanguage>> listLanguages() async {
    final List<dynamic> payload = await _getJsonList('languages');
    return payload.cast<Map<String, dynamic>>().map((Map<String, dynamic> row) {
      return HadithLanguage(
        code: row['code'] as String? ?? '',
        nativeName: row['native'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<List<HadithCategory>> listRootCategories({
    required String languageCode,
  }) async {
    final List<dynamic> payload = await _getJsonList(
      'categories/roots/?language=$languageCode',
    );
    return payload.cast<Map<String, dynamic>>().map((Map<String, dynamic> row) {
      return HadithCategory(
        id: int.parse(row['id'] as String),
        languageCode: languageCode,
        title: row['title'] as String? ?? '',
        hadithCount: int.parse(row['hadeeths_count'] as String? ?? '0'),
        parentId: row['parent_id'] == null
            ? null
            : int.parse(row['parent_id'] as String),
      );
    }).toList();
  }

  @override
  Future<HadithListPage> listHadiths({
    required String languageCode,
    required int categoryId,
    required int page,
    int perPage = 50,
  }) async {
    final Map<String, dynamic> payload = await _getJsonMap(
      'hadeeths/list/?language=$languageCode&category_id=$categoryId&page=$page&per_page=$perPage',
    );
    final Map<String, dynamic> meta =
        payload['meta'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final List<dynamic> rawItems =
        payload['data'] as List<dynamic>? ?? <dynamic>[];

    return HadithListPage(
      items:
          rawItems.cast<Map<String, dynamic>>().map((Map<String, dynamic> row) {
        return HadithListItem(
          id: int.parse(row['id'] as String),
          title: row['title'] as String? ?? '',
          availableTranslations:
              (row['translations'] as List<dynamic>? ?? <dynamic>[])
                  .cast<String>(),
        );
      }).toList(),
      currentPage: int.parse(meta['current_page'] as String? ?? '1'),
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      totalItems: (meta['total_items'] as num?)?.toInt() ?? 0,
      perPage: int.parse(meta['per_page'] as String? ?? '$perPage'),
    );
  }

  @override
  Future<HadithDetail> fetchHadith({
    required String languageCode,
    required int hadithId,
  }) async {
    final Map<String, dynamic> payload = await _getJsonMap(
      'hadeeths/one/?language=$languageCode&id=$hadithId',
    );
    return HadithDetail(
      id: int.parse(payload['id'] as String),
      languageCode: languageCode,
      title: payload['title'] as String? ?? '',
      hadithText: payload['hadeeth'] as String? ?? '',
      attribution: payload['attribution'] as String? ?? '',
      grade: payload['grade'] as String? ?? '',
      explanation: payload['explanation'] as String? ?? '',
      hints: _stringList(payload['hints']),
      categoryIds: _intList(payload['categories']),
      translations: _stringList(payload['translations']),
      hadithIntro: payload['hadeeth_intro'] as String? ?? '',
      hadithArabic: payload['hadeeth_ar'] as String? ?? '',
      hadithIntroArabic: payload['hadeeth_intro_ar'] as String? ?? '',
      explanationArabic: payload['explanation_ar'] as String? ?? '',
      hintsArabic: _stringList(payload['hints_ar']),
      wordsMeaningsArabic: _stringList(payload['words_meanings_ar']),
      attributionArabic: payload['attribution_ar'] as String? ?? '',
      gradeArabic: payload['grade_ar'] as String? ?? '',
    );
  }

  Future<List<dynamic>> _getJsonList(String path) async {
    final http.Response response = await _client.get(_baseUri.resolve(path));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'HadeethEnc request failed with ${response.statusCode} for $path',
      );
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> _getJsonMap(String path) async {
    final http.Response response = await _client.get(_baseUri.resolve(path));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'HadeethEnc request failed with ${response.statusCode} for $path',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<String> _stringList(Object? value) {
    return (value as List<dynamic>? ?? <dynamic>[])
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  List<int> _intList(Object? value) {
    return (value as List<dynamic>? ?? <dynamic>[])
        .map((dynamic item) => int.tryParse(item.toString()) ?? 0)
        .where((int item) => item > 0)
        .toList();
  }
}
