import '../domain/notification_health.dart';
import '../domain/prayer_notification.dart';

class IosNotificationWindowPlanner {
  const IosNotificationWindowPlanner({
    this.pendingNotificationCap = 64,
    this.safetyBuffer = 4,
  });

  final int pendingNotificationCap;
  final int safetyBuffer;

  IosNotificationWindowPlan plan({
    required DateTime now,
    required List<PrayerNotificationEvent> queuedEvents,
    required PrayerNotificationPreferences preferences,
  }) {
    final DateTime coverageTarget =
        now.add(Duration(days: preferences.iosRollingWindowDays));
    final int schedulableCount = pendingNotificationCap - safetyBuffer;
    final List<PrayerNotificationEvent> scheduled = queuedEvents
        .where((PrayerNotificationEvent event) =>
            event.scheduledFor.isBefore(coverageTarget))
        .take(schedulableCount)
        .toList();

    final List<PrayerNotificationEvent> deferred =
        queuedEvents.skip(scheduled.length).toList();

    final DateTime? coverageUntil =
        scheduled.isEmpty ? null : scheduled.last.scheduledFor;

    final NotificationHealth health;
    if (scheduled.isEmpty) {
      health = const NotificationHealth(
        status: NotificationHealthStatus.critical,
        message: 'Prayer reminders are not scheduled right now.',
      );
    } else if (coverageUntil!.difference(now) < const Duration(days: 3)) {
      health = NotificationHealth(
        status: NotificationHealthStatus.warning,
        message:
            'Prayer reminders are active. Open the app soon to keep them going.',
        coverageUntil: coverageUntil,
        scheduledCount: scheduled.length,
      );
    } else {
      health = NotificationHealth(
        status: NotificationHealthStatus.healthy,
        message: 'Prayer reminders are ready.',
        coverageUntil: coverageUntil,
        scheduledCount: scheduled.length,
      );
    }

    return IosNotificationWindowPlan(
      scheduled: scheduled,
      deferred: deferred,
      health: health,
    );
  }
}

class IosNotificationWindowPlan {
  const IosNotificationWindowPlan({
    required this.scheduled,
    required this.deferred,
    required this.health,
  });

  final List<PrayerNotificationEvent> scheduled;
  final List<PrayerNotificationEvent> deferred;
  final NotificationHealth health;
}
