import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer/prayer.dart';
import 'package:subscriptions/subscriptions.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_controller.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_environment.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_identity_store.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_profile_store.dart';
import 'package:ummah_mobile_app/src/bootstrap/device_capabilities_service.dart';
import 'package:ummah_mobile_app/src/bootstrap/device_location_service.dart';
import 'package:ummah_mobile_app/src/bootstrap/local_notifications_service.dart';

void main() {
  test('initialize keeps billing lazy for revenuecat builds', () async {
    final _SpyAppIdentityStore identityStore = _SpyAppIdentityStore();
    final _SpySubscriptionProvider provider = _SpySubscriptionProvider(
      initialState: SubscriptionState.initial(
        providerKind: BillingProviderKind.revenueCat,
        catalog: buildDefaultSubscriptionCatalog(),
        availability: BillingAvailability.configured,
        statusMessage: 'Loaded.',
      ),
    );
    final AppController controller = AppController(
      environment: const AppEnvironment(
        flavor: AppFlavor.prod,
        hostedAiEnabled: false,
        entitlementProvider: EntitlementProviderMode.revenueCat,
        apiBaseUrl: '',
        revenueCatAndroidPublicSdkKey: 'public_android_key',
        revenueCatIosPublicSdkKey: 'public_ios_key',
      ),
      profileStore: InMemoryAppProfileStore(),
      identityStore: identityStore,
      subscriptionRepository: SubscriptionRepository(provider: provider),
      locationService: FakeDeviceLocationService(
        const DeviceLocationResult(
          status: DeviceLocationStatus.ready,
          message: 'Using manual city.',
          coordinates: Coordinates(latitude: 41.8781, longitude: -87.6298),
        ),
      ),
      notificationsService: FakePrayerNotificationsService(
        NotificationSyncResult(
          health: const NotificationHealth(
            status: NotificationHealthStatus.healthy,
            message: 'Notifications scheduled.',
          ),
          scheduledCount: 3,
          notificationsEnabled: true,
        ),
      ),
      deviceCapabilitiesService: _FakeDeviceCapabilitiesService(
        UiPerformanceMode.standard,
      ),
    );

    await controller.initialize();

    expect(identityStore.ensureCount, 0);
    expect(provider.initializeCount, 0);
    expect(controller.revenueCatAppUserId, isNull);
    expect(
      controller.subscriptionStatusMessage,
      contains('open Plans & Unlocks'),
    );
  });

  test('loading billing creates app user id and initializes subscriptions',
      () async {
    final _SpyAppIdentityStore identityStore = _SpyAppIdentityStore();
    final _SpySubscriptionProvider provider = _SpySubscriptionProvider(
      initialState: SubscriptionState.initial(
        providerKind: BillingProviderKind.revenueCat,
        catalog: buildDefaultSubscriptionCatalog(),
        availability: BillingAvailability.configured,
        statusMessage: 'Loaded.',
      ),
    );
    final AppController controller = AppController(
      environment: const AppEnvironment(
        flavor: AppFlavor.prod,
        hostedAiEnabled: false,
        entitlementProvider: EntitlementProviderMode.revenueCat,
        apiBaseUrl: '',
        revenueCatAndroidPublicSdkKey: 'public_android_key',
        revenueCatIosPublicSdkKey: 'public_ios_key',
      ),
      profileStore: InMemoryAppProfileStore(),
      identityStore: identityStore,
      subscriptionRepository: SubscriptionRepository(provider: provider),
      locationService: FakeDeviceLocationService(
        const DeviceLocationResult(
          status: DeviceLocationStatus.ready,
          message: 'Using manual city.',
          coordinates: Coordinates(latitude: 41.8781, longitude: -87.6298),
        ),
      ),
      notificationsService: FakePrayerNotificationsService(
        NotificationSyncResult(
          health: const NotificationHealth(
            status: NotificationHealthStatus.healthy,
            message: 'Notifications scheduled.',
          ),
          scheduledCount: 3,
          notificationsEnabled: true,
        ),
      ),
      deviceCapabilitiesService: _FakeDeviceCapabilitiesService(
        UiPerformanceMode.standard,
      ),
    );

    await controller.initialize();
    await controller.loadBillingStateIfNeeded();

    expect(identityStore.ensureCount, 1);
    expect(provider.initializeCount, 1);
    expect(controller.revenueCatAppUserId, 'ummah_test_identity');
    expect(controller.billingAvailability, BillingAvailability.configured);
  });
}

class _SpyAppIdentityStore implements AppIdentityStore {
  int ensureCount = 0;
  String? _appUserId;

  @override
  Future<String> ensureAppUserId() async {
    ensureCount += 1;
    return _appUserId ??= 'ummah_test_identity';
  }

  @override
  Future<String> ensureRevenueCatAppUserId() {
    return ensureAppUserId();
  }

  @override
  Future<String?> readAppUserId() async => _appUserId;

  @override
  Future<String?> readRevenueCatAppUserId() async => _appUserId;
}

class _SpySubscriptionProvider implements SubscriptionProvider {
  _SpySubscriptionProvider({
    required this.initialState,
  });

  final SubscriptionState initialState;
  int initializeCount = 0;

  @override
  Future<SubscriptionState> initialize() async {
    initializeCount += 1;
    return initialState;
  }

  @override
  Future<PurchaseResult> purchase(String productId) {
    throw UnimplementedError();
  }

  @override
  Future<SubscriptionState> refresh() async {
    return initialState;
  }

  @override
  Future<PurchaseResult> restorePurchases() {
    throw UnimplementedError();
  }
}

class _FakeDeviceCapabilitiesService extends DeviceCapabilitiesService {
  _FakeDeviceCapabilitiesService(this.mode);

  final UiPerformanceMode mode;

  @override
  Future<UiPerformanceMode> resolve({
    UiPerformanceMode? override,
  }) async {
    return override ?? mode;
  }
}
