import 'app_module.dart';
import 'content_pack_ids.dart';
import 'entitlement.dart';

AppModuleRegistry buildDefaultAppModuleRegistry() {
  return AppModuleRegistry(
    const <AppModuleDefinition>[
      AppModuleDefinition(
        id: AppModuleId.onboarding,
        title: 'Onboarding',
        summary:
            'Account-free setup for language, fiqh profile, location, and starter downloads.',
        kind: AppModuleKind.core,
        releaseState: ModuleReleaseState.available,
        networkRequirement: ModuleNetworkRequirement.offlineOnly,
      ),
      AppModuleDefinition(
        id: AppModuleId.prayerCore,
        title: 'Prayer & Adhan',
        summary:
            'Offline prayer calculations, adhan reminders, and notification health.',
        kind: AppModuleKind.core,
        releaseState: ModuleReleaseState.available,
        networkRequirement: ModuleNetworkRequirement.offlineOnly,
        requiredPackIds: <String>{AppContentPackIds.corePrayer},
      ),
      AppModuleDefinition(
        id: AppModuleId.qibla,
        title: 'Qibla',
        summary:
            'Local qibla bearing using device sensors or manual coordinates.',
        kind: AppModuleKind.core,
        releaseState: ModuleReleaseState.available,
        networkRequirement: ModuleNetworkRequirement.offlineOnly,
        requiredPackIds: <String>{AppContentPackIds.corePrayer},
      ),
      AppModuleDefinition(
        id: AppModuleId.hijriDate,
        title: 'Hijri Date',
        summary:
            'Local Hijri date and prayer-day context without network dependency.',
        kind: AppModuleKind.core,
        releaseState: ModuleReleaseState.available,
        networkRequirement: ModuleNetworkRequirement.offlineOnly,
        requiredPackIds: <String>{AppContentPackIds.corePrayer},
      ),
      AppModuleDefinition(
        id: AppModuleId.quranReader,
        title: 'Quran Reader',
        summary:
            'Bundled Quran Arabic reading with optional downloaded translations.',
        kind: AppModuleKind.core,
        releaseState: ModuleReleaseState.available,
        networkRequirement: ModuleNetworkRequirement.offlineOnly,
        requiredPackIds: <String>{AppContentPackIds.quranArabic},
      ),
      AppModuleDefinition(
        id: AppModuleId.hadithFinder,
        title: 'Hadith Finder',
        summary:
            'Free cited Sunni Hadith lookup after installing a local HadeethEnc pack.',
        kind: AppModuleKind.freePack,
        releaseState: ModuleReleaseState.available,
        networkRequirement: ModuleNetworkRequirement.offlineAfterInstall,
        requiredPackPrefixes: <String>{'hadith_pack:'},
      ),
      AppModuleDefinition(
        id: AppModuleId.smartQuranSearch,
        title: 'Smart Quran Search',
        summary:
            'Deterministic offline Quran search with normalization, fuzzy matching, and reasoned suggestions.',
        kind: AppModuleKind.freePack,
        releaseState: ModuleReleaseState.comingSoon,
        networkRequirement: ModuleNetworkRequirement.offlineAfterInstall,
        requiredPackIds: <String>{AppContentPackIds.smartQuranSearch},
      ),
      AppModuleDefinition(
        id: AppModuleId.basicsLearning,
        title: 'Basics of Islam',
        summary:
            'Offline beginner-friendly lessons, checklists, and sourced references.',
        kind: AppModuleKind.freePack,
        releaseState: ModuleReleaseState.comingSoon,
        networkRequirement: ModuleNetworkRequirement.offlineAfterInstall,
        requiredPackIds: <String>{AppContentPackIds.basicsLearning},
      ),
      AppModuleDefinition(
        id: AppModuleId.duaDhikr,
        title: 'Dua & Dhikr',
        summary:
            'Offline sourced adhkar and duas with transliteration and translation.',
        kind: AppModuleKind.freePack,
        releaseState: ModuleReleaseState.comingSoon,
        networkRequirement: ModuleNetworkRequirement.offlineAfterInstall,
        requiredPackIds: <String>{AppContentPackIds.duaDhikr},
      ),
      AppModuleDefinition(
        id: AppModuleId.quranAudio,
        title: 'Quran Audio',
        summary:
            'Optional recitation streaming and later offline downloads, pending source licensing review.',
        kind: AppModuleKind.freePack,
        releaseState: ModuleReleaseState.blocked,
        networkRequirement: ModuleNetworkRequirement.networkOptional,
        requiredPackIds: <String>{AppContentPackIds.quranAudioStarter},
        blockedReason:
            'Blocked until recitation licensing and offline-download permissions are verified.',
      ),
      AppModuleDefinition(
        id: AppModuleId.quranAssistant,
        title: 'Quran Assistant',
        summary:
            'BYOK-first grounded assistant over local Quran Arabic and installed translations.',
        kind: AppModuleKind.paidModule,
        releaseState: ModuleReleaseState.available,
        networkRequirement: ModuleNetworkRequirement.networkOptional,
        requiredPackIds: <String>{AppContentPackIds.quranArabic},
        requiredEntitlements: <AppEntitlement>{AppEntitlement.aiQuran},
      ),
      AppModuleDefinition(
        id: AppModuleId.hadithAssistant,
        title: 'Hadith Assistant',
        summary:
            'BYOK-first grounded assistant over installed local Hadith packs with explicit citations.',
        kind: AppModuleKind.paidModule,
        releaseState: ModuleReleaseState.available,
        networkRequirement: ModuleNetworkRequirement.networkOptional,
        requiredPackPrefixes: <String>{'hadith_pack:'},
        requiredEntitlements: <AppEntitlement>{AppEntitlement.aiHadith},
      ),
      AppModuleDefinition(
        id: AppModuleId.scholarSources,
        title: 'Scholar Sources & Opinions',
        summary:
            'Curated institutions, source feeds, and linked summaries with explicit attribution.',
        kind: AppModuleKind.paidModule,
        releaseState: ModuleReleaseState.available,
        networkRequirement: ModuleNetworkRequirement.networkOptional,
        requiredEntitlements: <AppEntitlement>{AppEntitlement.scholarFeed},
      ),
    ],
  );
}
