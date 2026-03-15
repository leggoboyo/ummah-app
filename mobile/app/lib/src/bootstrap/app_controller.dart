import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:prayer/prayer.dart';
import 'package:qibla/qibla.dart';
import 'package:subscriptions/subscriptions.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app_environment.dart';
import 'app_identity_store.dart';
import 'app_location_resolver.dart';
import 'app_location_state.dart';
import 'app_notification_sync_service.dart';
import 'app_profile.dart';
import 'app_profile_store.dart';
import 'app_support_report_builder.dart';
import 'device_capabilities_service.dart';
import 'device_location_service.dart';
import 'diagnostics_logger.dart';
import 'local_notifications_service.dart';
import 'manual_location_preset.dart';
import 'revenuecat_mobile_subscription_provider.dart';
import 'shared_preferences_key_value_store.dart';

class AppController extends ChangeNotifier {
  static const Set<String> _supportedLanguageCodes = <String>{
    'en',
    'ar',
    'ur',
  };

  AppController({
    AppProfileStore? profileStore,
    DeviceLocationService? locationService,
    PrayerNotificationsService? notificationsService,
    PrayerTimeCalculator? prayerTimeCalculator,
    QiblaCalculator? qiblaCalculator,
    AppEnvironment? environment,
    AppIdentityStore? identityStore,
    DiagnosticsLogger? logger,
    SubscriptionRepository? subscriptionRepository,
    AppLocationResolver? locationResolver,
    AppNotificationSyncService? notificationSyncService,
    AppSupportReportBuilder? supportReportBuilder,
    AppModuleRegistry? moduleRegistry,
    DeviceCapabilitiesService? deviceCapabilitiesService,
  })  : _profileStore = profileStore ?? SharedPreferencesAppProfileStore(),
        _environment = environment ?? AppEnvironment.fromCompileTime(),
        _identityStore = identityStore ?? SecureAppIdentityStore(),
        _logger = logger ?? _buildDiagnosticsLogger(),
        _deviceCapabilitiesService = deviceCapabilitiesService ??
            MethodChannelDeviceCapabilitiesService(),
        _locationResolver = locationResolver ??
            AppLocationResolver(
              locationService:
                  locationService ?? const GeolocatorDeviceLocationService(),
              describeTimeZone: _describeTimeZoneForDate,
            ),
        _notificationSyncService = notificationSyncService ??
            AppNotificationSyncService(
              notificationsService:
                  notificationsService ?? LocalPrayerNotificationsService(),
            ),
        _prayerTimeCalculator =
            prayerTimeCalculator ?? const PrayerTimeCalculator(),
        _qiblaCalculator = qiblaCalculator ?? const QiblaCalculator(),
        _supportReportBuilder =
            supportReportBuilder ?? const AppSupportReportBuilder(),
        _moduleRegistry = moduleRegistry ?? buildDefaultAppModuleRegistry(),
        _subscriptionRepository = subscriptionRepository ??
            SubscriptionRepository(
              provider: _buildSubscriptionProvider(
                environment ?? AppEnvironment.fromCompileTime(),
                identityStore ?? SecureAppIdentityStore(),
              ),
            ) {
    _applySubscriptionState(_initialSubscriptionStateFor(_environment));
  }

  final AppProfileStore _profileStore;
  final AppEnvironment _environment;
  final AppIdentityStore _identityStore;
  final DiagnosticsLogger _logger;
  final DeviceCapabilitiesService _deviceCapabilitiesService;
  final AppLocationResolver _locationResolver;
  final AppNotificationSyncService _notificationSyncService;
  final PrayerTimeCalculator _prayerTimeCalculator;
  final QiblaCalculator _qiblaCalculator;
  final AppSupportReportBuilder _supportReportBuilder;
  final AppModuleRegistry _moduleRegistry;
  final SubscriptionRepository _subscriptionRepository;

  AppProfile _profile = AppProfile.defaults();
  DeviceCapabilities _deviceCapabilities = const DeviceCapabilities();
  Coordinates? _resolvedCoordinates;
  NotificationSyncResult? _notificationSyncResult;
  SubscriptionState? _subscriptionState;
  String _locationMessage =
      'Manual coordinates are active until setup is complete.';
  String? _revenueCatAppUserId;
  bool _subscriptionsLoaded = false;

  bool isReady = false;
  bool isWorking = false;
  String? bannerMessage;

  static bool _timeZonesReady = false;

  Set<AppEntitlement> _entitlements = <AppEntitlement>{
    AppEntitlement.coreFree,
  };

  AppProfile get profile => _profile;

  AppEnvironment get environment => _environment;

  Set<AppEntitlement> get entitlements =>
      Set<AppEntitlement>.unmodifiable(_entitlements);

  AppModuleRegistry get moduleRegistry => _moduleRegistry;

  bool get onboardingComplete => _profile.onboardingComplete;

  String get languageCode => _profile.languageCode;

  bool get analyticsEnabled => _profile.analyticsEnabled;

  FiqhProfile get fiqhProfile => _profile.fiqhProfile;

  PrayerCalculationMethod get calculationMethod => _profile.calculationMethod;

  Coordinates get manualCoordinates => _profile.manualCoordinates;

  AppLocationMode get locationMode => _profile.locationMode;

  String get manualLocationLabel => _profile.manualLocationLabel;

  String get manualTimeZoneId => _profile.manualTimeZoneId;

  QuranStartupMode get quranStartupMode => _profile.quranStartupMode;

  StartupSelection get startupSelection => _profile.startupSelection;

  Coordinates get activeCoordinates =>
      _resolvedCoordinates ?? _profile.manualCoordinates;

  Duration get activeTimeZoneOffset =>
      _profile.locationMode == AppLocationMode.manual
          ? _timeZoneOffsetForDate(_profile.manualTimeZoneId, DateTime.now())
          : DateTime.now().timeZoneOffset;

  String get locationSummary => _locationMessage;

  NotificationHealth? get notificationHealth => _notificationSyncResult?.health;

  AndroidAlarmDecision? get androidAlarmDecision =>
      _notificationSyncResult?.androidAlarmDecision;

  SubscriptionState? get subscriptionState => _subscriptionState;

  List<SubscriptionProduct> get subscriptionCatalog =>
      _subscriptionState?.catalog ?? const <SubscriptionProduct>[];

  BillingProviderKind get billingProviderKind =>
      _subscriptionState?.providerKind ?? BillingProviderKind.revenueCat;

  BillingAvailability get billingAvailability =>
      _subscriptionState?.availability ?? BillingAvailability.unavailable;

  String? get subscriptionStatusMessage => _subscriptionState?.statusMessage;

  DateTime? get entitlementSyncTime => _subscriptionState?.lastSyncedAt;

  String? get revenueCatAppUserId => _revenueCatAppUserId;

  int? get androidSdkInt => _deviceCapabilities.androidSdkInt;

  bool get isLowRamDevice => _deviceCapabilities.isLowRamDevice;

  UiPerformanceMode? get uiPerformanceModeOverride =>
      _profile.uiPerformanceModeOverride;

  UiPerformanceMode get uiPerformanceMode {
    final UiPerformanceMode? override = _profile.uiPerformanceModeOverride;
    if (override != null) {
      return override;
    }
    final int? sdkInt = _deviceCapabilities.androidSdkInt;
    if ((sdkInt != null && sdkInt <= 26) ||
        _deviceCapabilities.isLowRamDevice) {
      return UiPerformanceMode.lean;
    }
    return UiPerformanceMode.standard;
  }

  PrayerNotificationPreferences get notificationPreferences =>
      PrayerNotificationPreferences(
        preciseAndroidAlarms: _profile.preciseAndroidAlarms,
        soundKey: _profile.adhanSoundKey,
      );

  PrayerSettings get prayerSettings => prayerSettingsFor(DateTime.now());

  PrayerSettings prayerSettingsFor(DateTime date) =>
      PrayerSettings.withDefaultMethod(
        fiqhProfile: _profile.fiqhProfile,
        method: _profile.calculationMethod,
        timeZoneOffset: _profile.locationMode == AppLocationMode.manual
            ? _timeZoneOffsetForDate(_profile.manualTimeZoneId, date)
            : date.toLocal().timeZoneOffset,
      );

  Future<void> initialize() async {
    await _logger.log(
      AppLogLevel.info,
      'App bootstrap started for ${_environment.buildLabel}.',
    );
    await _notificationSyncService.initialize();
    _revenueCatAppUserId = await _identityStore.readRevenueCatAppUserId();
    final AppProfile loadedProfile = await _profileStore.load();
    _profile = _sanitizeProfile(loadedProfile);
    if (_profile.languageCode != loadedProfile.languageCode) {
      await _profileStore.save(_profile);
    }
    _deviceCapabilities = await _deviceCapabilitiesService.readCapabilities();

    if (_profile.onboardingComplete) {
      await _refreshCoreState(
        requestPermissions: false,
        requestLocationPermission: false,
      );
    } else {
      _resolvedCoordinates = _profile.manualCoordinates;
      _locationMessage =
          'Manual coordinates are pre-filled for onboarding and can be changed before you continue.';
    }

    isReady = true;
    await _logger.log(
      AppLogLevel.info,
      'App bootstrap completed. Onboarding complete: ${_profile.onboardingComplete}. UI mode: ${uiPerformanceMode.name}.',
    );
    notifyListeners();
  }

  PrayerDay prayerDayFor(DateTime date) {
    return _prayerTimeCalculator.calculate(
      date: date,
      coordinates: activeCoordinates,
      settings: prayerSettingsFor(date),
    );
  }

  PrayerName? nextPrayer(DateTime now) {
    return prayerDayFor(now).nextPrayerAfter(now);
  }

  QiblaDirection get qiblaDirection =>
      _qiblaCalculator.calculate(activeCoordinates);

  bool hasAccess(AppEntitlement entitlement) {
    return hasEntitlement(_entitlements, entitlement);
  }

  SubscriptionProduct? recommendedProductFor(AppEntitlement entitlement) {
    SubscriptionProduct? featuredMatch;
    SubscriptionProduct? directMatch;
    SubscriptionProduct? bundleMatch;

    for (final SubscriptionProduct product in subscriptionCatalog) {
      if (!product.unlocks(entitlement)) {
        continue;
      }
      if (product.primaryEntitlement == entitlement) {
        directMatch ??= product;
      }
      if (product.primaryEntitlement == AppEntitlement.megaBundle) {
        bundleMatch ??= product;
      }
      if (product.isFeatured) {
        featuredMatch ??= product;
      }
    }

    return directMatch ?? featuredMatch ?? bundleMatch;
  }

  Future<PurchaseResult> purchaseProduct(String productId) async {
    isWorking = true;
    notifyListeners();
    try {
      await _ensureSubscriptionsLoaded();
      final PurchaseResult result =
          await _subscriptionRepository.purchase(productId);
      _applySubscriptionState(result.state);
      await _logger.log(
        result.status == PurchaseStatus.success
            ? AppLogLevel.info
            : AppLogLevel.warning,
        'Purchase attempt for $productId finished with ${result.status.name}.',
      );
      return result;
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> refreshEntitlements() async {
    isWorking = true;
    notifyListeners();
    try {
      final SubscriptionState state = await _loadSubscriptionState(
        forceRefresh: _subscriptionsLoaded,
      );
      _applySubscriptionState(state);
      await _logger.log(
        AppLogLevel.info,
        'Entitlements refreshed from ${state.providerKind.label}.',
      );
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<PurchaseResult> restorePurchases() async {
    isWorking = true;
    notifyListeners();
    try {
      await _ensureSubscriptionsLoaded();
      final PurchaseResult result =
          await _subscriptionRepository.restorePurchases();
      _applySubscriptionState(result.state);
      await _logger.log(
        result.status == PurchaseStatus.success
            ? AppLogLevel.info
            : AppLogLevel.warning,
        'Restore purchases finished with ${result.status.name}.',
      );
      return result;
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> loadBillingStateIfNeeded() async {
    if (_subscriptionsLoaded) {
      return;
    }
    final SubscriptionState state = await _loadSubscriptionState();
    _applySubscriptionState(state);
    notifyListeners();
  }

  Future<String> ensureAppUserId() async {
    final String appUserId = _revenueCatAppUserId ??
        await _identityStore.ensureRevenueCatAppUserId();
    if (_revenueCatAppUserId != appUserId) {
      _revenueCatAppUserId = appUserId;
      notifyListeners();
    }
    return appUserId;
  }

  Future<void> completeOnboarding({
    required String selectedLanguageCode,
    required FiqhProfile selectedFiqhProfile,
    required PrayerCalculationMethod selectedMethod,
    required AppLocationMode selectedLocationMode,
    required String selectedManualLocationId,
    required String selectedManualLocationLabel,
    required String selectedManualTimeZoneId,
    required Coordinates selectedManualCoordinates,
    required bool preciseAndroidAlarms,
    required QuranStartupMode selectedQuranStartupMode,
    required StartupSelection startupSelection,
  }) async {
    isWorking = true;
    notifyListeners();
    bannerMessage = null;

    try {
      _profile = _profile.copyWith(
        onboardingComplete: true,
        languageCode: _sanitizeLanguageCode(selectedLanguageCode),
        fiqhProfile: selectedFiqhProfile,
        calculationMethod: selectedMethod,
        locationMode: selectedLocationMode,
        manualLocationId: selectedManualLocationId,
        manualLocationLabel: selectedManualLocationLabel,
        manualTimeZoneId: selectedManualTimeZoneId,
        manualCoordinates: selectedManualCoordinates,
        preciseAndroidAlarms: preciseAndroidAlarms,
        quranStartupMode: selectedQuranStartupMode,
        startupSelection: startupSelection,
      );

      await _profileStore.save(_profile);
      await _refreshCoreState(
        requestPermissions: true,
        requestLocationPermission:
            selectedLocationMode == AppLocationMode.device,
      );
      await _logger.log(
        AppLogLevel.info,
        'Onboarding completed with ${selectedFiqhProfile.label}, ${selectedMethod.name}, ${selectedLocationMode.name} location mode, and ${startupSelection.selectedPackIds.length} selected content packs.',
      );
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> updateManualCoordinates(Coordinates coordinates) async {
    final ManualLocationPreset closestPreset =
        closestManualLocationPreset(coordinates);
    _profile = _profile.copyWith(
      locationMode: AppLocationMode.manual,
      manualLocationId: closestPreset.id,
      manualLocationLabel: closestPreset.label,
      manualTimeZoneId: closestPreset.timeZoneId,
      manualCoordinates: coordinates,
    );
    _resolvedCoordinates = coordinates;
    _locationMessage =
        'Using ${closestPreset.label} (${_describeTimeZoneForDate(closestPreset.timeZoneId, DateTime.now())}) for manual prayer times.';
    bannerMessage = null;
    await _profileStore.save(_profile);
    if (_profile.onboardingComplete) {
      await _syncNotifications(requestPermissions: false);
    }
    await _logger.log(
      AppLogLevel.info,
      'Manual coordinates updated for ${closestPreset.label}.',
    );
    notifyListeners();
  }

  Future<void> updateFiqhProfile(FiqhProfile fiqhProfile) async {
    _profile = _profile.copyWith(
      fiqhProfile: fiqhProfile,
      calculationMethod: fiqhProfile.tradition == FiqhTradition.shia
          ? PrayerCalculationMethod.jafari
          : (_profile.calculationMethod == PrayerCalculationMethod.jafari
              ? PrayerCalculationMethod.muslimWorldLeague
              : _profile.calculationMethod),
    );
    await _profileStore.save(_profile);
    if (_profile.onboardingComplete) {
      await _syncNotifications(requestPermissions: false);
    }
    await _logger.log(
      AppLogLevel.info,
      'Fiqh profile updated to ${fiqhProfile.label}.',
    );
    notifyListeners();
  }

  Future<void> updateCalculationMethod(PrayerCalculationMethod method) async {
    _profile = _profile.copyWith(calculationMethod: method);
    await _profileStore.save(_profile);
    if (_profile.onboardingComplete) {
      await _syncNotifications(requestPermissions: false);
    }
    await _logger.log(
      AppLogLevel.info,
      'Prayer calculation method updated to ${method.name}.',
    );
    notifyListeners();
  }

  Future<void> updateUiPerformanceModeOverride(
    UiPerformanceMode? override,
  ) async {
    _profile = _profile.copyWith(
      uiPerformanceModeOverride: override,
      clearUiPerformanceModeOverride: override == null,
    );
    await _profileStore.save(_profile);
    await _logger.log(
      AppLogLevel.info,
      'UI performance mode override updated to ${override?.name ?? 'auto'}.',
    );
    notifyListeners();
  }

  Future<void> updateManualLocationPreset(ManualLocationPreset preset) async {
    _profile = _profile.copyWith(
      locationMode: AppLocationMode.manual,
      manualLocationId: preset.id,
      manualLocationLabel: preset.label,
      manualTimeZoneId: preset.timeZoneId,
      manualCoordinates: preset.coordinates,
    );
    _resolvedCoordinates = preset.coordinates;
    _locationMessage =
        'Using ${preset.label} (${_describeTimeZoneForDate(preset.timeZoneId, DateTime.now())}) for manual prayer times.';
    bannerMessage = null;
    await _profileStore.save(_profile);
    if (_profile.onboardingComplete) {
      await _syncNotifications(requestPermissions: false);
    }
    await _logger.log(
      AppLogLevel.info,
      'Manual location updated to ${preset.label}.',
    );
    notifyListeners();
  }

  Future<void> updateLocationMode(AppLocationMode mode) async {
    _profile = _profile.copyWith(locationMode: mode);
    await _profileStore.save(_profile);
    if (_profile.onboardingComplete) {
      await _refreshCoreState(
        requestPermissions: mode == AppLocationMode.device,
        requestLocationPermission: mode == AppLocationMode.device,
      );
    } else {
      notifyListeners();
    }
    await _logger.log(
      AppLogLevel.info,
      'Location mode updated to ${mode.name}.',
    );
  }

  Future<void> refreshDeviceLocation() async {
    isWorking = true;
    notifyListeners();
    try {
      await _resolveLocation(requestPermission: true);
      await _syncNotifications(requestPermissions: false);
      await _logger.log(
        bannerMessage == null ? AppLogLevel.info : AppLogLevel.warning,
        'Device location refresh completed. $_locationMessage',
      );
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    isWorking = true;
    notifyListeners();
    try {
      await _syncNotifications(requestPermissions: false);
      await _logger.log(
        AppLogLevel.info,
        'Notification refresh completed with status ${notificationHealth?.status.name ?? 'unknown'}.',
      );
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> refreshForegroundReliability() async {
    if (!_profile.onboardingComplete || isWorking) {
      return;
    }
    await _refreshCoreState(
      requestPermissions: false,
      requestLocationPermission: false,
    );
    await _logger.log(
      notificationHealth?.status == NotificationHealthStatus.healthy
          ? AppLogLevel.info
          : AppLogLevel.warning,
      'Foreground reliability refresh completed. ${notificationHealth?.message ?? 'No notification health available.'}',
    );
    notifyListeners();
  }

  Future<void> _refreshCoreState({
    required bool requestPermissions,
    required bool requestLocationPermission,
  }) async {
    await _resolveLocation(requestPermission: requestLocationPermission);
    await _syncNotifications(requestPermissions: requestPermissions);
  }

  Future<void> _resolveLocation({
    required bool requestPermission,
  }) async {
    final AppLocationState locationState = await _locationResolver.resolve(
      profile: _profile,
      requestPermission: requestPermission,
    );
    _resolvedCoordinates = locationState.coordinates;
    _locationMessage = locationState.summary;
    bannerMessage = locationState.bannerMessage;
  }

  Future<void> _syncNotifications({
    required bool requestPermissions,
  }) async {
    _notificationSyncResult = await _notificationSyncService.sync(
      profile: _profile,
      now: DateTime.now(),
      settings: prayerSettingsFor(DateTime.now()),
      preferences: notificationPreferences,
      calculatePrayerDay: prayerDayFor,
      coordinates: activeCoordinates,
      requestPermissions: requestPermissions,
    );
    if (_notificationSyncResult == null) {
      return;
    }
    if (_notificationSyncResult?.notificationsEnabled == false) {
      bannerMessage = _notificationSyncResult?.health.message;
    }
    await _logger.log(
      _notificationSyncResult?.health.status == NotificationHealthStatus.healthy
          ? AppLogLevel.info
          : AppLogLevel.warning,
      'Prayer notification sync finished. ${_notificationSyncResult?.health.message ?? 'No health message returned.'}',
    );
  }

  void _applySubscriptionState(SubscriptionState state) {
    _subscriptionState = state;
    _entitlements = <AppEntitlement>{
      AppEntitlement.coreFree,
      ...state.activeEntitlements,
    };
  }

  Future<void> _ensureSubscriptionsLoaded() async {
    if (_subscriptionsLoaded) {
      return;
    }
    final SubscriptionState state = await _loadSubscriptionState();
    _applySubscriptionState(state);
  }

  Future<SubscriptionState> _loadSubscriptionState({
    bool forceRefresh = false,
  }) async {
    _revenueCatAppUserId = await _identityStore.ensureRevenueCatAppUserId();
    final SubscriptionState state = forceRefresh
        ? await _subscriptionRepository.refresh()
        : await _subscriptionRepository.initialize();
    _subscriptionsLoaded = true;
    return state;
  }

  Future<List<AppLogEntry>> loadDiagnosticsEntries() {
    return _logger.entries();
  }

  Future<void> clearDiagnosticsEntries() async {
    await _logger.clear();
  }

  Future<String> buildDiagnosticsReport({
    bool includeSensitiveDetails = false,
  }) async {
    final List<AppLogEntry> entries = await _logger.entries();
    return _supportReportBuilder.build(
      environment: _environment,
      profile: _profile,
      uiPerformanceMode: uiPerformanceMode,
      entitlements: entitlements,
      billingProviderKind: billingProviderKind,
      billingAvailability: billingAvailability,
      subscriptionStatusMessage: subscriptionStatusMessage,
      notificationHealth: notificationHealth,
      locationSummary: locationSummary,
      activeCoordinates: activeCoordinates,
      activeTimeZoneOffset: activeTimeZoneOffset,
      revenueCatAppUserId: _revenueCatAppUserId,
      entries: entries,
      includeSensitiveDetails: includeSensitiveDetails,
    );
  }

  static SubscriptionProvider _buildSubscriptionProvider(
    AppEnvironment environment,
    AppIdentityStore identityStore,
  ) {
    switch (environment.entitlementProvider) {
      case EntitlementProviderMode.preview:
        return LocalPreviewSubscriptionProvider(
          keyValueStore: SharedPreferencesKeyValueStore(),
        );
      case EntitlementProviderMode.revenueCat:
        return RevenueCatMobileSubscriptionProvider(
          environment: environment,
          identityStore: identityStore,
        );
      case EntitlementProviderMode.none:
        return CatalogOnlySubscriptionProvider(
          providerKind: BillingProviderKind.revenueCat,
          unavailableMessage:
              'Billing is intentionally disabled in this build flavor.',
        );
    }
  }

  static SubscriptionState _initialSubscriptionStateFor(
    AppEnvironment environment,
  ) {
    final List<SubscriptionProduct> catalog = buildDefaultSubscriptionCatalog();
    switch (environment.entitlementProvider) {
      case EntitlementProviderMode.preview:
        return SubscriptionState.initial(
          providerKind: BillingProviderKind.localPreview,
          catalog: catalog,
          availability: BillingAvailability.preview,
          statusMessage:
              'Preview billing stays local to this device until you open Plans & Unlocks.',
        );
      case EntitlementProviderMode.revenueCat:
        return SubscriptionState.initial(
          providerKind: BillingProviderKind.revenueCat,
          catalog: catalog,
          availability: environment.hasRevenueCatKey
              ? BillingAvailability.configured
              : BillingAvailability.unavailable,
          statusMessage: environment.hasRevenueCatKey
              ? 'Store access has not been checked on this device yet.'
              : 'Store billing is not configured for this build.',
        );
      case EntitlementProviderMode.none:
        return SubscriptionState.initial(
          providerKind: BillingProviderKind.revenueCat,
          catalog: catalog,
          availability: BillingAvailability.unavailable,
          statusMessage: 'Billing is intentionally disabled in this build.',
        );
    }
  }

  static DiagnosticsLogger _buildDiagnosticsLogger() {
    try {
      return PersistentDiagnosticsLogger();
    } on StateError {
      return InMemoryDiagnosticsLogger();
    }
  }

  AppProfile _sanitizeProfile(AppProfile profile) {
    return profile.copyWith(
      languageCode: _sanitizeLanguageCode(profile.languageCode),
    );
  }

  String _sanitizeLanguageCode(String languageCode) {
    final String normalized = languageCode.trim().toLowerCase();
    if (_supportedLanguageCodes.contains(normalized)) {
      return normalized;
    }
    return 'en';
  }

  Duration _timeZoneOffsetForDate(String timeZoneId, DateTime date) {
    _ensureTimeZonesReady();
    try {
      final tz.Location location = tz.getLocation(timeZoneId);
      return tz.TZDateTime(
        location,
        date.year,
        date.month,
        date.day,
        12,
      ).timeZoneOffset;
    } catch (_) {
      return date.toLocal().timeZoneOffset;
    }
  }

  static String _describeTimeZoneForDate(String timeZoneId, DateTime date) {
    _ensureTimeZonesReady();
    try {
      final tz.Location location = tz.getLocation(timeZoneId);
      final tz.TZDateTime zonedDate = tz.TZDateTime(
        location,
        date.year,
        date.month,
        date.day,
        12,
      );
      final Duration offset = zonedDate.timeZoneOffset;
      final String sign = offset.isNegative ? '-' : '+';
      final int totalMinutes = offset.inMinutes.abs();
      final int hours = totalMinutes ~/ 60;
      final int minutes = totalMinutes % 60;
      return '${zonedDate.timeZoneName} • UTC$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeZoneId;
    }
  }

  static void _ensureTimeZonesReady() {
    if (_timeZonesReady) {
      return;
    }
    tz_data.initializeTimeZones();
    _timeZonesReady = true;
  }
}
