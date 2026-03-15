import 'package:core/core.dart';
import 'package:prayer/prayer.dart';

import 'manual_location_preset.dart';

enum AppLocationMode {
  device,
  manual,
}

enum QuranStartupMode {
  arabicOnly,
  starterPack,
  fullTranslation,
}

StartupSelection _defaultStartupSelectionForMode(QuranStartupMode mode) {
  switch (mode) {
    case QuranStartupMode.arabicOnly:
      return const StartupSelection(
        preset: StartupSetupPreset.lightest,
        selectedPackIds: <String>[
          'core_prayer',
          'quran_arabic',
        ],
        deferredPackIds: <String>[],
        wifiOnlyDownloads: true,
        storageSaverMode: true,
      );
    case QuranStartupMode.starterPack:
    case QuranStartupMode.fullTranslation:
      return const StartupSelection(
        preset: StartupSetupPreset.recommendedStudy,
        selectedPackIds: <String>[
          'core_prayer',
          'quran_arabic',
          'quran_translation:default',
          'hadith_pack:default',
        ],
        deferredPackIds: <String>[],
        wifiOnlyDownloads: true,
        storageSaverMode: false,
      );
  }
}

class AppProfile {
  AppProfile({
    required this.onboardingComplete,
    required this.languageCode,
    required this.fiqhProfile,
    required this.calculationMethod,
    required this.locationMode,
    required this.manualLocationId,
    required this.manualLocationLabel,
    required this.manualTimeZoneId,
    required this.manualCoordinates,
    required this.preciseAndroidAlarms,
    required this.quranStartupMode,
    required this.startupSelection,
    required this.analyticsEnabled,
    this.uiPerformanceModeOverride,
    this.adhanSoundKey = 'default',
  });

  factory AppProfile.defaults() {
    const ManualLocationPreset defaultPreset = ManualLocationPreset(
      id: 'chicago_us',
      city: 'Chicago',
      country: 'United States',
      coordinates: Coordinates(
        latitude: 41.8781,
        longitude: -87.6298,
      ),
      timeZoneId: 'America/Chicago',
    );
    return AppProfile(
      onboardingComplete: false,
      languageCode: 'en',
      fiqhProfile: FiqhProfile.defaultSunni,
      calculationMethod: PrayerCalculationMethod.muslimWorldLeague,
      locationMode: AppLocationMode.manual,
      manualLocationId: defaultPreset.id,
      manualLocationLabel: defaultPreset.label,
      manualTimeZoneId: defaultPreset.timeZoneId,
      manualCoordinates: defaultPreset.coordinates,
      preciseAndroidAlarms: false,
      quranStartupMode: QuranStartupMode.fullTranslation,
      startupSelection: _defaultStartupSelectionForMode(
        QuranStartupMode.fullTranslation,
      ),
      analyticsEnabled: false,
      uiPerformanceModeOverride: null,
    );
  }

  final bool onboardingComplete;
  final String languageCode;
  final FiqhProfile fiqhProfile;
  final PrayerCalculationMethod calculationMethod;
  final AppLocationMode locationMode;
  final String manualLocationId;
  final String manualLocationLabel;
  final String manualTimeZoneId;
  final Coordinates manualCoordinates;
  final bool preciseAndroidAlarms;
  final QuranStartupMode quranStartupMode;
  final StartupSelection startupSelection;
  final bool analyticsEnabled;
  final UiPerformanceMode? uiPerformanceModeOverride;
  final String adhanSoundKey;

  AppProfile copyWith({
    bool? onboardingComplete,
    String? languageCode,
    FiqhProfile? fiqhProfile,
    PrayerCalculationMethod? calculationMethod,
    AppLocationMode? locationMode,
    String? manualLocationId,
    String? manualLocationLabel,
    String? manualTimeZoneId,
    Coordinates? manualCoordinates,
    bool? preciseAndroidAlarms,
    QuranStartupMode? quranStartupMode,
    StartupSelection? startupSelection,
    bool? analyticsEnabled,
    UiPerformanceMode? uiPerformanceModeOverride,
    bool clearUiPerformanceModeOverride = false,
    String? adhanSoundKey,
  }) {
    return AppProfile(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      languageCode: languageCode ?? this.languageCode,
      fiqhProfile: fiqhProfile ?? this.fiqhProfile,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      locationMode: locationMode ?? this.locationMode,
      manualLocationId: manualLocationId ?? this.manualLocationId,
      manualLocationLabel: manualLocationLabel ?? this.manualLocationLabel,
      manualTimeZoneId: manualTimeZoneId ?? this.manualTimeZoneId,
      manualCoordinates: manualCoordinates ?? this.manualCoordinates,
      preciseAndroidAlarms: preciseAndroidAlarms ?? this.preciseAndroidAlarms,
      quranStartupMode: quranStartupMode ?? this.quranStartupMode,
      startupSelection: startupSelection ?? this.startupSelection,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      uiPerformanceModeOverride: clearUiPerformanceModeOverride
          ? null
          : (uiPerformanceModeOverride ?? this.uiPerformanceModeOverride),
      adhanSoundKey: adhanSoundKey ?? this.adhanSoundKey,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'onboardingComplete': onboardingComplete,
      'languageCode': languageCode,
      'fiqhTradition': fiqhProfile.tradition.name,
      'school': fiqhProfile.school.name,
      'calculationMethod': calculationMethod.name,
      'locationMode': locationMode.name,
      'manualLocationId': manualLocationId,
      'manualLocationLabel': manualLocationLabel,
      'manualTimeZoneId': manualTimeZoneId,
      'manualLatitude': manualCoordinates.latitude,
      'manualLongitude': manualCoordinates.longitude,
      'preciseAndroidAlarms': preciseAndroidAlarms,
      'quranStartupMode': quranStartupMode.name,
      'startupSetupPreset': startupSelection.preset.name,
      'selectedPackIds': startupSelection.selectedPackIds,
      'deferredPackIds': startupSelection.deferredPackIds,
      'wifiOnlyDownloads': startupSelection.wifiOnlyDownloads,
      'storageSaverMode': startupSelection.storageSaverMode,
      'analyticsEnabled': analyticsEnabled,
      'uiPerformanceModeOverride': uiPerformanceModeOverride?.name,
      'adhanSoundKey': adhanSoundKey,
    };
  }

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    final AppProfile defaults = AppProfile.defaults();

    final FiqhTradition tradition = FiqhTradition.values.firstWhere(
      (FiqhTradition value) => value.name == json['fiqhTradition'],
      orElse: () => defaults.fiqhProfile.tradition,
    );
    final SchoolOfThought school = SchoolOfThought.values.firstWhere(
      (SchoolOfThought value) => value.name == json['school'],
      orElse: () => defaults.fiqhProfile.school,
    );
    final Coordinates manualCoordinates = Coordinates(
      latitude: (json['manualLatitude'] as num?)?.toDouble() ??
          defaults.manualCoordinates.latitude,
      longitude: (json['manualLongitude'] as num?)?.toDouble() ??
          defaults.manualCoordinates.longitude,
    );
    final ManualLocationPreset inferredPreset = closestManualLocationPreset(
      manualCoordinates,
    );
    final QuranStartupMode startupMode = () {
      final String? raw = json['quranStartupMode'] as String?;
      if (raw == 'starterPack') {
        return QuranStartupMode.fullTranslation;
      }
      return QuranStartupMode.values.firstWhere(
        (QuranStartupMode value) => value.name == raw,
        orElse: () => defaults.quranStartupMode,
      );
    }();
    final List<String>? selectedPackIds =
        (json['selectedPackIds'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false);
    final List<String>? deferredPackIds =
        (json['deferredPackIds'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false);
    final StartupSelection startupSelection =
        selectedPackIds == null || selectedPackIds.isEmpty
            ? _defaultStartupSelectionForMode(startupMode)
            : StartupSelection(
                preset: StartupSetupPreset.values.firstWhere(
                  (StartupSetupPreset value) =>
                      value.name == json['startupSetupPreset'],
                  orElse: () => defaults.startupSelection.preset,
                ),
                selectedPackIds: selectedPackIds,
                deferredPackIds: deferredPackIds ?? const <String>[],
                wifiOnlyDownloads: json['wifiOnlyDownloads'] as bool? ??
                    defaults.startupSelection.wifiOnlyDownloads,
                storageSaverMode: json['storageSaverMode'] as bool? ??
                    defaults.startupSelection.storageSaverMode,
              );

    return AppProfile(
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      languageCode: json['languageCode'] as String? ?? defaults.languageCode,
      fiqhProfile: FiqhProfile(
        tradition: tradition,
        school: school,
      ),
      calculationMethod: PrayerCalculationMethod.values.firstWhere(
        (PrayerCalculationMethod value) =>
            value.name == json['calculationMethod'],
        orElse: () => defaults.calculationMethod,
      ),
      locationMode: AppLocationMode.values.firstWhere(
        (AppLocationMode value) => value.name == json['locationMode'],
        orElse: () => defaults.locationMode,
      ),
      manualLocationId:
          json['manualLocationId'] as String? ?? inferredPreset.id,
      manualLocationLabel:
          json['manualLocationLabel'] as String? ?? inferredPreset.label,
      manualTimeZoneId:
          json['manualTimeZoneId'] as String? ?? inferredPreset.timeZoneId,
      manualCoordinates: manualCoordinates,
      preciseAndroidAlarms: json['preciseAndroidAlarms'] as bool? ??
          defaults.preciseAndroidAlarms,
      quranStartupMode: startupMode,
      startupSelection: startupSelection,
      analyticsEnabled: false,
      uiPerformanceModeOverride: _parseUiPerformanceModeOverride(
        json['uiPerformanceModeOverride'],
        defaults.uiPerformanceModeOverride,
      ),
      adhanSoundKey: json['adhanSoundKey'] as String? ?? defaults.adhanSoundKey,
    );
  }

  static UiPerformanceMode? _parseUiPerformanceModeOverride(
    Object? rawValue,
    UiPerformanceMode? fallback,
  ) {
    final String? normalized = rawValue as String?;
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }

    for (final UiPerformanceMode mode in UiPerformanceMode.values) {
      if (mode.name == normalized) {
        return mode;
      }
    }
    return fallback;
  }
}
