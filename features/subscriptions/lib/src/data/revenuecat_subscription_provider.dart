import '../domain/billing_provider_kind.dart';
import 'catalog_only_subscription_provider.dart';

class RevenueCatSubscriptionProvider extends CatalogOnlySubscriptionProvider {
  RevenueCatSubscriptionProvider()
      : super(
          providerKind: BillingProviderKind.revenueCat,
          unavailableMessage:
              'RevenueCat is the planned billing provider, but store products and SDK keys have not been connected in this build yet.',
        );
}
