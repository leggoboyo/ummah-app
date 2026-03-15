import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer/prayer.dart';
import 'package:subscriptions/subscriptions.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_controller.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_environment.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_identity_store.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_profile.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_profile_store.dart';
import 'package:ummah_mobile_app/src/bootstrap/device_capabilities_service.dart';
import 'package:ummah_mobile_app/src/bootstrap/device_location_service.dart';
import 'package:ummah_mobile_app/src/bootstrap/local_notifications_service.dart';
import 'package:ummah_mobile_app/src/bootstrap/manual_location_preset.dart';

void main() {
  test('free core boot stays local and does not initialize billing on startup',
      () async {
    final _TrackingSubscriptionProvider provider =
        _TrackingSubscriptionProvider();
    final AppController controller = AppController(
      environment: const AppEnvironment(
        flavor: AppFlavor.staging,
        hostedAiEnabled: false,
        entitlementProvider: EntitlementProviderMode.revenueCat,
        apiBaseUrl: 'https://ummah-content-pack-worker.zkhawaja721.workers.dev',
        revenueCatAndroidPublicSdkKey: 'goog_test_key',
        revenueCatIosPublicSdkKey: 'appl_test_key',
      ),
      profileStore: InMemoryAppProfileStore(
        AppProfile.defaults().copyWith(
          onboardingComplete: true,
          locationMode: AppLocationMode.manual,
          manualLocationId: 'chicago_us',
          manualLocationLabel: 'Chicago',
          manualTimeZoneId: 'America/Chicago',
          manualCoordinates: const Coordinates(
            latitude: 41.8781,
            longitude: -87.6298,
          ),
          startupSelection: const StartupSelection(
            preset: StartupSetupPreset.lightest,
            selectedPackIds: <String>[
              AppContentPackIds.corePrayer,
              AppContentPackIds.quranArabic,
            ],
            deferredPackIds: <String>[],
            wifiOnlyDownloads: true,
            storageSaverMode: true,
          ),
        ),
      ),
      locationService: const FakeDeviceLocationService(
        DeviceLocationResult(
          status: DeviceLocationStatus.ready,
          message: 'Using your device location for prayer times and qibla.',
          coordinates: Coordinates(latitude: 1, longitude: 1),
        ),
      ),
      notificationsService: FakePrayerNotificationsService(
        NotificationSyncResult(
          health: const NotificationHealth(
            status: NotificationHealthStatus.healthy,
            message: 'Prayer reminders are ready.',
            actionHint: 'Open weekly to keep them scheduled.',
          ),
          scheduledCount: 12,
          notificationsEnabled: true,
        ),
      ),
      subscriptionRepository: SubscriptionRepository(provider: provider),
      identityStore: _TestAppIdentityStore(),
    );

    await controller.initialize();

    expect(provider.initializeCalls, 0);
    expect(controller.revenueCatAppUserId, isNull);
    expect(controller.activeCoordinates.latitude, 41.8781);
    expect(controller.notificationHealth?.status,
        NotificationHealthStatus.healthy);
    expect(
      controller.prayerDayFor(DateTime(2026, 3, 14)).timeFor(PrayerName.fajr),
      isA<DateTime>(),
    );
    expect(
      controller.qiblaDirection.bearingFromTrueNorth,
      inInclusiveRange(45.0, 55.0),
    );
  });

  test('billing state and app user id load only on demand', () async {
    final _TrackingSubscriptionProvider provider =
        _TrackingSubscriptionProvider();
    final _TestAppIdentityStore identityStore = _TestAppIdentityStore();
    final AppController controller = AppController(
      profileStore: InMemoryAppProfileStore(),
      locationService: const FakeDeviceLocationService(
        DeviceLocationResult(
          status: DeviceLocationStatus.ready,
          message: 'Using your device location for prayer times and qibla.',
          coordinates: Coordinates(latitude: 1, longitude: 1),
        ),
      ),
      notificationsService: FakePrayerNotificationsService(
        NotificationSyncResult(
          health: const NotificationHealth(
            status: NotificationHealthStatus.warning,
            message:
                'Prayer reminders are active. Open the app soon to keep them going.',
            actionHint: 'Refresh soon.',
          ),
          scheduledCount: 8,
          notificationsEnabled: true,
        ),
      ),
      subscriptionRepository: SubscriptionRepository(provider: provider),
      identityStore: identityStore,
    );

    await controller.initialize();
    await controller.loadBillingStateIfNeeded();
    await controller.refreshEntitlements();

    expect(provider.initializeCalls, 1);
    expect(provider.refreshCalls, 1);
    expect(controller.revenueCatAppUserId, 'ummah_test_identity');
    expect(controller.hasAccess(AppEntitlement.hadithPlus), isTrue);
  });

  test('manual time zone offsets follow daylight-saving changes', () async {
    final AppController controller = AppController(
      profileStore: InMemoryAppProfileStore(
        AppProfile.defaults().copyWith(
          onboardingComplete: true,
          locationMode: AppLocationMode.manual,
          manualTimeZoneId: 'America/Chicago',
        ),
      ),
      locationService: const FakeDeviceLocationService(
        DeviceLocationResult(
          status: DeviceLocationStatus.ready,
          message: 'Using your device location for prayer times and qibla.',
          coordinates: Coordinates(latitude: 1, longitude: 1),
        ),
      ),
      notificationsService: FakePrayerNotificationsService(
        NotificationSyncResult(
          health: const NotificationHealth(
            status: NotificationHealthStatus.healthy,
            message: 'Prayer reminders are ready.',
          ),
          scheduledCount: 8,
          notificationsEnabled: true,
        ),
      ),
      subscriptionRepository:
          SubscriptionRepository(provider: _TrackingSubscriptionProvider()),
      identityStore: _TestAppIdentityStore(),
    );

    await controller.initialize();

    expect(
      controller.prayerSettingsFor(DateTime(2026, 1, 15)).timeZoneOffset,
      const Duration(hours: -6),
    );
    expect(
      controller.prayerSettingsFor(DateTime(2026, 7, 15)).timeZoneOffset,
      const Duration(hours: -5),
    );
    expect(
      controller.prayerSettingsFor(DateTime(2026, 7, 15)).timeZoneOffset,
      isNot(const Duration(hours: 5)),
    );
  });

  test('manual time zone offsets stay stable in non-DST locales', () async {
    final AppController controller = AppController(
      profileStore: InMemoryAppProfileStore(
        AppProfile.defaults().copyWith(
          onboardingComplete: true,
          locationMode: AppLocationMode.manual,
          manualTimeZoneId: 'Asia/Karachi',
        ),
      ),
      locationService: const FakeDeviceLocationService(
        DeviceLocationResult(
          status: DeviceLocationStatus.ready,
          message: 'Using your device location for prayer times and qibla.',
          coordinates: Coordinates(latitude: 1, longitude: 1),
        ),
      ),
      notificationsService: FakePrayerNotificationsService(
        NotificationSyncResult(
          health: const NotificationHealth(
            status: NotificationHealthStatus.healthy,
            message: 'Prayer reminders are ready.',
          ),
          scheduledCount: 8,
          notificationsEnabled: true,
        ),
      ),
      subscriptionRepository:
          SubscriptionRepository(provider: _TrackingSubscriptionProvider()),
      identityStore: _TestAppIdentityStore(),
    );

    await controller.initialize();

    expect(
      controller.prayerSettingsFor(DateTime(2026, 1, 15)).timeZoneOffset,
      const Duration(hours: 5),
    );
    expect(
      controller.prayerSettingsFor(DateTime(2026, 7, 15)).timeZoneOffset,
      const Duration(hours: 5),
    );
  });

  test('unsupported saved locale falls back to English', () async {
    final AppController controller = AppController(
      profileStore: InMemoryAppProfileStore(
        AppProfile.defaults().copyWith(
          onboardingComplete: true,
          languageCode: 'fr',
        ),
      ),
      locationService: const FakeDeviceLocationService(
        DeviceLocationResult(
          status: DeviceLocationStatus.ready,
          message: 'Using your device location for prayer times and qibla.',
          coordinates: Coordinates(latitude: 1, longitude: 1),
        ),
      ),
      notificationsService: FakePrayerNotificationsService(
        NotificationSyncResult(
          health: const NotificationHealth(
            status: NotificationHealthStatus.healthy,
            message: 'Prayer reminders are ready.',
          ),
          scheduledCount: 8,
          notificationsEnabled: true,
        ),
      ),
      subscriptionRepository:
          SubscriptionRepository(provider: _TrackingSubscriptionProvider()),
      identityStore: _TestAppIdentityStore(),
    );

    await controller.initialize();

    expect(controller.languageCode, 'en');
  });

  test('older Android devices default to lean performance mode', () async {
    final AppController controller = AppController(
      profileStore: InMemoryAppProfileStore(
        AppProfile.defaults().copyWith(onboardingComplete: true),
      ),
      locationService: const FakeDeviceLocationService(
        DeviceLocationResult(
          status: DeviceLocationStatus.ready,
          message: 'Using your device location for prayer times and qibla.',
          coordinates: Coordinates(latitude: 1, longitude: 1),
        ),
      ),
      notificationsService: FakePrayerNotificationsService(
        NotificationSyncResult(
          health: const NotificationHealth(
            status: NotificationHealthStatus.healthy,
            message: 'Prayer reminders are ready.',
          ),
          scheduledCount: 8,
          notificationsEnabled: true,
        ),
      ),
      subscriptionRepository:
          SubscriptionRepository(provider: _TrackingSubscriptionProvider()),
      identityStore: _TestAppIdentityStore(),
      deviceCapabilitiesService: const _TestDeviceCapabilitiesService(
        DeviceCapabilities(androidSdkInt: 24),
      ),
    );

    await controller.initialize();

    expect(controller.uiPerformanceMode, UiPerformanceMode.lean);
  });

  test('manual location updates stay local after onboarding', () async {
    final _CountingDeviceLocationService locationService =
        _CountingDeviceLocationService();
    final AppController controller = AppController(
      profileStore: InMemoryAppProfileStore(
        AppProfile.defaults().copyWith(
          onboardingComplete: true,
          locationMode: AppLocationMode.manual,
        ),
      ),
      locationService: locationService,
      notificationsService: FakePrayerNotificationsService(
        NotificationSyncResult(
          health: const NotificationHealth(
            status: NotificationHealthStatus.healthy,
            message: 'Prayer reminders are ready.',
          ),
          scheduledCount: 8,
          notificationsEnabled: true,
        ),
      ),
      subscriptionRepository:
          SubscriptionRepository(provider: _TrackingSubscriptionProvider()),
      identityStore: _TestAppIdentityStore(),
    );

    await controller.initialize();
    final int callsAfterInitialize = locationService.resolveCalls;

    await controller.updateManualLocationPreset(
      manualLocationPresetById('karachi_pk'),
    );
    await controller.updateManualCoordinates(
      const Coordinates(latitude: 24.8607, longitude: 67.0011),
    );

    expect(locationService.resolveCalls, callsAfterInitialize);
    expect(controller.locationMode, AppLocationMode.manual);
    expect(controller.manualTimeZoneId, isNotEmpty);
    expect(controller.activeCoordinates.latitude, closeTo(24.8607, 0.0001));
  });
}

class _TrackingSubscriptionProvider implements SubscriptionProvider {
  int initializeCalls = 0;
  int refreshCalls = 0;

  @override
  Future<SubscriptionState> initialize() async {
    initializeCalls += 1;
    return _state('Billing loaded on demand.');
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    return PurchaseResult(
      status: PurchaseStatus.unavailable,
      state: _state('Purchases disabled for offline contract tests.'),
      message: 'Purchases disabled for offline contract tests.',
    );
  }

  @override
  Future<SubscriptionState> refresh() async {
    refreshCalls += 1;
    return _state('Billing refresh completed.');
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    return PurchaseResult(
      status: PurchaseStatus.unavailable,
      state: _state('Restore disabled for offline contract tests.'),
      message: 'Restore disabled for offline contract tests.',
    );
  }

  SubscriptionState _state(String message) {
    return SubscriptionState(
      providerKind: BillingProviderKind.revenueCat,
      availability: BillingAvailability.configured,
      activeEntitlements: const <AppEntitlement>{
        AppEntitlement.coreFree,
        AppEntitlement.hadithPlus,
      },
      catalog: buildDefaultSubscriptionCatalog(),
      statusMessage: message,
      lastSyncedAt: DateTime(2026, 3, 14, 10),
    );
  }
}

class _TestAppIdentityStore implements AppIdentityStore {
  String? _appUserId;

  @override
  Future<String> ensureRevenueCatAppUserId() async {
    return _appUserId ??= 'ummah_test_identity';
  }

  @override
  Future<String?> readRevenueCatAppUserId() async => _appUserId;
}

class _TestDeviceCapabilitiesService implements DeviceCapabilitiesService {
  const _TestDeviceCapabilitiesService(this.capabilities);

  final DeviceCapabilities capabilities;

  @override
  Future<DeviceCapabilities> readCapabilities() async => capabilities;
}

class _CountingDeviceLocationService implements DeviceLocationService {
  int resolveCalls = 0;

  @override
  Future<DeviceLocationResult> resolve({
    required bool requestPermission,
  }) async {
    resolveCalls += 1;
    return const DeviceLocationResult(
      status: DeviceLocationStatus.ready,
      message: 'Using your device location for prayer times and qibla.',
      coordinates: Coordinates(latitude: 41.8781, longitude: -87.6298),
    );
  }
}
