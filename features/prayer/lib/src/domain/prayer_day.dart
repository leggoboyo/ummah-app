import 'prayer_name.dart';
import 'prayer_settings.dart';

class PrayerDay {
  const PrayerDay({
    required this.date,
    required this.settings,
    required this.times,
  });

  final DateTime date;
  final PrayerSettings settings;
  final Map<PrayerName, DateTime> times;

  DateTime timeFor(PrayerName prayer) => times[prayer]!;

  PrayerName? nextPrayerAfter(DateTime moment) {
    for (final MapEntry<PrayerName, DateTime> entry in times.entries) {
      if (!entry.value.isBefore(moment)) {
        return entry.key;
      }
    }
    return null;
  }
}
