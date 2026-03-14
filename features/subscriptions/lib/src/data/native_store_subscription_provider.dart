import '../domain/billing_provider_kind.dart';
import 'catalog_only_subscription_provider.dart';

class NativeStoreSubscriptionProvider extends CatalogOnlySubscriptionProvider {
  NativeStoreSubscriptionProvider()
      : super(
          providerKind: BillingProviderKind.nativeStores,
          unavailableMessage:
              'Native App Store and Play billing adapters are defined architecturally, but not connected in this build yet.',
        );
}
