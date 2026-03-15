import 'package:prayer/prayer.dart';
import 'package:test/test.dart';

void main() {
  group('AndroidAlarmPolicy', () {
    const AndroidAlarmPolicy policy = AndroidAlarmPolicy();

    test('uses exact alarms when precise timing is enabled and granted', () {
      final AndroidAlarmDecision decision = policy.decide(
        preferences: PrayerNotificationPreferences(
          preciseAndroidAlarms: true,
        ),
        exactAlarmPermissionGranted: true,
      );

      expect(decision.mode, AndroidAlarmDeliveryMode.exactAllowWhileIdle);
      expect(decision.message, contains('precise alarms'));
      expect(decision.actionHint, contains('reboot'));
    });

    test('falls back gracefully when exact alarm permission is denied', () {
      final AndroidAlarmDecision decision = policy.decide(
        preferences: PrayerNotificationPreferences(
          preciseAndroidAlarms: true,
        ),
        exactAlarmPermissionGranted: false,
      );

      expect(decision.mode, AndroidAlarmDeliveryMode.inexactNotification);
      expect(decision.message, contains('delay some alerts'));
      expect(decision.actionHint, contains('Allow precise alarms'));
    });
  });
}
