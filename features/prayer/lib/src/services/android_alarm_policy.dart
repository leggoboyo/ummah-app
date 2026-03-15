import '../domain/prayer_notification.dart';

enum AndroidAlarmDeliveryMode {
  exactAllowWhileIdle,
  inexactNotification,
}

class AndroidAlarmDecision {
  const AndroidAlarmDecision({
    required this.mode,
    required this.message,
    this.actionHint,
  });

  final AndroidAlarmDeliveryMode mode;
  final String message;
  final String? actionHint;
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
        actionHint:
            'If you reboot, travel, or change time zones, open Ummah App once so it can confirm the next prayer alerts.',
      );
    }

    if (preferences.preciseAndroidAlarms && !exactAlarmPermissionGranted) {
      return const AndroidAlarmDecision(
        mode: AndroidAlarmDeliveryMode.inexactNotification,
        message:
            'Prayer reminders are on. Your phone may delay some alerts slightly to save battery.',
        actionHint:
            'Allow precise alarms in Android settings if you want on-the-dot adhan timing.',
      );
    }

    return const AndroidAlarmDecision(
      mode: AndroidAlarmDeliveryMode.inexactNotification,
      message: 'Prayer reminders are on.',
      actionHint:
          'Open Ummah App after major time changes so the next reminder window stays accurate.',
    );
  }
}
