import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('startup selection copyWith preserves prior values by default', () {
    const StartupSelection selection = StartupSelection(
      preset: StartupSetupPreset.lightest,
      selectedPackIds: <String>['quran_translation:default'],
      deferredPackIds: <String>['quran_audio:starter'],
      wifiOnlyDownloads: true,
      storageSaverMode: true,
    );

    final StartupSelection next = selection.copyWith(
      preset: StartupSetupPreset.custom,
    );

    expect(next.preset, StartupSetupPreset.custom);
    expect(next.selectedPackIds, selection.selectedPackIds);
    expect(next.deferredPackIds, selection.deferredPackIds);
    expect(next.wifiOnlyDownloads, isTrue);
    expect(next.storageSaverMode, isTrue);
  });
}
