import 'package:core/core.dart';

class HadithPackManifest {
  const HadithPackManifest({
    required this.providerKey,
    required this.packId,
    required this.module,
    required this.languageCode,
    required this.languageName,
    required this.version,
    required this.sourceUrl,
    required this.downloadUrl,
    required this.objectKey,
    required this.fileHash,
    required this.recordCount,
    required this.packSizeBytes,
    required this.lastUpdatedAt,
    required this.isStarterFreeEligible,
    required this.manifestUrl,
    this.assetPath,
    this.isBundled = false,
    this.requiredEntitlementKey,
  });

  final String providerKey;
  final String packId;
  final ContentModule module;
  final String languageCode;
  final String languageName;
  final String version;
  final String sourceUrl;
  final String downloadUrl;
  final String objectKey;
  final String fileHash;
  final int recordCount;
  final int packSizeBytes;
  final DateTime lastUpdatedAt;
  final bool isStarterFreeEligible;
  final String manifestUrl;
  final String? assetPath;
  final bool isBundled;
  final String? requiredEntitlementKey;

  factory HadithPackManifest.fromJson(Map<String, dynamic> json) {
    return HadithPackManifest(
      providerKey: json['provider_key'] as String? ?? 'hadeethenc',
      packId: json['pack_id'] as String? ?? '',
      module: _parseModule(
        json['module'] as String? ?? ContentModule.hadithPack.name,
      ),
      languageCode: json['language_code'] as String? ?? '',
      languageName: json['language_name'] as String? ?? '',
      version: json['version'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
      objectKey: json['object_key'] as String? ?? '',
      fileHash: json['file_hash'] as String? ?? '',
      recordCount: (json['record_count'] as num?)?.toInt() ?? 0,
      packSizeBytes: (json['pack_size_bytes'] as num?)?.toInt() ?? 0,
      lastUpdatedAt: DateTime.tryParse(
            json['last_updated_at'] as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isStarterFreeEligible: json['is_starter_free_eligible'] as bool? ?? false,
      manifestUrl: json['manifest_url'] as String? ?? '',
      assetPath: json['asset_path'] as String?,
      isBundled: json['is_bundled'] as bool? ?? false,
      requiredEntitlementKey: json['required_entitlement_key'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'provider_key': providerKey,
      'pack_id': packId,
      'module': module.name,
      'language_code': languageCode,
      'language_name': languageName,
      'version': version,
      'source_url': sourceUrl,
      'download_url': downloadUrl,
      'object_key': objectKey,
      'file_hash': fileHash,
      'record_count': recordCount,
      'pack_size_bytes': packSizeBytes,
      'last_updated_at': lastUpdatedAt.toIso8601String(),
      'is_starter_free_eligible': isStarterFreeEligible,
      'manifest_url': manifestUrl,
      'asset_path': assetPath,
      'is_bundled': isBundled,
      'required_entitlement_key': requiredEntitlementKey,
    };
  }

  static ContentModule _parseModule(String raw) {
    for (final ContentModule module in ContentModule.values) {
      if (module.name == raw) {
        return module;
      }
    }
    return ContentModule.hadithPack;
  }
}
