enum PackContentType {
  text,
  sqlite,
  json,
  archive,
  audioIndex,
}

enum PackDeliveryType {
  bundled,
  remoteOptional,
}

class PackSourceEntry {
  const PackSourceEntry({
    required this.name,
    required this.url,
    required this.version,
    required this.licenseSummary,
    required this.attributionRequired,
    required this.noModifyRequired,
    required this.verbatimOnly,
  });

  final String name;
  final String url;
  final String version;
  final String licenseSummary;
  final bool attributionRequired;
  final bool noModifyRequired;
  final bool verbatimOnly;

  factory PackSourceEntry.fromJson(Map<String, dynamic> json) {
    return PackSourceEntry(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      version: json['version'] as String? ?? '',
      licenseSummary: json['license_summary'] as String? ?? '',
      attributionRequired: json['attribution_required'] as bool? ?? false,
      noModifyRequired: json['no_modify_required'] as bool? ?? false,
      verbatimOnly: json['verbatim_only'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'url': url,
      'version': version,
      'license_summary': licenseSummary,
      'attribution_required': attributionRequired,
      'no_modify_required': noModifyRequired,
      'verbatim_only': verbatimOnly,
    };
  }
}

class PackCatalogEntry {
  const PackCatalogEntry({
    required this.packId,
    required this.moduleId,
    required this.title,
    required this.summary,
    required this.version,
    required this.locales,
    required this.sizeBytes,
    required this.sha256,
    required this.contentType,
    required this.deliveryType,
    required this.installSteps,
    required this.compatibility,
    required this.sources,
    this.artifactPath,
    this.remoteObjectKey,
    this.requiredEntitlementKey,
  });

  final String packId;
  final String moduleId;
  final String title;
  final String summary;
  final String version;
  final List<String> locales;
  final int sizeBytes;
  final String sha256;
  final PackContentType contentType;
  final PackDeliveryType deliveryType;
  final List<String> installSteps;
  final List<String> compatibility;
  final List<PackSourceEntry> sources;
  final String? artifactPath;
  final String? remoteObjectKey;
  final String? requiredEntitlementKey;

  factory PackCatalogEntry.fromJson(Map<String, dynamic> json) {
    return PackCatalogEntry(
      packId: json['pack_id'] as String? ?? '',
      moduleId: json['module_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      version: json['version'] as String? ?? '',
      locales: (json['locales'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      sha256: json['sha256'] as String? ?? '',
      contentType: _parseContentType(json['content_type'] as String? ?? ''),
      deliveryType: _parseDeliveryType(json['delivery_type'] as String? ?? ''),
      installSteps:
          (json['install_steps'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      compatibility:
          (json['compatibility'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      sources: (json['sources'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PackSourceEntry.fromJson)
          .toList(growable: false),
      artifactPath: json['artifact_path'] as String?,
      remoteObjectKey: json['remote_object_key'] as String?,
      requiredEntitlementKey: json['required_entitlement_key'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'pack_id': packId,
      'module_id': moduleId,
      'title': title,
      'summary': summary,
      'version': version,
      'locales': locales,
      'size_bytes': sizeBytes,
      'sha256': sha256,
      'content_type': contentType.name,
      'delivery_type': deliveryType.name,
      'install_steps': installSteps,
      'compatibility': compatibility,
      'sources':
          sources.map((PackSourceEntry entry) => entry.toJson()).toList(),
      'artifact_path': artifactPath,
      'remote_object_key': remoteObjectKey,
      'required_entitlement_key': requiredEntitlementKey,
    };
  }

  static PackContentType _parseContentType(String raw) {
    for (final PackContentType value in PackContentType.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return PackContentType.json;
  }

  static PackDeliveryType _parseDeliveryType(String raw) {
    for (final PackDeliveryType value in PackDeliveryType.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return PackDeliveryType.bundled;
  }
}

class PackCatalog {
  const PackCatalog({
    required this.generatedLabel,
    required this.packs,
  });

  final String generatedLabel;
  final List<PackCatalogEntry> packs;

  factory PackCatalog.fromJson(Map<String, dynamic> json) {
    return PackCatalog(
      generatedLabel: json['generated_label'] as String? ??
          'Bundled with this build from canonical pack manifests.',
      packs: (json['packs'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PackCatalogEntry.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'generated_label': generatedLabel,
      'packs': packs.map((PackCatalogEntry entry) => entry.toJson()).toList(),
    };
  }
}
