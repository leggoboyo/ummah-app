import 'prayer_name.dart';

class PrayerNotificationPreferences {
  const PrayerNotificationPreferences({
    this.enabledPrayers = const <PrayerName>{
      PrayerName.fajr,
      PrayerName.dhuhr,
      PrayerName.asr,
      PrayerName.maghrib,
      PrayerName.isha,
    },
    this.preciseAndroidAlarms = false,
    this.iosRollingWindowDays = 8,
    this.iosPendingNotificationCap = 64,
    this.soundKey = 'adhan_1',
  });

  final Set<PrayerName> enabledPrayers;
  final bool preciseAndroidAlarms;
  final int iosRollingWindowDays;
  final int iosPendingNotificationCap;
  final String soundKey;
}

class PrayerNotificationEvent {
  const PrayerNotificationEvent({
    required this.id,
    required this.prayer,
    required this.scheduledFor,
    required this.soundKey,
  });

  final String id;
  final PrayerName prayer;
  final DateTime scheduledFor;
  final String soundKey;
}
