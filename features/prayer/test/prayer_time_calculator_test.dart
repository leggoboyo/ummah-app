import 'package:core/core.dart';
import 'package:prayer/prayer.dart';
import 'package:test/test.dart';

void main() {
  group('PrayerTimeCalculator', () {
    const PrayerTimeCalculator calculator = PrayerTimeCalculator();
    const Coordinates chicago = Coordinates(
      latitude: 41.8781,
      longitude: -87.6298,
    );
    const Coordinates mecca = Coordinates(
      latitude: 21.3891,
      longitude: 39.8579,
    );
    const Coordinates reykjavik = Coordinates(
      latitude: 64.1466,
      longitude: -21.9426,
    );

    test('calculates Chicago prayer times for MWL defaults', () {
      final PrayerSettings settings = PrayerSettings.withDefaultMethod(
        fiqhProfile: FiqhProfile.defaultSunni,
        method: PrayerCalculationMethod.muslimWorldLeague,
        timeZoneOffset: const Duration(hours: -5),
      );

      final PrayerDay result = calculator.calculate(
        date: DateTime(2026, 3, 13),
        coordinates: chicago,
        settings: settings,
      );

      expect(_clock(result.timeFor(PrayerName.fajr)), '05:33');
      expect(_clock(result.timeFor(PrayerName.sunrise)), '07:06');
      expect(_clock(result.timeFor(PrayerName.dhuhr)), '13:00');
      expect(_clock(result.timeFor(PrayerName.asr)), '16:19');
      expect(_clock(result.timeFor(PrayerName.maghrib)), '18:55');
      expect(_clock(result.timeFor(PrayerName.isha)), '20:22');
    });

    test('moves Asr later for Hanafi profile defaults', () {
      final PrayerSettings settings = PrayerSettings.withDefaultMethod(
        fiqhProfile: const FiqhProfile(
          tradition: FiqhTradition.sunni,
          school: SchoolOfThought.hanafi,
        ),
        method: PrayerCalculationMethod.muslimWorldLeague,
        timeZoneOffset: const Duration(hours: -5),
      );

      final PrayerDay result = calculator.calculate(
        date: DateTime(2026, 3, 13),
        coordinates: chicago,
        settings: settings,
      );

      expect(_clock(result.timeFor(PrayerName.asr)), '17:08');
    });

    test('supports Umm al-Qura fixed Isha offset', () {
      final PrayerSettings settings = PrayerSettings.withDefaultMethod(
        fiqhProfile: FiqhProfile.defaultSunni,
        method: PrayerCalculationMethod.ummAlQura,
        timeZoneOffset: const Duration(hours: 3),
      );

      final PrayerDay result = calculator.calculate(
        date: DateTime(2026, 3, 13),
        coordinates: mecca,
        settings: settings,
      );

      expect(_clock(result.timeFor(PrayerName.fajr)), '05:15');
      expect(_clock(result.timeFor(PrayerName.maghrib)), '18:29');
      expect(_clock(result.timeFor(PrayerName.isha)), '19:59');
    });

    test('supports Ja‘fari defaults with later Maghrib than sunset', () {
      final PrayerSettings settings = PrayerSettings.withDefaultMethod(
        fiqhProfile: FiqhProfile.defaultShia,
        method: PrayerCalculationMethod.jafari,
        timeZoneOffset: const Duration(hours: -5),
      );

      final PrayerDay result = calculator.calculate(
        date: DateTime(2026, 3, 13),
        coordinates: chicago,
        settings: settings,
      );

      expect(_clock(result.timeFor(PrayerName.fajr)), '05:44');
      expect(_clock(result.timeFor(PrayerName.maghrib)), '19:12');
      expect(_clock(result.timeFor(PrayerName.isha)), '20:06');
    });

    test('applies high latitude handling without breaking event order', () {
      final PrayerSettings settings = PrayerSettings.withDefaultMethod(
        fiqhProfile: FiqhProfile.defaultSunni,
        method: PrayerCalculationMethod.muslimWorldLeague,
        timeZoneOffset: Duration.zero,
      );

      final PrayerDay result = calculator.calculate(
        date: DateTime(2026, 5, 20),
        coordinates: reykjavik,
        settings: settings,
      );

      expect(_clock(result.timeFor(PrayerName.fajr)), '01:25');
      expect(_clock(result.timeFor(PrayerName.sunrise)), '03:57');
      expect(_clock(result.timeFor(PrayerName.maghrib)), '22:53');
      expect(_clock(result.timeFor(PrayerName.isha)), '01:25');
      expect(
        result
            .timeFor(PrayerName.sunrise)
            .isAfter(result.timeFor(PrayerName.fajr)),
        isTrue,
      );
    });
  });
}

String _clock(DateTime value) {
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
