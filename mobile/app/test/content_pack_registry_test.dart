import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hadith/hadith.dart';
import 'package:ummah_mobile_app/src/content_packs/content_pack_registry.dart';

void main() {
  test('recommended study preset selects translation and hadith starter packs',
      () {
    final ContentPackRegistry registry = ContentPackRegistry();

    final StartupSelection selection = registry.selectionForPreset(
      StartupSetupPreset.recommendedStudy,
    );

    expect(
      selection.selectedPackIds,
      containsAll(<String>[
        AppContentPackIds.corePrayer,
        AppContentPackIds.quranArabic,
        AppContentPackIds.quranTranslationDefault,
        AppContentPackIds.hadithPackDefault,
      ]),
    );
    expect(selection.storageSaverMode, isFalse);
    expect(selection.wifiOnlyDownloads, isTrue);
  });

  test('startup packs do not require remote hadith discovery', () async {
    final ContentPackRegistry registry = ContentPackRegistry(
      hadithRepository: _ThrowingHadithRepository(),
    );

    final List<ContentPackManifest> packs = await registry.getStartupPacks(
      preferredLanguageCode: 'ur',
    );

    expect(
      packs.any(
        (ContentPackManifest pack) =>
            pack.id == AppContentPackIds.hadithPackDefault &&
            pack.languageCode == 'ur',
      ),
      isTrue,
    );
  });
}

class _ThrowingHadithRepository extends HadithRepository {
  @override
  Future<HadithPackManifest?> getRecommendedPack({
    required String preferredLanguageCode,
  }) {
    throw StateError('Remote manifest should not be consulted here.');
  }
}
