import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer/prayer.dart';
import 'package:subscriptions/subscriptions.dart';
import 'package:ummah_mobile_app/src/app/ummah_app.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_controller.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_identity_store.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_profile_store.dart';
import 'package:ummah_mobile_app/src/bootstrap/device_location_service.dart';
import 'package:ummah_mobile_app/src/bootstrap/local_notifications_service.dart';

void main() {
  testWidgets('completing onboarding enters the home shell', (
    WidgetTester tester,
  ) async {
    final AppController controller = AppController(
      profileStore: InMemoryAppProfileStore(),
      locationService: FakeDeviceLocationService(
        const DeviceLocationResult(
          status: DeviceLocationStatus.ready,
          message: 'Using your device location for prayer times and qibla.',
          coordinates: Coordinates(
            latitude: 41.8781,
            longitude: -87.6298,
          ),
        ),
      ),
      notificationsService: FakePrayerNotificationsService(
        NotificationSyncResult(
          health: const NotificationHealth(
            status: NotificationHealthStatus.healthy,
            message: 'Notifications are scheduled.',
          ),
          scheduledCount: 5,
          notificationsEnabled: true,
        ),
      ),
      subscriptionRepository: SubscriptionRepository(
        provider: RevenueCatSubscriptionProvider(),
      ),
      identityStore: _TestAppIdentityStore(),
    );

    await controller.initialize();
    await tester.pumpWidget(UmmahApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Ummah App'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Continue'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Notification health'), findsOneWidget);
    expect(find.text('Prayer'), findsOneWidget);
  });
}

class _TestAppIdentityStore implements AppIdentityStore {
  String? _appUserId;

  @override
  Future<String> ensureRevenueCatAppUserId() async {
    return _appUserId ??= 'ummah_test_onboarding';
  }

  @override
  Future<String?> readRevenueCatAppUserId() async => _appUserId;
}
