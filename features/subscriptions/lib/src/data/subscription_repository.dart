import '../domain/purchase_result.dart';
import '../domain/subscription_state.dart';
import 'subscription_provider.dart';

class SubscriptionRepository {
  SubscriptionRepository({
    required SubscriptionProvider provider,
  }) : _provider = provider;

  final SubscriptionProvider _provider;

  Future<SubscriptionState> initialize() => _provider.initialize();

  Future<SubscriptionState> refresh() => _provider.refresh();

  Future<PurchaseResult> purchase(String productId) =>
      _provider.purchase(productId);

  Future<PurchaseResult> restorePurchases() => _provider.restorePurchases();
}
