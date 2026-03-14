import 'package:flutter/services.dart';

abstract interface class QuranSeedDataSource {
  String get arabicVersion;

  String get arabicAttribution;

  Future<String> loadArabicCorpus();

  Future<String> loadMetadata();
}

class QuranAssetSeedDataSource implements QuranSeedDataSource {
  const QuranAssetSeedDataSource({
    AssetBundle? assetBundle,
  }) : _assetBundle = assetBundle;

  static const String corpusAssetPath =
      'packages/quran/assets/quran_uthmani_v1.1.txt';
  static const String metadataAssetPath =
      'packages/quran/assets/quran_metadata_v1.0.json';

  final AssetBundle? _assetBundle;

  @override
  String get arabicAttribution => 'Tanzil Project (tanzil.net)';

  @override
  String get arabicVersion => '1.1';

  @override
  Future<String> loadArabicCorpus() {
    return (_assetBundle ?? rootBundle).loadString(corpusAssetPath);
  }

  @override
  Future<String> loadMetadata() {
    return (_assetBundle ?? rootBundle).loadString(metadataAssetPath);
  }
}
