import '../domain/prayer_notification.dart';

enum AndroidAlarmDeliveryMode {
  exactAllowWhileIdle,
  inexactNotification,
}

class AndroidAlarmDecision {
  const AndroidAlarmDecision({
    required this.mode,
    required this.message,
  });

  final AndroidAlarmDeliveryMode mode;
  final String message;
}

class AndroidAlarmPolicy {
  const AndroidAlarmPolicy();

  AndroidAlarmDecision decide({
    required PrayerNotificationPreferences preferences,
    required bool exactAlarmPermissionGranted,
  }) {
    if (preferences.preciseAndroidAlarms && exactAlarmPermissionGranted) {
      return const AndroidAlarmDecision(
        mode: AndroidAlarmDeliveryMode.exactAllowWhileIdle,
        message: 'Prayer reminders are set to precise alarms.',
      );
    }

    if (preferences.preciseAndroidAlarms && !exactAlarmPermissionGranted) {
      return const AndroidAlarmDecision(
        mode: AndroidAlarmDeliveryMode.inexactNotification,
        message:
            'Prayer reminders are on. Your phone may delay some alerts slightly to save battery.',
      );
    }

    return const AndroidAlarmDecision(
      mode: AndroidAlarmDeliveryMode.inexactNotification,
      message: 'Prayer reminders are on.',
    );
  }
}
