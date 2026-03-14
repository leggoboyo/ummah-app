import 'package:core/core.dart';

import '../domain/prayer_day.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_notification.dart';
import '../domain/prayer_settings.dart';
import 'prayer_time_calculator.dart';

class PrayerNotificationQueueBuilder {
  const PrayerNotificationQueueBuilder({
    PrayerTimeCalculator? calculator,
  }) : _calculator = calculator ?? const PrayerTimeCalculator();

  final PrayerTimeCalculator _calculator;

  List<PrayerNotificationEvent> buildUpcomingQueue({
    required DateTime now,
    required Coordinates coordinates,
    required PrayerSettings settings,
    required PrayerNotificationPreferences preferences,
    int days = 60,
  }) {
    final List<PrayerNotificationEvent> events = <PrayerNotificationEvent>[];

    for (int dayOffset = 0; dayOffset < days; dayOffset += 1) {
      final DateTime day = DateTime(now.year, now.month, now.day + dayOffset);
      final PrayerDay prayerDay = _calculator.calculate(
        date: day,
        coordinates: coordinates,
        settings: settings,
      );

      for (final PrayerName prayer in preferences.enabledPrayers) {
        final DateTime scheduledFor = prayerDay.timeFor(prayer);
        if (scheduledFor.isAfter(now)) {
          events.add(
            PrayerNotificationEvent(
              id: '${day.toIso8601String()}-${prayer.name}',
              prayer: prayer,
              scheduledFor: scheduledFor,
              soundKey: preferences.soundKey,
            ),
          );
        }
      }
    }

    events.sort(
      (PrayerNotificationEvent a, PrayerNotificationEvent b) =>
          a.scheduledFor.compareTo(b.scheduledFor),
    );
    return events;
  }
}
