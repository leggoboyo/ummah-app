class HadithPackDownloadResult {
  const HadithPackDownloadResult({
    required this.packId,
    required this.filePath,
    required this.sizeBytes,
    required this.fileHash,
  });

  final String packId;
  final String filePath;
  final int sizeBytes;
  final String fileHash;
}
