import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:prayer/prayer.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

class NotificationSyncResult {
  const NotificationSyncResult({
    required this.health,
    required this.scheduledCount,
    required this.notificationsEnabled,
    this.androidAlarmDecision,
  });

  final NotificationHealth health;
  final int scheduledCount;
  final bool notificationsEnabled;
  final AndroidAlarmDecision? androidAlarmDecision;
}

abstract interface class PrayerNotificationsService {
  Future<void> initialize();

  Future<NotificationSyncResult> syncPrayerSchedule({
    required DateTime now,
    required PrayerSettings settings,
    required PrayerNotificationPreferences preferences,
    required PrayerDay Function(DateTime date) calculatePrayerDay,
    required Coordinates coordinates,
    required bool requestPermissions,
  });
}

class LocalPrayerNotificationsService implements PrayerNotificationsService {
  LocalPrayerNotificationsService({
    FlutterLocalNotificationsPlugin? plugin,
    PrayerNotificationQueueBuilder? queueBuilder,
    IosNotificationWindowPlanner? iosPlanner,
    AndroidAlarmPolicy? androidAlarmPolicy,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _queueBuilder = queueBuilder ?? const PrayerNotificationQueueBuilder(),
        _iosPlanner = iosPlanner ?? const IosNotificationWindowPlanner(),
        _androidAlarmPolicy = androidAlarmPolicy ?? const AndroidAlarmPolicy();

  final FlutterLocalNotificationsPlugin _plugin;
  final PrayerNotificationQueueBuilder _queueBuilder;
  final IosNotificationWindowPlanner _iosPlanner;
  final AndroidAlarmPolicy _androidAlarmPolicy;

  bool _initialized = false;

  static const AndroidNotificationChannel _prayerChannel =
      AndroidNotificationChannel(
    'prayer_adhan',
    'Prayer Adhan',
    description: 'Prayer time reminders and adhan alerts.',
    importance: Importance.max,
  );

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    final TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_prayerChannel);

    _initialized = true;
  }

  @override
  Future<NotificationSyncResult> syncPrayerSchedule({
    required DateTime now,
    required PrayerSettings settings,
    required PrayerNotificationPreferences preferences,
    required PrayerDay Function(DateTime date) calculatePrayerDay,
    required Coordinates coordinates,
    required bool requestPermissions,
  }) async {
    await initialize();

    final _PermissionSnapshot permissionSnapshot = await _requestPermissions(
      requestPermissions: requestPermissions,
      preferences: preferences,
    );

    final AndroidAlarmDecision? androidAlarmDecision =
        permissionSnapshot.androidAlarmDecision;

    if (!permissionSnapshot.notificationsEnabled) {
      return NotificationSyncResult(
        health: const NotificationHealth(
          status: NotificationHealthStatus.critical,
          message: 'Prayer reminders are off on this phone.',
          actionHint:
              'Turn notifications back on in system settings, then refresh prayer alerts in Ummah App.',
        ),
        scheduledCount: 0,
        notificationsEnabled: false,
        androidAlarmDecision: androidAlarmDecision,
      );
    }

    await _plugin.cancelAll();

    final List<PrayerNotificationEvent> queue =
        _queueBuilder.buildUpcomingQueue(
      now: now,
      coordinates: coordinates,
      settings: settings,
      preferences: preferences,
    );

    final List<PrayerNotificationEvent> scheduledEvents;
    NotificationHealth health;

    if (Platform.isIOS) {
      final IosNotificationWindowPlan iosPlan = _iosPlanner.plan(
        now: now,
        queuedEvents: queue,
        preferences: preferences,
      );
      scheduledEvents = iosPlan.scheduled;
      health = iosPlan.health;
    } else {
      scheduledEvents = queue;
      final DateTime? coverageUntil =
          scheduledEvents.isEmpty ? null : scheduledEvents.last.scheduledFor;
      health = NotificationHealth(
        status: androidAlarmDecision?.mode ==
                AndroidAlarmDeliveryMode.inexactNotification
            ? NotificationHealthStatus.warning
            : NotificationHealthStatus.healthy,
        message: androidAlarmDecision?.message ??
            'Prayer reminders are ready on this phone.',
        coverageUntil: coverageUntil,
        scheduledCount: scheduledEvents.length,
        actionHint: androidAlarmDecision?.actionHint,
      );
    }

    final AndroidScheduleMode scheduleMode = androidAlarmDecision?.mode ==
            AndroidAlarmDeliveryMode.exactAllowWhileIdle
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final PrayerNotificationEvent event in scheduledEvents) {
      final bool useSound = preferences.soundKey != 'silent';
      await _plugin.zonedSchedule(
        id: _notificationIdFor(event),
        title: '${event.prayer.label} prayer',
        body: 'It is time for ${event.prayer.label}.',
        scheduledDate: tz.TZDateTime.from(event.scheduledFor, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _prayerChannel.id,
            _prayerChannel.name,
            channelDescription: _prayerChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            playSound: useSound,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: useSound,
          ),
        ),
        androidScheduleMode: scheduleMode,
      );
    }

    return NotificationSyncResult(
      health: health,
      scheduledCount: scheduledEvents.length,
      notificationsEnabled: true,
      androidAlarmDecision: androidAlarmDecision,
    );
  }

  Future<_PermissionSnapshot> _requestPermissions({
    required bool requestPermissions,
    required PrayerNotificationPreferences preferences,
  }) async {
    bool notificationsEnabled = true;
    AndroidAlarmDecision? androidAlarmDecision;

    if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (requestPermissions) {
        notificationsEnabled = await iosPlugin?.requestPermissions(
              alert: true,
              badge: false,
              sound: true,
            ) ??
            false;
      } else {
        final NotificationsEnabledOptions? options =
            await iosPlugin?.checkPermissions();
        notificationsEnabled = options?.isEnabled ?? true;
      }
    }

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (requestPermissions) {
        notificationsEnabled =
            await androidPlugin?.requestNotificationsPermission() ?? true;
      } else {
        notificationsEnabled =
            await androidPlugin?.areNotificationsEnabled() ?? true;
      }

      bool exactAlarmGranted = false;
      if (preferences.preciseAndroidAlarms) {
        exactAlarmGranted = requestPermissions
            ? await androidPlugin?.requestExactAlarmsPermission() ?? false
            : await androidPlugin?.canScheduleExactNotifications() ?? false;
      }

      androidAlarmDecision = _androidAlarmPolicy.decide(
        preferences: preferences,
        exactAlarmPermissionGranted: exactAlarmGranted,
      );
    }

    return _PermissionSnapshot(
      notificationsEnabled: notificationsEnabled,
      androidAlarmDecision: androidAlarmDecision,
    );
  }

  int _notificationIdFor(PrayerNotificationEvent event) {
    final DateTime value = event.scheduledFor;
    final String id = '${value.year % 100}'
        '${value.month.toString().padLeft(2, '0')}'
        '${value.day.toString().padLeft(2, '0')}'
        '${event.prayer.index}';
    return int.parse(id);
  }
}

class _PermissionSnapshot {
  const _PermissionSnapshot({
    required this.notificationsEnabled,
    required this.androidAlarmDecision,
  });

  final bool notificationsEnabled;
  final AndroidAlarmDecision? androidAlarmDecision;
}

class FakePrayerNotificationsService implements PrayerNotificationsService {
  const FakePrayerNotificationsService(this.result);

  final NotificationSyncResult result;

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationSyncResult> syncPrayerSchedule({
    required DateTime now,
    required PrayerSettings settings,
    required PrayerNotificationPreferences preferences,
    required PrayerDay Function(DateTime date) calculatePrayerDay,
    required Coordinates coordinates,
    required bool requestPermissions,
  }) async {
    return result;
  }
}
