import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('default registry exposes all planned modules', () {
    final AppModuleRegistry registry = buildDefaultAppModuleRegistry();

    expect(registry.modules.map((AppModuleDefinition module) => module.id), {
      AppModuleId.onboarding,
      AppModuleId.prayerCore,
      AppModuleId.qibla,
      AppModuleId.hijriDate,
      AppModuleId.quranReader,
      AppModuleId.hadithFinder,
      AppModuleId.smartQuranSearch,
      AppModuleId.basicsLearning,
      AppModuleId.duaDhikr,
      AppModuleId.quranAudio,
      AppModuleId.quranAssistant,
      AppModuleId.hadithAssistant,
      AppModuleId.scholarSources,
    });
  });

  test('registry resolves pack and entitlement readiness separately', () {
    final AppModuleRegistry registry = buildDefaultAppModuleRegistry();

    final List<ResolvedAppModule> resolved = registry.resolve(
      installedPackIds: <String>{
        AppContentPackIds.corePrayer,
        AppContentPackIds.quranArabic,
        AppContentPackIds.hadithPackLanguage('en'),
      },
      activeEntitlements: <AppEntitlement>{AppEntitlement.coreFree},
    );

    final ResolvedAppModule prayer = resolved.firstWhere(
      (ResolvedAppModule module) =>
          module.definition.id == AppModuleId.prayerCore,
    );
    final ResolvedAppModule hadithFinder = resolved.firstWhere(
      (ResolvedAppModule module) =>
          module.definition.id == AppModuleId.hadithFinder,
    );
    final ResolvedAppModule quranAssistant = resolved.firstWhere(
      (ResolvedAppModule module) =>
          module.definition.id == AppModuleId.quranAssistant,
    );
    final ResolvedAppModule quranAudio = resolved.firstWhere(
      (ResolvedAppModule module) =>
          module.definition.id == AppModuleId.quranAudio,
    );

    expect(prayer.isReady, isTrue);
    expect(hadithFinder.isInstalled, isTrue);
    expect(hadithFinder.isReady, isTrue);
    expect(quranAssistant.isInstalled, isTrue);
    expect(quranAssistant.isUnlocked, isFalse);
    expect(quranAssistant.statusMessage, 'Requires a paid unlock.');
    expect(quranAudio.definition.releaseState, ModuleReleaseState.blocked);
    expect(quranAudio.statusMessage, contains('Blocked'));
  });
}
