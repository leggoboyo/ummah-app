import 'dart:math' as math;

import 'package:core/core.dart';

import '../domain/high_latitude_rule.dart';
import '../domain/prayer_calculation_method.dart';
import '../domain/prayer_day.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_settings.dart';

class PrayerTimeCalculator {
  const PrayerTimeCalculator();

  PrayerDay calculate({
    required DateTime date,
    required Coordinates coordinates,
    required PrayerSettings settings,
  }) {
    final DateTime localDate = DateTime(date.year, date.month, date.day);
    final double timeZoneHours = settings.timeZoneOffset.inMinutes / 60.0;
    final double julianDay =
        _julianDate(localDate) - coordinates.longitude / 360.0;

    final Map<PrayerName, double> times = <PrayerName, double>{
      PrayerName.fajr: 5,
      PrayerName.sunrise: 6,
      PrayerName.dhuhr: 12,
      PrayerName.asr: 13,
      PrayerName.maghrib: 18,
      PrayerName.isha: 18.5,
    };

    final Map<PrayerName, double> computedTimes = _computeTimes(
      julianDay: julianDay,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      timeZoneHours: timeZoneHours,
      settings: settings,
      seedTimes: times,
    );

    final Map<PrayerName, DateTime> resolvedTimes = <PrayerName, DateTime>{};
    for (final MapEntry<PrayerName, double> entry in computedTimes.entries) {
      final int adjustment = settings.adjustments[entry.key] ?? 0;
      resolvedTimes[entry.key] = _dateFromFloatHours(
        localDate,
        entry.value + (adjustment / 60.0),
      );
    }

    return PrayerDay(
      date: localDate,
      settings: settings,
      times: resolvedTimes,
    );
  }

  Map<PrayerName, double> _computeTimes({
    required double julianDay,
    required double latitude,
    required double longitude,
    required double timeZoneHours,
    required PrayerSettings settings,
    required Map<PrayerName, double> seedTimes,
  }) {
    final Map<PrayerName, double> dayPortions = _dayPortions(seedTimes);

    final double fajr = _sunAngleTime(
      julianDay,
      latitude,
      180 - settings.fajrAngle,
      dayPortions[PrayerName.fajr]!,
      true,
    );
    final double sunrise = _sunAngleTime(
      julianDay,
      latitude,
      180 - 0.833,
      dayPortions[PrayerName.sunrise]!,
      true,
    );
    final double dhuhr = _midDay(julianDay, dayPortions[PrayerName.dhuhr]!);
    final double asr = _asrTime(
      julianDay,
      latitude,
      settings.asrMethod == AsrMethod.hanafi ? 2 : 1,
      dayPortions[PrayerName.asr]!,
    );
    final double sunset = _sunAngleTime(
      julianDay,
      latitude,
      0.833,
      dayPortions[PrayerName.maghrib]!,
      false,
    );

    double maghrib = sunset;
    if (settings.maghribRule.type == SolarRuleType.angle) {
      maghrib = _sunAngleTime(
        julianDay,
        latitude,
        settings.maghribRule.angle!,
        dayPortions[PrayerName.maghrib]!,
        false,
      );
    } else if (settings.maghribRule.type == SolarRuleType.minutesAfterSunset) {
      maghrib = sunset + (settings.maghribRule.minutes! / 60.0);
    }

    double isha = sunset;
    if (settings.ishaRule.type == SolarRuleType.angle) {
      isha = _sunAngleTime(
        julianDay,
        latitude,
        settings.ishaRule.angle!,
        dayPortions[PrayerName.isha]!,
        false,
      );
    } else if (settings.ishaRule.type == SolarRuleType.minutesAfterSunset) {
      isha = sunset + (settings.ishaRule.minutes! / 60.0);
    }

    final double adjustedSunset = sunset + timeZoneHours - longitude / 15.0;
    final Map<PrayerName, double> adjusted = <PrayerName, double>{
      PrayerName.fajr: fajr + timeZoneHours - longitude / 15.0,
      PrayerName.sunrise: sunrise + timeZoneHours - longitude / 15.0,
      PrayerName.dhuhr: dhuhr +
          timeZoneHours -
          longitude / 15.0 +
          settings.dhuhrOffsetMinutes / 60.0,
      PrayerName.asr: asr + timeZoneHours - longitude / 15.0,
      PrayerName.maghrib: maghrib + timeZoneHours - longitude / 15.0,
      PrayerName.isha: isha + timeZoneHours - longitude / 15.0,
    };

    return _adjustHighLatitudeTimes(adjusted, settings, adjustedSunset);
  }

  Map<PrayerName, double> _adjustHighLatitudeTimes(
    Map<PrayerName, double> times,
    PrayerSettings settings,
    double sunsetTime,
  ) {
    final double night = _timeDiff(sunsetTime, times[PrayerName.sunrise]!);
    if (night.isNaN) {
      return times;
    }

    final double fajrPortion = _nightPortion(
      settings.highLatitudeRule,
      settings.fajrAngle,
      night,
    );
    final double fajrGap =
        _timeDiff(times[PrayerName.fajr]!, times[PrayerName.sunrise]!);
    if (times[PrayerName.fajr]!.isNaN ||
        (!fajrGap.isNaN && fajrGap > fajrPortion)) {
      times[PrayerName.fajr] = times[PrayerName.sunrise]! - fajrPortion;
    }

    if (settings.ishaRule.type == SolarRuleType.angle) {
      final double ishaPortion = _nightPortion(
        settings.highLatitudeRule,
        settings.ishaRule.angle!,
        night,
      );
      final double ishaGap = _timeDiff(sunsetTime, times[PrayerName.isha]!);
      if (times[PrayerName.isha]!.isNaN ||
          (!ishaGap.isNaN && ishaGap > ishaPortion)) {
        times[PrayerName.isha] = sunsetTime + ishaPortion;
      }
    }

    if (settings.maghribRule.type == SolarRuleType.angle) {
      final double maghribPortion = _nightPortion(
        settings.highLatitudeRule,
        settings.maghribRule.angle!,
        night,
      );
      final double maghribGap =
          _timeDiff(sunsetTime, times[PrayerName.maghrib]!);
      if (times[PrayerName.maghrib]!.isNaN ||
          (!maghribGap.isNaN && maghribGap > maghribPortion)) {
        times[PrayerName.maghrib] = sunsetTime + maghribPortion;
      }
    }

    return times;
  }

  Map<PrayerName, double> _dayPortions(Map<PrayerName, double> times) {
    return <PrayerName, double>{
      for (final MapEntry<PrayerName, double> entry in times.entries)
        entry.key: entry.value / 24.0,
    };
  }

  double _midDay(double julianDay, double time) {
    final SolarPosition position = _solarPosition(julianDay + time);
    return _fixHour(12 - position.equationOfTime);
  }

  double _sunAngleTime(
    double julianDay,
    double latitude,
    double angle,
    double time,
    bool beforeMidday,
  ) {
    final SolarPosition position = _solarPosition(julianDay + time);
    final double declination = position.declination;
    final double noon = _midDay(julianDay, time);
    final double numerator =
        -_sinDeg(angle) - _sinDeg(declination) * _sinDeg(latitude);
    final double denominator = _cosDeg(declination) * _cosDeg(latitude);
    final double arccosInput = numerator / denominator;
    if (arccosInput.isNaN || arccosInput < -1.0 || arccosInput > 1.0) {
      return double.nan;
    }
    final double delta = _acosDeg(arccosInput) / 15.0;
    return noon + (beforeMidday ? -delta : delta);
  }

  double _asrTime(
    double julianDay,
    double latitude,
    int shadowFactor,
    double time,
  ) {
    final SolarPosition position = _solarPosition(julianDay + time);
    final double declination = position.declination;
    final double angle = -_acotDeg(
      shadowFactor + _tanDeg((latitude - declination).abs()),
    );
    return _sunAngleTime(julianDay, latitude, angle, time, false);
  }

  double _nightPortion(
    HighLatitudeRule rule,
    double angle,
    double nightLength,
  ) {
    switch (rule) {
      case HighLatitudeRule.middleOfTheNight:
        return nightLength / 2.0;
      case HighLatitudeRule.seventhOfTheNight:
        return nightLength / 7.0;
      case HighLatitudeRule.twilightAngle:
        return nightLength * (angle / 60.0);
    }
  }

  DateTime _dateFromFloatHours(DateTime baseDate, double hours) {
    final int roundedMinutes = (hours * 60).round();
    return DateTime(baseDate.year, baseDate.month, baseDate.day)
        .add(Duration(minutes: roundedMinutes));
  }

  double _julianDate(DateTime date) {
    int year = date.year;
    int month = date.month;
    final int day = date.day;

    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    final int a = year ~/ 100;
    final int b = 2 - a + (a ~/ 4);

    return (365.25 * (year + 4716)).floorToDouble() +
        (30.6001 * (month + 1)).floorToDouble() +
        day +
        b -
        1524.5;
  }

  SolarPosition _solarPosition(double julianDay) {
    final double d = julianDay - 2451545.0;
    final double g = _fixAngle(357.529 + 0.98560028 * d);
    final double q = _fixAngle(280.459 + 0.98564736 * d);
    final double l = _fixAngle(q + 1.915 * _sinDeg(g) + 0.020 * _sinDeg(2 * g));

    final double e = 23.439 - 0.00000036 * d;
    final double rightAscension =
        _atan2Deg(_cosDeg(e) * _sinDeg(l), _cosDeg(l)) / 15.0;
    final double equationOfTime = q / 15.0 - _fixHour(rightAscension);
    final double declination = _asinDeg(_sinDeg(e) * _sinDeg(l));

    return SolarPosition(
      declination: declination,
      equationOfTime: equationOfTime,
    );
  }

  double _fixAngle(double angle) {
    return angle - 360.0 * (angle / 360.0).floorToDouble();
  }

  double _fixHour(double hour) {
    return hour - 24.0 * (hour / 24.0).floorToDouble();
  }

  double _timeDiff(double time1, double time2) {
    if (time1.isNaN || time2.isNaN) {
      return double.nan;
    }
    return _fixHour(time2 - time1);
  }

  double _sinDeg(double degrees) => math.sin(_degreesToRadians(degrees));

  double _cosDeg(double degrees) => math.cos(_degreesToRadians(degrees));

  double _tanDeg(double degrees) => math.tan(_degreesToRadians(degrees));

  double _asinDeg(double value) => _radiansToDegrees(math.asin(value));

  double _acosDeg(double value) => _radiansToDegrees(math.acos(value));

  double _atan2Deg(double y, double x) => _radiansToDegrees(math.atan2(y, x));

  double _acotDeg(double value) => _radiansToDegrees(math.atan(1.0 / value));

  double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;

  double _radiansToDegrees(double radians) => radians * 180.0 / math.pi;
}

class SolarPosition {
  const SolarPosition({
    required this.declination,
    required this.equationOfTime,
  });

  final double declination;
  final double equationOfTime;
}
