import 'package:core/core.dart';

import 'high_latitude_rule.dart';

enum PrayerCalculationMethod {
  muslimWorldLeague,
  egyptian,
  karachi,
  northAmerica,
  ummAlQura,
  jafari,
}

enum SolarRuleType {
  angle,
  minutesAfterSunset,
  sunset,
}

class SolarEventRule {
  const SolarEventRule._({
    required this.type,
    this.angle,
    this.minutes,
  });

  const SolarEventRule.angle(double value)
      : this._(type: SolarRuleType.angle, angle: value);

  const SolarEventRule.minutesAfterSunset(int value)
      : this._(type: SolarRuleType.minutesAfterSunset, minutes: value);

  const SolarEventRule.sunset() : this._(type: SolarRuleType.sunset);

  final SolarRuleType type;
  final double? angle;
  final int? minutes;
}

class MethodPreset {
  const MethodPreset({
    required this.method,
    required this.displayName,
    required this.fajrAngle,
    required this.maghribRule,
    required this.ishaRule,
    required this.highLatitudeRule,
  });

  final PrayerCalculationMethod method;
  final String displayName;
  final double fajrAngle;
  final SolarEventRule maghribRule;
  final SolarEventRule ishaRule;
  final HighLatitudeRule highLatitudeRule;
}

MethodPreset methodPresetFor(
  PrayerCalculationMethod method, {
  required FiqhProfile fiqhProfile,
}) {
  switch (method) {
    case PrayerCalculationMethod.muslimWorldLeague:
      return const MethodPreset(
        method: PrayerCalculationMethod.muslimWorldLeague,
        displayName: 'Muslim World League',
        fajrAngle: 18,
        maghribRule: SolarEventRule.sunset(),
        ishaRule: SolarEventRule.angle(17),
        highLatitudeRule: HighLatitudeRule.middleOfTheNight,
      );
    case PrayerCalculationMethod.egyptian:
      return const MethodPreset(
        method: PrayerCalculationMethod.egyptian,
        displayName: 'Egyptian General Authority',
        fajrAngle: 19.5,
        maghribRule: SolarEventRule.sunset(),
        ishaRule: SolarEventRule.angle(17.5),
        highLatitudeRule: HighLatitudeRule.middleOfTheNight,
      );
    case PrayerCalculationMethod.karachi:
      return const MethodPreset(
        method: PrayerCalculationMethod.karachi,
        displayName: 'University of Islamic Sciences, Karachi',
        fajrAngle: 18,
        maghribRule: SolarEventRule.sunset(),
        ishaRule: SolarEventRule.angle(18),
        highLatitudeRule: HighLatitudeRule.middleOfTheNight,
      );
    case PrayerCalculationMethod.northAmerica:
      return const MethodPreset(
        method: PrayerCalculationMethod.northAmerica,
        displayName: 'Islamic Society of North America',
        fajrAngle: 15,
        maghribRule: SolarEventRule.sunset(),
        ishaRule: SolarEventRule.angle(15),
        highLatitudeRule: HighLatitudeRule.middleOfTheNight,
      );
    case PrayerCalculationMethod.ummAlQura:
      return const MethodPreset(
        method: PrayerCalculationMethod.ummAlQura,
        displayName: 'Umm al-Qura',
        fajrAngle: 18.5,
        maghribRule: SolarEventRule.sunset(),
        ishaRule: SolarEventRule.minutesAfterSunset(90),
        highLatitudeRule: HighLatitudeRule.middleOfTheNight,
      );
    case PrayerCalculationMethod.jafari:
      return MethodPreset(
        method: PrayerCalculationMethod.jafari,
        displayName: 'Ja‘fari',
        fajrAngle: 16,
        maghribRule: const SolarEventRule.angle(4),
        ishaRule: const SolarEventRule.angle(14),
        highLatitudeRule: fiqhProfile.tradition == FiqhTradition.shia
            ? HighLatitudeRule.twilightAngle
            : HighLatitudeRule.middleOfTheNight,
      );
  }
}
