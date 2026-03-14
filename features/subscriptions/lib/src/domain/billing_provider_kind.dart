enum BillingProviderKind {
  localPreview,
  revenueCat,
  nativeStores;

  String get label {
    switch (this) {
      case BillingProviderKind.localPreview:
        return 'Local preview';
      case BillingProviderKind.revenueCat:
        return 'RevenueCat';
      case BillingProviderKind.nativeStores:
        return 'Native store billing';
    }
  }
}

enum BillingAvailability {
  preview,
  configured,
  unavailable;

  String get label {
    switch (this) {
      case BillingAvailability.preview:
        return 'Preview';
      case BillingAvailability.configured:
        return 'Ready';
      case BillingAvailability.unavailable:
        return 'Not configured';
    }
  }
}
