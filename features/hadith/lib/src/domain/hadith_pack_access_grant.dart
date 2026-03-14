class HadithPackAccessGrant {
  const HadithPackAccessGrant({
    required this.packId,
    required this.downloadUrl,
    required this.expiresAt,
    required this.fileHash,
    required this.sizeBytes,
    required this.version,
    required this.isFree,
  });

  final String packId;
  final Uri downloadUrl;
  final DateTime expiresAt;
  final String fileHash;
  final int sizeBytes;
  final String version;
  final bool isFree;

  factory HadithPackAccessGrant.fromJson(Map<String, dynamic> json) {
    return HadithPackAccessGrant(
      packId: json['packId'] as String? ?? '',
      downloadUrl: Uri.parse(json['downloadUrl'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      fileHash: json['sha256'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      version: json['version'] as String? ?? '',
      isFree: json['isFree'] as bool? ?? false,
    );
  }
}
