import '../domain/billing_provider_kind.dart';
import '../domain/purchase_result.dart';
import '../domain/subscription_product.dart';
import '../domain/subscription_state.dart';
import 'default_subscription_catalog.dart';
import 'subscription_provider.dart';

class CatalogOnlySubscriptionProvider implements SubscriptionProvider {
  CatalogOnlySubscriptionProvider({
    required BillingProviderKind providerKind,
    required String unavailableMessage,
    List<SubscriptionProduct>? catalog,
  })  : _providerKind = providerKind,
        _unavailableMessage = unavailableMessage,
        _catalog = catalog ?? buildDefaultSubscriptionCatalog();

  final BillingProviderKind _providerKind;
  final String _unavailableMessage;
  final List<SubscriptionProduct> _catalog;

  @override
  Future<SubscriptionState> initialize() async => _state();

  @override
  Future<PurchaseResult> purchase(String productId) async {
    final SubscriptionState state = _state();
    return PurchaseResult(
      status: PurchaseStatus.unavailable,
      state: state,
      message: _unavailableMessage,
    );
  }

  @override
  Future<SubscriptionState> refresh() async => _state();

  @override
  Future<PurchaseResult> restorePurchases() async {
    final SubscriptionState state = _state();
    return PurchaseResult(
      status: PurchaseStatus.unavailable,
      state: state,
      message: _unavailableMessage,
    );
  }

  SubscriptionState _state() {
    return SubscriptionState.initial(
      providerKind: _providerKind,
      catalog: _catalog,
      availability: BillingAvailability.unavailable,
      statusMessage: _unavailableMessage,
    );
  }
}
