import 'package:core/core.dart';

import 'billing_provider_kind.dart';
import 'subscription_product.dart';

class SubscriptionState {
  const SubscriptionState({
    required this.providerKind,
    required this.availability,
    required this.activeEntitlements,
    required this.catalog,
    required this.statusMessage,
    this.lastSyncedAt,
  });

  factory SubscriptionState.initial({
    required BillingProviderKind providerKind,
    required List<SubscriptionProduct> catalog,
    required BillingAvailability availability,
    String? statusMessage,
  }) {
    return SubscriptionState(
      providerKind: providerKind,
      availability: availability,
      activeEntitlements: const <AppEntitlement>{AppEntitlement.coreFree},
      catalog: catalog,
      statusMessage: statusMessage,
    );
  }

  final BillingProviderKind providerKind;
  final BillingAvailability availability;
  final Set<AppEntitlement> activeEntitlements;
  final List<SubscriptionProduct> catalog;
  final String? statusMessage;
  final DateTime? lastSyncedAt;

  SubscriptionState copyWith({
    BillingProviderKind? providerKind,
    BillingAvailability? availability,
    Set<AppEntitlement>? activeEntitlements,
    List<SubscriptionProduct>? catalog,
    String? statusMessage,
    DateTime? lastSyncedAt,
  }) {
    return SubscriptionState(
      providerKind: providerKind ?? this.providerKind,
      availability: availability ?? this.availability,
      activeEntitlements: activeEntitlements ?? this.activeEntitlements,
      catalog: catalog ?? this.catalog,
      statusMessage: statusMessage ?? this.statusMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
