import 'package:core/core.dart';

import 'high_latitude_rule.dart';
import 'prayer_calculation_method.dart';
import 'prayer_name.dart';

class PrayerSettings {
  const PrayerSettings({
    required this.fiqhProfile,
    required this.method,
    required this.timeZoneOffset,
    required this.fajrAngle,
    required this.maghribRule,
    required this.ishaRule,
    required this.asrMethod,
    required this.highLatitudeRule,
    this.dhuhrOffsetMinutes = 0,
    this.adjustments = const <PrayerName, int>{},
  });

  final FiqhProfile fiqhProfile;
  final PrayerCalculationMethod method;
  final Duration timeZoneOffset;
  final double fajrAngle;
  final SolarEventRule maghribRule;
  final SolarEventRule ishaRule;
  final AsrMethod asrMethod;
  final HighLatitudeRule highLatitudeRule;
  final int dhuhrOffsetMinutes;
  final Map<PrayerName, int> adjustments;

  factory PrayerSettings.withDefaultMethod({
    required FiqhProfile fiqhProfile,
    required PrayerCalculationMethod method,
    required Duration timeZoneOffset,
    Map<PrayerName, int> adjustments = const <PrayerName, int>{},
  }) {
    final MethodPreset preset = methodPresetFor(
      method,
      fiqhProfile: fiqhProfile,
    );

    return PrayerSettings(
      fiqhProfile: fiqhProfile,
      method: method,
      timeZoneOffset: timeZoneOffset,
      fajrAngle: preset.fajrAngle,
      maghribRule: preset.maghribRule,
      ishaRule: preset.ishaRule,
      asrMethod: fiqhProfile.defaultAsrMethod,
      highLatitudeRule: preset.highLatitudeRule,
      adjustments: adjustments,
    );
  }
}
