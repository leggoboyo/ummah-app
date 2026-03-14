import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/errors.dart' as rc_errors;
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:subscriptions/subscriptions.dart';

import 'app_environment.dart';
import 'app_identity_store.dart';

class RevenueCatMobileSubscriptionProvider implements SubscriptionProvider {
  RevenueCatMobileSubscriptionProvider({
    required AppEnvironment environment,
    required AppIdentityStore identityStore,
    List<SubscriptionProduct>? catalog,
  })  : _environment = environment,
        _identityStore = identityStore,
        _catalog = catalog ?? buildDefaultSubscriptionCatalog();

  final AppEnvironment _environment;
  final AppIdentityStore _identityStore;
  final List<SubscriptionProduct> _catalog;

  bool _isConfigured = false;

  @override
  Future<SubscriptionState> initialize() async {
    try {
      await _configureIfNeeded();
      return _buildState(
        await rc.Purchases.getCustomerInfo(),
        statusMessage: 'RevenueCat is connected for this build.',
      );
    } catch (error) {
      return _unavailableState(
        'RevenueCat could not initialize on this device yet: $error',
      );
    }
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    try {
      await _configureIfNeeded();
      final rc.StoreProduct? product = await _findStoreProduct(productId);
      if (product == null) {
        final SubscriptionState state = await refresh();
        return PurchaseResult(
          status: PurchaseStatus.unavailable,
          state: state,
          message:
              'That store product is not available yet. Finish Play Console and RevenueCat product setup first.',
        );
      }

      final rc.PurchaseResult purchase = await rc.Purchases.purchase(
        rc.PurchaseParams.storeProduct(product),
      );
      final SubscriptionState state = _buildState(
        purchase.customerInfo,
        statusMessage:
            'Purchase completed through RevenueCat for ${product.identifier}.',
      );
      return PurchaseResult(
        status: PurchaseStatus.success,
        state: state,
        message: state.statusMessage!,
      );
    } on PlatformException catch (error) {
      final rc_errors.PurchasesErrorCode errorCode =
          rc_errors.PurchasesErrorHelper.getErrorCode(error);
      final SubscriptionState state = await refresh();
      return PurchaseResult(
        status: errorCode == rc_errors.PurchasesErrorCode.purchaseCancelledError
            ? PurchaseStatus.cancelled
            : PurchaseStatus.failed,
        state: state,
        message: _messageForPlatformException(error, errorCode),
      );
    } catch (error) {
      final SubscriptionState state = await refresh();
      return PurchaseResult(
        status: PurchaseStatus.failed,
        state: state,
        message: 'Purchase failed: $error',
      );
    }
  }

  @override
  Future<SubscriptionState> refresh() async {
    try {
      await _configureIfNeeded();
      return _buildState(
        await rc.Purchases.getCustomerInfo(),
        statusMessage: 'RevenueCat customer info refreshed.',
      );
    } catch (error) {
      return _unavailableState(
        'RevenueCat refresh failed: $error',
      );
    }
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    try {
      await _configureIfNeeded();
      final rc.CustomerInfo info = await rc.Purchases.restorePurchases();
      final SubscriptionState state = _buildState(
        info,
        statusMessage: 'Purchases restored from RevenueCat.',
      );
      return PurchaseResult(
        status: PurchaseStatus.success,
        state: state,
        message: state.statusMessage!,
      );
    } on PlatformException catch (error) {
      final rc_errors.PurchasesErrorCode errorCode =
          rc_errors.PurchasesErrorHelper.getErrorCode(error);
      final SubscriptionState state = await refresh();
      return PurchaseResult(
        status: errorCode == rc_errors.PurchasesErrorCode.purchaseCancelledError
            ? PurchaseStatus.cancelled
            : PurchaseStatus.failed,
        state: state,
        message: _messageForPlatformException(error, errorCode),
      );
    } catch (error) {
      final SubscriptionState state = await refresh();
      return PurchaseResult(
        status: PurchaseStatus.failed,
        state: state,
        message: 'Restore failed: $error',
      );
    }
  }

  Future<void> _configureIfNeeded() async {
    if (_isConfigured || await rc.Purchases.isConfigured) {
      _isConfigured = true;
      return;
    }

    final String apiKey = _platformApiKey;
    if (apiKey.isEmpty) {
      throw StateError(
        'No RevenueCat public SDK key is configured for ${Platform.operatingSystem}.',
      );
    }

    final String appUserId = await _identityStore.ensureRevenueCatAppUserId();
    final rc.PurchasesConfiguration configuration =
        rc.PurchasesConfiguration(apiKey)
          ..appUserID = appUserId
          ..diagnosticsEnabled = false;
    await rc.Purchases.configure(configuration);
    _isConfigured = true;
  }

  String get _platformApiKey {
    if (Platform.isAndroid) {
      return _environment.revenueCatAndroidPublicSdkKey;
    }
    if (Platform.isIOS) {
      return _environment.revenueCatIosPublicSdkKey;
    }
    return '';
  }

  Future<rc.StoreProduct?> _findStoreProduct(String productId) async {
    final SubscriptionProduct? catalogProduct = _catalogProduct(productId);
    if (catalogProduct == null) {
      return null;
    }

    final rc.ProductCategory category =
        catalogProduct.kind == SubscriptionProductKind.subscription
            ? rc.ProductCategory.subscription
            : rc.ProductCategory.nonSubscription;
    final List<rc.StoreProduct> products = await rc.Purchases.getProducts(
      <String>[productId],
      productCategory: category,
    );
    if (products.isEmpty) {
      return null;
    }
    return products.first;
  }

  SubscriptionProduct? _catalogProduct(String productId) {
    for (final SubscriptionProduct product in _catalog) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  SubscriptionState _buildState(
    rc.CustomerInfo info, {
    required String statusMessage,
  }) {
    final Set<AppEntitlement> activeEntitlements = info.entitlements.active.keys
        .map(appEntitlementFromKey)
        .whereType<AppEntitlement>()
        .toSet()
      ..add(AppEntitlement.coreFree);

    return SubscriptionState(
      providerKind: BillingProviderKind.revenueCat,
      availability: BillingAvailability.configured,
      activeEntitlements: activeEntitlements,
      catalog: _catalog,
      statusMessage: statusMessage,
      lastSyncedAt: DateTime.now(),
    );
  }

  SubscriptionState _unavailableState(String message) {
    return SubscriptionState.initial(
      providerKind: BillingProviderKind.revenueCat,
      catalog: _catalog,
      availability: BillingAvailability.unavailable,
      statusMessage: message,
    ).copyWith(lastSyncedAt: DateTime.now());
  }

  String _messageForPlatformException(
    PlatformException error,
    rc_errors.PurchasesErrorCode errorCode,
  ) {
    switch (errorCode) {
      case rc_errors.PurchasesErrorCode.purchaseCancelledError:
        return 'Purchase cancelled.';
      case rc_errors.PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'That product is not available in the current store configuration yet.';
      case rc_errors.PurchasesErrorCode.networkError:
      case rc_errors.PurchasesErrorCode.offlineConnectionError:
        return 'Network connection is required to complete store purchases.';
      case rc_errors.PurchasesErrorCode.invalidCredentialsError:
      case rc_errors.PurchasesErrorCode.configurationError:
        return 'RevenueCat store configuration is incomplete: ${error.message ?? error.details ?? error.code}';
      default:
        return error.message ?? 'Store purchase failed with ${errorCode.name}.';
    }
  }
}
