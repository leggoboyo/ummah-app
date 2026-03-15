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
  testWidgets('Hadith Finder opens for free users from the More tab', (
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
        provider: LocalPreviewSubscriptionProvider(
          keyValueStore: _InMemoryKeyValueStore(),
          catalog: const <SubscriptionProduct>[
            SubscriptionProduct(
              id: 'hadith_plus_addon',
              title: 'Hadith Plus',
              tagline: 'Unlock extra Hadith language packs.',
              description: 'Test product for widget integration.',
              kind: SubscriptionProductKind.lifetimeAddOn,
              primaryEntitlement: AppEntitlement.hadithPlus,
              includesEntitlements: <AppEntitlement>{
                AppEntitlement.hadithPlus,
              },
              isFeatured: true,
            ),
          ],
        ),
      ),
      identityStore: _TestAppIdentityStore(),
    );

    await controller.initialize();
    await tester.pumpWidget(UmmahApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Continue'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('More'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final Finder hadithLabel = find.text('Hadith Finder');
    await tester.scrollUntilVisible(
      hadithLabel,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Free'), findsOneWidget);
    expect(
      find.textContaining('Free Sunni Hadith Finder'),
      findsOneWidget,
    );

    await tester.tap(hadithLabel.last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Hadith Finder'), findsWidgets);
    expect(find.text('Plans & Unlocks'), findsNothing);
  });
}

class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _storage = <String, String>{};

  @override
  Future<String?> readString(String key) async => _storage[key];

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    _storage[key] = value;
  }
}

class _TestAppIdentityStore implements AppIdentityStore {
  String? _appUserId;

  @override
  Future<String> ensureAppUserId() async {
    return _appUserId ??= 'ummah_test_subscription';
  }

  @override
  Future<String> ensureRevenueCatAppUserId() async {
    return ensureAppUserId();
  }

  @override
  Future<String?> readAppUserId() async => _appUserId;

  @override
  Future<String?> readRevenueCatAppUserId() async => _appUserId;
}
