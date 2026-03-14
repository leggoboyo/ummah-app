enum AppFlavor {
  dev,
  staging,
  prod;

  String get label {
    switch (this) {
      case AppFlavor.dev:
        return 'Dev';
      case AppFlavor.staging:
        return 'Staging';
      case AppFlavor.prod:
        return 'Production';
    }
  }
}

enum EntitlementProviderMode {
  preview,
  revenueCat,
  none;

  String get label {
    switch (this) {
      case EntitlementProviderMode.preview:
        return 'Preview';
      case EntitlementProviderMode.revenueCat:
        return 'RevenueCat';
      case EntitlementProviderMode.none:
        return 'Disabled';
    }
  }
}

class AppEnvironment {
  const AppEnvironment({
    required this.flavor,
    required this.hostedAiEnabled,
    required this.entitlementProvider,
    required this.apiBaseUrl,
    required this.revenueCatAndroidPublicSdkKey,
    required this.revenueCatIosPublicSdkKey,
  });

  factory AppEnvironment.fromCompileTime() {
    return AppEnvironment(
      flavor: _parseFlavor(
        const String.fromEnvironment('appFlavor', defaultValue: 'dev'),
      ),
      hostedAiEnabled:
          const bool.fromEnvironment('hostedAiEnabled', defaultValue: false),
      entitlementProvider: _parseEntitlementProvider(
        const String.fromEnvironment(
          'entitlementProvider',
          defaultValue: 'preview',
        ),
      ),
      apiBaseUrl: const String.fromEnvironment('apiBaseUrl', defaultValue: ''),
      revenueCatAndroidPublicSdkKey: const String.fromEnvironment(
        'revenueCatAndroidPublicSdkKey',
        defaultValue: '',
      ),
      revenueCatIosPublicSdkKey: const String.fromEnvironment(
        'revenueCatIosPublicSdkKey',
        defaultValue: '',
      ),
    );
  }

  final AppFlavor flavor;
  final bool hostedAiEnabled;
  final EntitlementProviderMode entitlementProvider;
  final String apiBaseUrl;
  final String revenueCatAndroidPublicSdkKey;
  final String revenueCatIosPublicSdkKey;

  bool get isProduction => flavor == AppFlavor.prod;

  bool get showBuildBanner => !isProduction;

  bool get hasRevenueCatKey =>
      revenueCatAndroidPublicSdkKey.isNotEmpty ||
      revenueCatIosPublicSdkKey.isNotEmpty;

  String get buildLabel {
    if (apiBaseUrl.isEmpty) {
      return flavor.label;
    }
    return '${flavor.label} • API';
  }

  static AppFlavor _parseFlavor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'prod':
      case 'production':
        return AppFlavor.prod;
      case 'staging':
        return AppFlavor.staging;
      case 'dev':
      default:
        return AppFlavor.dev;
    }
  }

  static EntitlementProviderMode _parseEntitlementProvider(String value) {
    switch (value.trim().toLowerCase()) {
      case 'revenuecat':
        return EntitlementProviderMode.revenueCat;
      case 'none':
        return EntitlementProviderMode.none;
      case 'preview':
      default:
        return EntitlementProviderMode.preview;
    }
  }
}
