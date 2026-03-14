import 'entitlement.dart';

enum ContentModule {
  corePrayer,
  quranTranslation,
  quranAudio,
  hadithPack,
  scholarCache,
  tafsirPack,
}

enum ContentAvailabilityStatus {
  available,
  comingSoon,
}

enum ContentInstallState {
  bundled,
  notInstalled,
  installing,
  installed,
  partial,
  updateAvailable,
}

enum StartupSetupPreset {
  lightest,
  recommendedStudy,
  custom,
}

class ContentPackManifest {
  const ContentPackManifest({
    required this.id,
    required this.module,
    required this.title,
    required this.description,
    required this.version,
    required this.estimatedSizeBytes,
    required this.isFree,
    required this.isBundled,
    required this.availabilityStatus,
    this.languageCode,
    this.providerKey,
    this.requiredEntitlement,
    this.integrityHash,
    this.isRecommended = false,
  });

  final String id;
  final ContentModule module;
  final String title;
  final String description;
  final String version;
  final int estimatedSizeBytes;
  final bool isFree;
  final bool isBundled;
  final ContentAvailabilityStatus availabilityStatus;
  final String? languageCode;
  final String? providerKey;
  final AppEntitlement? requiredEntitlement;
  final String? integrityHash;
  final bool isRecommended;
}

class InstalledContentPack {
  const InstalledContentPack({
    required this.packId,
    required this.module,
    required this.title,
    required this.version,
    required this.installState,
    required this.installedSizeBytes,
    this.languageCode,
    this.providerKey,
    this.installedAt,
    this.lastUsedAt,
  });

  final String packId;
  final ContentModule module;
  final String title;
  final String version;
  final ContentInstallState installState;
  final int installedSizeBytes;
  final String? languageCode;
  final String? providerKey;
  final DateTime? installedAt;
  final DateTime? lastUsedAt;
}

class ContentDownloadRequest {
  const ContentDownloadRequest({
    required this.packIds,
    required this.wifiOnly,
    required this.storageSaverMode,
  });

  final List<String> packIds;
  final bool wifiOnly;
  final bool storageSaverMode;
}

class ContentAvailability {
  const ContentAvailability({
    required this.manifest,
    required this.canInstallNow,
    required this.isInstalled,
    required this.isDeferredUntilPurchase,
    required this.installState,
    this.statusMessage,
  });

  final ContentPackManifest manifest;
  final bool canInstallNow;
  final bool isInstalled;
  final bool isDeferredUntilPurchase;
  final ContentInstallState installState;
  final String? statusMessage;
}

class StartupSelection {
  const StartupSelection({
    required this.preset,
    required this.selectedPackIds,
    required this.deferredPackIds,
    required this.wifiOnlyDownloads,
    required this.storageSaverMode,
  });

  final StartupSetupPreset preset;
  final List<String> selectedPackIds;
  final List<String> deferredPackIds;
  final bool wifiOnlyDownloads;
  final bool storageSaverMode;

  StartupSelection copyWith({
    StartupSetupPreset? preset,
    List<String>? selectedPackIds,
    List<String>? deferredPackIds,
    bool? wifiOnlyDownloads,
    bool? storageSaverMode,
  }) {
    return StartupSelection(
      preset: preset ?? this.preset,
      selectedPackIds: selectedPackIds ?? this.selectedPackIds,
      deferredPackIds: deferredPackIds ?? this.deferredPackIds,
      wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
      storageSaverMode: storageSaverMode ?? this.storageSaverMode,
    );
  }
}

class StorageEstimate {
  const StorageEstimate({
    required this.immediateDownloadBytes,
    required this.deferredDownloadBytes,
    required this.selectedPackCount,
    required this.deferredPackCount,
  });

  final int immediateDownloadBytes;
  final int deferredDownloadBytes;
  final int selectedPackCount;
  final int deferredPackCount;
}
