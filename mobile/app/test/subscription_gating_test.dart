import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer/prayer.dart';
import 'package:subscriptions/subscriptions.dart';
import 'package:ummah_mobile_app/src/app/ummah_app.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_controller.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_profile_store.dart';
import 'package:ummah_mobile_app/src/bootstrap/device_location_service.dart';
import 'package:ummah_mobile_app/src/bootstrap/local_notifications_service.dart';

void main() {
  testWidgets('locked Hadith module routes to plans, then opens after unlock', (
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
              tagline: 'Unlock the hadith library.',
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    final Finder hadithLabel = find.text('Hadith Library');
    await tester.scrollUntilVisible(
      hadithLabel,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Locked module: unlock Hadith Plus or Mega Bundle to open the hadith library.',
      ),
      findsOneWidget,
    );

    await tester.tap(hadithLabel.last);
    await tester.pumpAndSettle();

    expect(find.text('Plans & Unlocks'), findsOneWidget);
    expect(find.text('Hadith Plus is locked'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Unlock'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
    await tester.pumpAndSettle();

    expect(controller.hasAccess(AppEntitlement.hadithPlus), isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('Unlocked:'), findsOneWidget);

    await tester.scrollUntilVisible(
      hadithLabel,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(hadithLabel.last);
    await tester.pump();

    expect(find.text('Hadith Library'), findsWidgets);
    expect(find.text('Hadith categories refreshed from HadeethEnc.'),
        findsNothing);
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
