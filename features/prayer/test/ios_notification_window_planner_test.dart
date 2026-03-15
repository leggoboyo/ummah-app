import 'package:prayer/prayer.dart';
import 'package:test/test.dart';

void main() {
  group('IosNotificationWindowPlanner', () {
    const IosNotificationWindowPlanner planner = IosNotificationWindowPlanner();

    test('schedules only up to the safe pending count', () {
      final DateTime now = DateTime(2026, 3, 13, 8);
      final PrayerNotificationPreferences preferences =
          const PrayerNotificationPreferences(
        iosRollingWindowDays: 30,
      );
      final List<PrayerNotificationEvent> events =
          List<PrayerNotificationEvent>.generate(
        80,
        (int index) => PrayerNotificationEvent(
          id: 'event-$index',
          prayer: PrayerName.fajr,
          scheduledFor: now.add(Duration(hours: index + 1)),
          soundKey: 'adhan_1',
        ),
      );

      final IosNotificationWindowPlan plan = planner.plan(
        now: now,
        queuedEvents: events,
        preferences: preferences,
      );

      expect(plan.scheduled, hasLength(60));
      expect(plan.deferred, hasLength(20));
      expect(plan.health.status, NotificationHealthStatus.warning);
      expect(plan.health.actionHint, contains('next few days'));
    });

    test('reports healthy coverage when the next week is planned', () {
      final DateTime now = DateTime(2026, 3, 13, 8);
      final PrayerNotificationPreferences preferences =
          const PrayerNotificationPreferences(
        iosRollingWindowDays: 8,
      );
      final List<PrayerNotificationEvent> events =
          List<PrayerNotificationEvent>.generate(
        40,
        (int index) => PrayerNotificationEvent(
          id: 'event-$index',
          prayer: PrayerName.fajr,
          scheduledFor: now.add(Duration(hours: (index + 1) * 5)),
          soundKey: 'adhan_1',
        ),
      );

      final IosNotificationWindowPlan plan = planner.plan(
        now: now,
        queuedEvents: events,
        preferences: preferences,
      );

      expect(plan.scheduled.length, greaterThanOrEqualTo(35));
      expect(plan.health.status, NotificationHealthStatus.healthy);
      expect(plan.health.coverageUntil, isNotNull);
      expect(plan.health.actionHint, contains('once a week'));
    });

    test('reports critical status and recovery hint when nothing is queued',
        () {
      final IosNotificationWindowPlan plan = planner.plan(
        now: DateTime(2026, 3, 13, 8),
        queuedEvents: const <PrayerNotificationEvent>[],
        preferences: const PrayerNotificationPreferences(),
      );

      expect(plan.scheduled, isEmpty);
      expect(plan.health.status, NotificationHealthStatus.critical);
      expect(plan.health.actionHint, contains('refresh prayer alerts'));
    });
  });
}
