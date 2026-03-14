import 'package:core/core.dart';
import 'package:prayer/prayer.dart';

import 'app_profile.dart';
import 'local_notifications_service.dart';

class AppNotificationSyncService {
  const AppNotificationSyncService({
    required PrayerNotificationsService notificationsService,
  }) : _notificationsService = notificationsService;

  final PrayerNotificationsService _notificationsService;

  Future<void> initialize() => _notificationsService.initialize();

  Future<NotificationSyncResult?> sync({
    required AppProfile profile,
    required DateTime now,
    required PrayerSettings settings,
    required PrayerNotificationPreferences preferences,
    required PrayerDay Function(DateTime date) calculatePrayerDay,
    required Coordinates coordinates,
    required bool requestPermissions,
  }) async {
    if (!profile.onboardingComplete) {
      return null;
    }

    return _notificationsService.syncPrayerSchedule(
      now: now,
      settings: settings,
      preferences: preferences,
      calculatePrayerDay: calculatePrayerDay,
      coordinates: coordinates,
      requestPermissions: requestPermissions,
    );
  }
}
