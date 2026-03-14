import 'package:core/core.dart';
import 'package:subscriptions/subscriptions.dart';
import 'package:test/test.dart';

void main() {
  test('local preview provider persists purchased entitlements', () async {
    final _InMemoryKeyValueStore store = _InMemoryKeyValueStore();
    final SubscriptionRepository repository = SubscriptionRepository(
      provider: LocalPreviewSubscriptionProvider(
        keyValueStore: store,
      ),
    );

    final SubscriptionState initialState = await repository.initialize();
    final PurchaseResult result =
        await repository.purchase('hadith_plus_addon');
    final SubscriptionState refreshedState = await repository.refresh();

    expect(initialState.activeEntitlements, contains(AppEntitlement.coreFree));
    expect(result.status, PurchaseStatus.success);
    expect(
      hasEntitlement(
        refreshedState.activeEntitlements,
        AppEntitlement.hadithPlus,
      ),
      isTrue,
    );
  });

  test('mega bundle unlocks bundled entitlements in preview mode', () async {
    final SubscriptionRepository repository = SubscriptionRepository(
      provider: LocalPreviewSubscriptionProvider(
        keyValueStore: _InMemoryKeyValueStore(),
      ),
    );

    await repository.initialize();
    final PurchaseResult result =
        await repository.purchase('mega_bundle_monthly:monthly');

    expect(result.status, PurchaseStatus.success);
    expect(
      hasEntitlement(result.state.activeEntitlements, AppEntitlement.aiQuran),
      isTrue,
    );
    expect(
      hasEntitlement(
          result.state.activeEntitlements, AppEntitlement.scholarFeed),
      isTrue,
    );
  });

  test('catalog-only providers remain unavailable until store wiring exists',
      () async {
    final SubscriptionRepository repository = SubscriptionRepository(
      provider: RevenueCatSubscriptionProvider(),
    );

    final SubscriptionState state = await repository.initialize();
    final PurchaseResult result =
        await repository.purchase('hadith_plus_addon');

    expect(state.availability, BillingAvailability.unavailable);
    expect(result.status, PurchaseStatus.unavailable);
    expect(result.message, contains('RevenueCat'));
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
