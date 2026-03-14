class HadithPackInstall {
  const HadithPackInstall({
    required this.languageCode,
    required this.languageName,
    required this.version,
    required this.providerKey,
    required this.sourceType,
    required this.installedAt,
    required this.fileHash,
    required this.installedFileHash,
    required this.recordCount,
    required this.packSizeBytes,
    required this.isComplete,
    this.lastValidatedAt,
    this.archiveVersion,
    this.archivePath,
  });

  final String languageCode;
  final String languageName;
  final String version;
  final String providerKey;
  final String sourceType;
  final DateTime installedAt;
  final String fileHash;
  final String installedFileHash;
  final int recordCount;
  final int packSizeBytes;
  final bool isComplete;
  final DateTime? lastValidatedAt;
  final String? archiveVersion;
  final String? archivePath;
}
