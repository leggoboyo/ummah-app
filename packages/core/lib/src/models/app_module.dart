import 'entitlement.dart';

enum AppModuleId {
  onboarding,
  prayerCore,
  qibla,
  hijriDate,
  quranReader,
  hadithFinder,
  smartQuranSearch,
  basicsLearning,
  duaDhikr,
  quranAudio,
  quranAssistant,
  hadithAssistant,
  scholarSources,
}

extension AppModuleIdX on AppModuleId {
  String get key {
    switch (this) {
      case AppModuleId.onboarding:
        return 'onboarding';
      case AppModuleId.prayerCore:
        return 'prayer_core';
      case AppModuleId.qibla:
        return 'qibla';
      case AppModuleId.hijriDate:
        return 'hijri_date';
      case AppModuleId.quranReader:
        return 'quran_reader';
      case AppModuleId.hadithFinder:
        return 'hadith_finder';
      case AppModuleId.smartQuranSearch:
        return 'smart_quran_search';
      case AppModuleId.basicsLearning:
        return 'basics_learning';
      case AppModuleId.duaDhikr:
        return 'dua_dhikr';
      case AppModuleId.quranAudio:
        return 'quran_audio';
      case AppModuleId.quranAssistant:
        return 'quran_assistant';
      case AppModuleId.hadithAssistant:
        return 'hadith_assistant';
      case AppModuleId.scholarSources:
        return 'scholar_sources';
    }
  }
}

enum AppModuleKind {
  core,
  freePack,
  paidModule,
}

enum ModuleReleaseState {
  available,
  comingSoon,
  blocked,
}

enum ModuleNetworkRequirement {
  offlineOnly,
  offlineAfterInstall,
  networkOptional,
}

class AppModuleDefinition {
  const AppModuleDefinition({
    required this.id,
    required this.title,
    required this.summary,
    required this.kind,
    required this.releaseState,
    required this.networkRequirement,
    this.requiredPackIds = const <String>{},
    this.requiredPackPrefixes = const <String>{},
    this.requiredEntitlements = const <AppEntitlement>{},
    this.blockedReason,
  });

  final AppModuleId id;
  final String title;
  final String summary;
  final AppModuleKind kind;
  final ModuleReleaseState releaseState;
  final ModuleNetworkRequirement networkRequirement;
  final Set<String> requiredPackIds;
  final Set<String> requiredPackPrefixes;
  final Set<AppEntitlement> requiredEntitlements;
  final String? blockedReason;
}

class ResolvedAppModule {
  const ResolvedAppModule({
    required this.definition,
    required this.isUnlocked,
    required this.isInstalled,
    required this.isReady,
    required this.missingPackIds,
    required this.missingPackPrefixes,
    this.statusMessage,
  });

  final AppModuleDefinition definition;
  final bool isUnlocked;
  final bool isInstalled;
  final bool isReady;
  final Set<String> missingPackIds;
  final Set<String> missingPackPrefixes;
  final String? statusMessage;
}

class AppModuleRegistry {
  const AppModuleRegistry(this.modules);

  final List<AppModuleDefinition> modules;

  AppModuleDefinition definitionFor(AppModuleId id) {
    return modules.firstWhere((AppModuleDefinition entry) => entry.id == id);
  }

  List<ResolvedAppModule> resolve({
    required Set<String> installedPackIds,
    required Set<AppEntitlement> activeEntitlements,
  }) {
    return modules.map((AppModuleDefinition definition) {
      final Set<String> missingPackIds = definition.requiredPackIds
          .where((String packId) => !installedPackIds.contains(packId))
          .toSet();
      final Set<String> missingPackPrefixes = definition.requiredPackPrefixes
          .where(
            (String prefix) => !installedPackIds.any(
                (String installedPackId) => installedPackId.startsWith(prefix)),
          )
          .toSet();
      final bool isUnlocked = definition.requiredEntitlements.isEmpty ||
          definition.requiredEntitlements.every(
            (AppEntitlement entitlement) =>
                hasEntitlement(activeEntitlements, entitlement),
          );
      final bool isInstalled =
          missingPackIds.isEmpty && missingPackPrefixes.isEmpty;
      final bool isAvailable =
          definition.releaseState == ModuleReleaseState.available;
      final bool isReady = isAvailable && isUnlocked && isInstalled;

      return ResolvedAppModule(
        definition: definition,
        isUnlocked: isUnlocked,
        isInstalled: isInstalled,
        isReady: isReady,
        missingPackIds: missingPackIds,
        missingPackPrefixes: missingPackPrefixes,
        statusMessage: _statusMessageFor(
          definition: definition,
          isUnlocked: isUnlocked,
          missingPackIds: missingPackIds,
          missingPackPrefixes: missingPackPrefixes,
        ),
      );
    }).toList(growable: false);
  }

  String? _statusMessageFor({
    required AppModuleDefinition definition,
    required bool isUnlocked,
    required Set<String> missingPackIds,
    required Set<String> missingPackPrefixes,
  }) {
    switch (definition.releaseState) {
      case ModuleReleaseState.available:
        break;
      case ModuleReleaseState.comingSoon:
        return 'Coming soon.';
      case ModuleReleaseState.blocked:
        return definition.blockedReason ?? 'Blocked pending external review.';
    }

    if (!isUnlocked) {
      return 'Requires a paid unlock.';
    }

    if (missingPackIds.isNotEmpty || missingPackPrefixes.isNotEmpty) {
      return 'Requires local content packs before it can run offline.';
    }

    return 'Ready on this device.';
  }
}
