import '../domain/purchase_result.dart';
import '../domain/subscription_state.dart';

abstract interface class SubscriptionProvider {
  Future<SubscriptionState> initialize();

  Future<SubscriptionState> refresh();

  Future<PurchaseResult> purchase(String productId);

  Future<PurchaseResult> restorePurchases();
}
