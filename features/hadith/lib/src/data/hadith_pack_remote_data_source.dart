import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/hadith_pack_access_grant.dart';
import '../domain/hadith_pack_manifest.dart';

abstract interface class HadithPackRemoteDataSource {
  bool get isConfigured;

  Future<List<HadithPackManifest>> fetchManifest();

  Future<HadithPackAccessGrant> requestAccess({
    required String packId,
    required String appUserId,
    required String platform,
    required String environment,
  });

  Future<Uint8List> downloadPack(Uri downloadUrl);
}

class UnconfiguredHadithPackRemoteDataSource
    implements HadithPackRemoteDataSource {
  const UnconfiguredHadithPackRemoteDataSource();

  @override
  bool get isConfigured => false;

  @override
  Future<Uint8List> downloadPack(Uri downloadUrl) {
    throw StateError('Remote Hadith pack delivery is not configured.');
  }

  @override
  Future<List<HadithPackManifest>> fetchManifest() {
    throw StateError('Remote Hadith pack delivery is not configured.');
  }

  @override
  Future<HadithPackAccessGrant> requestAccess({
    required String packId,
    required String appUserId,
    required String platform,
    required String environment,
  }) {
    throw StateError('Remote Hadith pack delivery is not configured.');
  }
}

class HadithPackApiDataSource implements HadithPackRemoteDataSource {
  HadithPackApiDataSource({
    required String baseUrl,
    required String environment,
    http.Client? client,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _environment = environment,
        _client = client ?? http.Client();

  final String _baseUrl;
  final String _environment;
  final http.Client _client;

  @override
  bool get isConfigured => _baseUrl.isNotEmpty;

  @override
  Future<Uint8List> downloadPack(Uri downloadUrl) async {
    _ensureConfigured();
    final http.Response response = await _client.get(downloadUrl);
    if (response.statusCode != 200) {
      throw StateError(
        'Hadith pack download failed (${response.statusCode}).',
      );
    }
    return response.bodyBytes;
  }

  @override
  Future<List<HadithPackManifest>> fetchManifest() async {
    _ensureConfigured();
    final Uri uri = Uri.parse(
      '$_baseUrl/v1/packs/manifest?environment=${Uri.encodeQueryComponent(_environment)}&module=hadith_pack',
    );
    final http.Response response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw StateError(
        'Hadith pack manifest failed to load (${response.statusCode}).',
      );
    }

    final Map<String, dynamic> payload =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> rawPacks =
        payload['packs'] as List<dynamic>? ?? const <dynamic>[];
    return rawPacks
        .whereType<Map<String, dynamic>>()
        .map(HadithPackManifest.fromJson)
        .toList(growable: false);
  }

  @override
  Future<HadithPackAccessGrant> requestAccess({
    required String packId,
    required String appUserId,
    required String platform,
    required String environment,
  }) async {
    _ensureConfigured();
    final Uri uri = Uri.parse('$_baseUrl/v1/packs/access');
    final http.Response response = await _client.post(
      uri,
      headers: const <String, String>{
        'content-type': 'application/json',
      },
      body: jsonEncode(<String, Object?>{
        'packId': packId,
        'appUserId': appUserId,
        'platform': platform,
        'environment': environment,
      }),
    );
    if (response.statusCode != 200) {
      final String message = response.body;
      if (response.statusCode == 403) {
        throw StateError(
          'Hadith pack access was denied (403). $message',
        );
      }
      if (response.statusCode == 503) {
        throw StateError(
          'Hadith pack delivery is temporarily unavailable (503). $message',
        );
      }
      throw StateError(
        'Hadith pack access failed (${response.statusCode}). $message',
      );
    }
    return HadithPackAccessGrant.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw StateError('Remote Hadith pack delivery is not configured.');
    }
  }
}
