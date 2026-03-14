import 'dart:convert';

import 'package:core/core.dart';

import '../domain/billing_provider_kind.dart';
import '../domain/purchase_result.dart';
import '../domain/subscription_product.dart';
import '../domain/subscription_state.dart';
import 'default_subscription_catalog.dart';
import 'subscription_provider.dart';

class LocalPreviewSubscriptionProvider implements SubscriptionProvider {
  LocalPreviewSubscriptionProvider({
    required KeyValueStore keyValueStore,
    List<SubscriptionProduct>? catalog,
  })  : _keyValueStore = keyValueStore,
        _catalog = catalog ?? buildDefaultSubscriptionCatalog();

  static const String _storageKey = 'subscription_preview_state_v1';

  final KeyValueStore _keyValueStore;
  final List<SubscriptionProduct> _catalog;

  @override
  Future<SubscriptionState> initialize() async {
    return _loadState();
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    final SubscriptionState state = await _loadState();
    final SubscriptionProduct? product = _findProduct(productId);
    if (product == null) {
      return PurchaseResult(
        status: PurchaseStatus.failed,
        state: state,
        message: 'That product is not in the local preview catalog.',
      );
    }

    final Set<AppEntitlement> updated = <AppEntitlement>{
      ...state.activeEntitlements,
      ...product.includesEntitlements,
      AppEntitlement.coreFree,
    };
    final SubscriptionState nextState = state.copyWith(
      activeEntitlements: updated,
      statusMessage:
          'Preview unlock applied for ${product.title}. This simulates store delivery on this device only.',
      lastSyncedAt: DateTime.now(),
    );
    await _persist(nextState);
    return PurchaseResult(
      status: PurchaseStatus.success,
      state: nextState,
      message: nextState.statusMessage!,
    );
  }

  @override
  Future<SubscriptionState> refresh() async {
    final SubscriptionState state = await _loadState();
    return state.copyWith(
      statusMessage:
          'Preview entitlements were refreshed from local device storage.',
      lastSyncedAt: DateTime.now(),
    );
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    final SubscriptionState state = await _loadState();
    final SubscriptionState nextState = state.copyWith(
      statusMessage: 'Preview restore completed from local device storage.',
      lastSyncedAt: DateTime.now(),
    );
    await _persist(nextState);
    return PurchaseResult(
      status: PurchaseStatus.success,
      state: nextState,
      message: nextState.statusMessage!,
    );
  }

  Future<PurchaseResult> resetPreviewPurchases() async {
    final SubscriptionState state = SubscriptionState.initial(
      providerKind: BillingProviderKind.localPreview,
      catalog: _catalog,
      availability: BillingAvailability.preview,
      statusMessage: 'Preview purchases were cleared on this device.',
    ).copyWith(lastSyncedAt: DateTime.now());
    await _persist(state);
    return PurchaseResult(
      status: PurchaseStatus.success,
      state: state,
      message: state.statusMessage!,
    );
  }

  SubscriptionProduct? _findProduct(String productId) {
    for (final SubscriptionProduct product in _catalog) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  Future<SubscriptionState> _loadState() async {
    final String? raw = await _keyValueStore.readString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return SubscriptionState.initial(
        providerKind: BillingProviderKind.localPreview,
        catalog: _catalog,
        availability: BillingAvailability.preview,
        statusMessage:
            'Local preview mode is active. Unlocks are simulated on this device until store billing is connected.',
      );
    }

    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final Set<AppEntitlement> entitlements = (json['entitlements']
              as List<dynamic>)
          .map((dynamic value) => appEntitlementFromKey(value as String))
          .whereType<AppEntitlement>()
          .toSet()
        ..add(AppEntitlement.coreFree);
      return SubscriptionState(
        providerKind: BillingProviderKind.localPreview,
        availability: BillingAvailability.preview,
        activeEntitlements: entitlements,
        catalog: _catalog,
        statusMessage: json['statusMessage'] as String?,
        lastSyncedAt: _parseDate(json['lastSyncedAt'] as String?),
      );
    } catch (_) {
      return SubscriptionState.initial(
        providerKind: BillingProviderKind.localPreview,
        catalog: _catalog,
        availability: BillingAvailability.preview,
        statusMessage:
            'Preview entitlements were reset because the local cache could not be read.',
      );
    }
  }

  Future<void> _persist(SubscriptionState state) {
    final List<String> entitlementKeys = state.activeEntitlements
        .map((AppEntitlement entitlement) => entitlement.key)
        .toList()
      ..sort();
    return _keyValueStore.writeString(
      _storageKey,
      jsonEncode(<String, Object?>{
        'entitlements': entitlementKeys,
        'statusMessage': state.statusMessage,
        'lastSyncedAt': state.lastSyncedAt?.toIso8601String(),
      }),
    );
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
