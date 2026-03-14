import 'package:core/core.dart';
import 'package:hadith/hadith.dart';
import 'package:quran/quran.dart';

class AppContentPackIds {
  static const String corePrayer = 'core_prayer';
  static const String quranArabic = 'quran_arabic';
  static const String quranTranslationDefault = 'quran_translation:default';
  static const String hadithPackDefault = 'hadith_pack:default';
  static const String quranAudioStarter = 'quran_audio:starter';

  static String quranTranslationLanguage(String languageCode) =>
      'quran_translation:$languageCode';

  static String hadithPackLanguage(String languageCode) =>
      'hadith_pack:$languageCode';
}

class ContentPackRegistry {
  ContentPackRegistry({
    QuranRepository? quranRepository,
    HadithRepository? hadithRepository,
  })  : _quranRepository = quranRepository ?? QuranRepository(),
        _hadithRepository = hadithRepository ?? HadithRepository();

  final QuranRepository _quranRepository;
  final HadithRepository _hadithRepository;

  static const int _bundledQuranArabicBytes = 520000;
  static const int _defaultQuranTranslationBytes = 6200000;
  static const int _defaultHadithStarterBytes = 3200000;
  static const int _audioStarterBytes = 52000000;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    await _quranRepository.initialize();
    await _hadithRepository.initialize();
    _isInitialized = true;
  }

  Future<List<ContentPackManifest>> getStartupPacks({
    required String preferredLanguageCode,
  }) async {
    final String normalizedLanguage =
        _normalizeLanguageCode(preferredLanguageCode);

    final List<ContentPackManifest> packs = <ContentPackManifest>[
      const ContentPackManifest(
        id: AppContentPackIds.corePrayer,
        module: ContentModule.corePrayer,
        title: 'Prayer core',
        description:
            'Prayer times, adhan reminders, qibla, location, fiqh profile, and Hijri date.',
        version: 'bundled',
        estimatedSizeBytes: 0,
        isFree: true,
        isBundled: true,
        availabilityStatus: ContentAvailabilityStatus.available,
        isRecommended: true,
      ),
      const ContentPackManifest(
        id: AppContentPackIds.quranArabic,
        module: ContentModule.quranTranslation,
        title: 'Quran Arabic text',
        description:
            'Bundled Arabic Quran text for offline reading from the first launch.',
        version: '1.1',
        estimatedSizeBytes: _bundledQuranArabicBytes,
        isFree: true,
        isBundled: true,
        availabilityStatus: ContentAvailabilityStatus.available,
        languageCode: 'ar',
        providerKey: 'tanzil',
        isRecommended: true,
      ),
      ContentPackManifest(
        id: AppContentPackIds.quranTranslationDefault,
        module: ContentModule.quranTranslation,
        title:
            'Quran translation (${_displayLanguageName(normalizedLanguage)})',
        description:
            'Recommended phone-language Quran translation for offline search and reading.',
        version: 'current',
        estimatedSizeBytes: _defaultQuranTranslationBytes,
        isFree: true,
        isBundled: false,
        availabilityStatus: ContentAvailabilityStatus.available,
        languageCode: normalizedLanguage,
        providerKey: 'quranenc',
        isRecommended: true,
      ),
      ContentPackManifest(
        id: AppContentPackIds.hadithPackDefault,
        module: ContentModule.hadithPack,
        title:
            'Sunni Hadith pack (${_displayLanguageName(normalizedLanguage)})',
        description:
            'Optional HadeethEnc starter pack for cited Sunni Hadith lookup in your recommended language.',
        version: 'remote-current',
        estimatedSizeBytes: _defaultHadithStarterBytes,
        isFree: true,
        isBundled: false,
        availabilityStatus: ContentAvailabilityStatus.available,
        languageCode: normalizedLanguage,
        providerKey: 'hadeethenc',
        isRecommended: true,
      ),
      const ContentPackManifest(
        id: AppContentPackIds.quranAudioStarter,
        module: ContentModule.quranAudio,
        title: 'Audio starter pack',
        description:
            'English and Arabic recitation or audiobook packs stay optional to keep older phones lighter.',
        version: 'coming-soon',
        estimatedSizeBytes: _audioStarterBytes,
        isFree: false,
        isBundled: false,
        availabilityStatus: ContentAvailabilityStatus.comingSoon,
        requiredEntitlement: AppEntitlement.quranPlus,
      ),
    ];
    return packs;
  }

  Future<List<InstalledContentPack>> getInstalledPacks({
    required String preferredLanguageCode,
  }) async {
    await initialize();
    final List<InstalledContentPack> packs = <InstalledContentPack>[
      const InstalledContentPack(
        packId: AppContentPackIds.corePrayer,
        module: ContentModule.corePrayer,
        title: 'Prayer core',
        version: 'bundled',
        installState: ContentInstallState.bundled,
        installedSizeBytes: 0,
      ),
      const InstalledContentPack(
        packId: AppContentPackIds.quranArabic,
        module: ContentModule.quranTranslation,
        title: 'Quran Arabic text',
        version: '1.1',
        installState: ContentInstallState.bundled,
        installedSizeBytes: _bundledQuranArabicBytes,
        languageCode: 'ar',
        providerKey: 'tanzil',
      ),
    ];

    final List<QuranTranslationInfo> translations =
        await _quranRepository.getLocalTranslations();
    for (final QuranTranslationInfo translation in translations) {
      if (!translation.isDownloaded) {
        continue;
      }
      packs.add(
        InstalledContentPack(
          packId: AppContentPackIds.quranTranslationLanguage(
            translation.languageCode,
          ),
          module: ContentModule.quranTranslation,
          title: translation.title,
          version: translation.version,
          installState: translation.isFullyDownloaded
              ? ContentInstallState.installed
              : ContentInstallState.partial,
          installedSizeBytes: _estimateQuranTranslationBytes(translation),
          languageCode: translation.languageCode,
          providerKey: 'quranenc',
          installedAt: translation.lastSyncedAt,
          lastUsedAt: translation.lastSyncedAt,
        ),
      );
    }

    final List<HadithPackInstall> hadithInstalls =
        await _hadithRepository.getInstalledPacks();
    for (final HadithPackInstall install in hadithInstalls) {
      packs.add(
        InstalledContentPack(
          packId: AppContentPackIds.hadithPackLanguage(install.languageCode),
          module: ContentModule.hadithPack,
          title: 'Sunni Hadith (${install.languageName})',
          version: install.version,
          installState: install.isComplete
              ? ContentInstallState.installed
              : ContentInstallState.partial,
          installedSizeBytes: install.packSizeBytes,
          languageCode: install.languageCode,
          providerKey: install.providerKey,
          installedAt: install.installedAt,
          lastUsedAt: install.installedAt,
        ),
      );
    }

    return packs;
  }

  Future<StorageEstimate> estimateSelection({
    required StartupSelection selection,
    required String preferredLanguageCode,
    required Set<AppEntitlement> entitlements,
  }) async {
    final List<ContentPackManifest> startupPacks = await getStartupPacks(
      preferredLanguageCode: preferredLanguageCode,
    );
    final Set<String> selectedPackIds = selection.selectedPackIds.toSet();
    final Set<String> deferredPackIds = selection.deferredPackIds.toSet();

    int immediateBytes = 0;
    int deferredBytes = 0;
    int immediateCount = 0;
    int deferredCount = 0;

    for (final ContentPackManifest manifest in startupPacks) {
      if ((!selectedPackIds.contains(manifest.id) &&
              !deferredPackIds.contains(manifest.id)) ||
          manifest.isBundled) {
        continue;
      }
      final bool unlocked = manifest.isFree ||
          manifest.requiredEntitlement == null ||
          hasEntitlement(entitlements, manifest.requiredEntitlement!);
      final bool readyNow = unlocked &&
          manifest.availabilityStatus == ContentAvailabilityStatus.available &&
          !deferredPackIds.contains(manifest.id);
      if (readyNow) {
        immediateBytes += manifest.estimatedSizeBytes;
        immediateCount += 1;
      } else {
        deferredBytes += manifest.estimatedSizeBytes;
        deferredCount += 1;
      }
    }

    return StorageEstimate(
      immediateDownloadBytes: immediateBytes,
      deferredDownloadBytes: deferredBytes,
      selectedPackCount: immediateCount,
      deferredPackCount: deferredCount,
    );
  }

  Future<List<ContentAvailability>> describeSelection({
    required StartupSelection selection,
    required String preferredLanguageCode,
    required Set<AppEntitlement> entitlements,
  }) async {
    final List<ContentPackManifest> startupPacks = await getStartupPacks(
      preferredLanguageCode: preferredLanguageCode,
    );
    final Set<String> selectedIds = selection.selectedPackIds.toSet();
    final Set<String> deferredIds = selection.deferredPackIds.toSet();
    final Map<String, InstalledContentPack> installed =
        <String, InstalledContentPack>{
      for (final InstalledContentPack pack in await getInstalledPacks(
          preferredLanguageCode: preferredLanguageCode))
        pack.packId: pack,
    };

    final List<ContentAvailability> availability = <ContentAvailability>[];
    for (final ContentPackManifest manifest in startupPacks) {
      final bool explicitlySelected = selectedIds.contains(manifest.id) ||
          deferredIds.contains(manifest.id) ||
          manifest.isBundled;
      if (!explicitlySelected) {
        continue;
      }
      final InstalledContentPack? installedPack = installed[manifest.id];
      final bool unlocked = manifest.isFree ||
          manifest.requiredEntitlement == null ||
          hasEntitlement(entitlements, manifest.requiredEntitlement!);
      final bool comingSoon =
          manifest.availabilityStatus == ContentAvailabilityStatus.comingSoon;
      availability.add(
        ContentAvailability(
          manifest: manifest,
          canInstallNow: unlocked && !comingSoon,
          isInstalled: installedPack != null,
          isDeferredUntilPurchase:
              !manifest.isBundled && (!unlocked || comingSoon),
          installState: installedPack?.installState ??
              (manifest.isBundled
                  ? ContentInstallState.bundled
                  : ContentInstallState.notInstalled),
          statusMessage: _statusMessageForManifest(
            manifest: manifest,
            unlocked: unlocked,
            comingSoon: comingSoon,
          ),
        ),
      );
    }
    return availability;
  }

  StartupSelection selectionForPreset(StartupSetupPreset preset) {
    switch (preset) {
      case StartupSetupPreset.lightest:
        return const StartupSelection(
          preset: StartupSetupPreset.lightest,
          selectedPackIds: <String>[
            AppContentPackIds.corePrayer,
            AppContentPackIds.quranArabic,
          ],
          deferredPackIds: <String>[],
          wifiOnlyDownloads: true,
          storageSaverMode: true,
        );
      case StartupSetupPreset.recommendedStudy:
        return const StartupSelection(
          preset: StartupSetupPreset.recommendedStudy,
          selectedPackIds: <String>[
            AppContentPackIds.corePrayer,
            AppContentPackIds.quranArabic,
            AppContentPackIds.quranTranslationDefault,
            AppContentPackIds.hadithPackDefault,
          ],
          deferredPackIds: <String>[],
          wifiOnlyDownloads: true,
          storageSaverMode: false,
        );
      case StartupSetupPreset.custom:
        return const StartupSelection(
          preset: StartupSetupPreset.custom,
          selectedPackIds: <String>[
            AppContentPackIds.corePrayer,
            AppContentPackIds.quranArabic,
          ],
          deferredPackIds: <String>[],
          wifiOnlyDownloads: true,
          storageSaverMode: false,
        );
    }
  }

  Future<void> dispose() async {
    await _quranRepository.dispose();
    await _hadithRepository.dispose();
    _isInitialized = false;
  }

  static String _normalizeLanguageCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ar':
      case 'ur':
        return languageCode.toLowerCase();
      default:
        return 'en';
    }
  }

  static String _displayLanguageName(String languageCode) {
    switch (_normalizeLanguageCode(languageCode)) {
      case 'ar':
        return 'Arabic';
      case 'ur':
        return 'Urdu';
      default:
        return 'English';
    }
  }

  static int _estimateQuranTranslationBytes(QuranTranslationInfo translation) {
    if (translation.totalAyahCount == 0) {
      return _defaultQuranTranslationBytes;
    }
    final double ratio = translation.cachedAyahCount /
        translation.totalAyahCount.clamp(1, 999999);
    return (_defaultQuranTranslationBytes * ratio).round();
  }

  static String? _statusMessageForManifest({
    required ContentPackManifest manifest,
    required bool unlocked,
    required bool comingSoon,
  }) {
    if (manifest.isBundled) {
      return 'Included in the base app.';
    }
    if (comingSoon) {
      return 'Planned for a future download release.';
    }
    if (!unlocked) {
      return 'Saved for later. Unlock ${manifest.requiredEntitlement?.title ?? 'a paid plan'} to download it.';
    }
    return 'Ready to download after setup.';
  }
}
