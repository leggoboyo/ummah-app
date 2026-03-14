import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:prayer/prayer.dart';
import 'package:qibla/qibla.dart';
import 'package:subscriptions/subscriptions.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app_environment.dart';
import 'app_profile.dart';
import 'app_profile_store.dart';
import 'device_location_service.dart';
import 'diagnostics_logger.dart';
import 'local_notifications_service.dart';
import 'manual_location_preset.dart';
import 'revenuecat_mobile_subscription_provider.dart';
import 'shared_preferences_key_value_store.dart';

class AppController extends ChangeNotifier {
  AppController({
    AppProfileStore? profileStore,
    DeviceLocationService? locationService,
    PrayerNotificationsService? notificationsService,
    PrayerTimeCalculator? prayerTimeCalculator,
    QiblaCalculator? qiblaCalculator,
    AppEnvironment? environment,
    DiagnosticsLogger? logger,
    SubscriptionRepository? subscriptionRepository,
  })  : _profileStore = profileStore ?? SharedPreferencesAppProfileStore(),
        _environment = environment ?? AppEnvironment.fromCompileTime(),
        _logger = logger ?? _buildDiagnosticsLogger(),
        _locationService =
            locationService ?? const GeolocatorDeviceLocationService(),
        _notificationsService =
            notificationsService ?? LocalPrayerNotificationsService(),
        _prayerTimeCalculator =
            prayerTimeCalculator ?? const PrayerTimeCalculator(),
        _qiblaCalculator = qiblaCalculator ?? const QiblaCalculator(),
        _subscriptionRepository = subscriptionRepository ??
            SubscriptionRepository(
              provider: _buildSubscriptionProvider(
                environment ?? AppEnvironment.fromCompileTime(),
              ),
            );

  final AppProfileStore _profileStore;
  final AppEnvironment _environment;
  final DiagnosticsLogger _logger;
  final DeviceLocationService _locationService;
  final PrayerNotificationsService _notificationsService;
  final PrayerTimeCalculator _prayerTimeCalculator;
  final QiblaCalculator _qiblaCalculator;
  final SubscriptionRepository _subscriptionRepository;

  AppProfile _profile = AppProfile.defaults();
  Coordinates? _resolvedCoordinates;
  NotificationSyncResult? _notificationSyncResult;
  SubscriptionState? _subscriptionState;
  String _locationMessage =
      'Manual coordinates are active until setup is complete.';

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
    await _notificationsService.initialize();
    _profile = await _profileStore.load();
    await _initializeSubscriptions();

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
      'App bootstrap completed. Onboarding complete: ${_profile.onboardingComplete}.',
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
      final SubscriptionState state = await _subscriptionRepository.refresh();
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
  }) async {
    isWorking = true;
    notifyListeners();
    bannerMessage = null;

    try {
      _profile = _profile.copyWith(
        onboardingComplete: true,
        languageCode: selectedLanguageCode,
        fiqhProfile: selectedFiqhProfile,
        calculationMethod: selectedMethod,
        locationMode: selectedLocationMode,
        manualLocationId: selectedManualLocationId,
        manualLocationLabel: selectedManualLocationLabel,
        manualTimeZoneId: selectedManualTimeZoneId,
        manualCoordinates: selectedManualCoordinates,
        preciseAndroidAlarms: preciseAndroidAlarms,
        quranStartupMode: selectedQuranStartupMode,
      );

      await _profileStore.save(_profile);
      await _refreshCoreState(
        requestPermissions: true,
        requestLocationPermission:
            selectedLocationMode == AppLocationMode.device,
      );
      await _logger.log(
        AppLogLevel.info,
        'Onboarding completed with ${selectedFiqhProfile.label}, ${selectedMethod.name}, and ${selectedLocationMode.name} location mode.',
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
        'Using ${closestPreset.label} (${_timeZoneDescriptionForDate(closestPreset.timeZoneId, DateTime.now())}) for manual prayer times.';
    bannerMessage = null;
    await _profileStore.save(_profile);
    if (_profile.onboardingComplete) {
      await _syncNotifications(requestPermissions: false);
    }
    await _logger.log(
      AppLogLevel.info,
      'Manual coordinates updated to ${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}.',
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
        'Using ${preset.label} (${_timeZoneDescriptionForDate(preset.timeZoneId, DateTime.now())}) for manual prayer times.';
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
    if (_profile.locationMode == AppLocationMode.manual) {
      _resolvedCoordinates = _profile.manualCoordinates;
      _locationMessage =
          'Using ${_profile.manualLocationLabel} (${_timeZoneDescriptionForDate(_profile.manualTimeZoneId, DateTime.now())}) for manual prayer times.';
      return;
    }

    final DeviceLocationResult result = await _locationService.resolve(
      requestPermission: requestPermission,
    );

    if (result.coordinates != null) {
      _resolvedCoordinates = result.coordinates;
      _locationMessage = result.message;
      bannerMessage = null;
      return;
    }

    _resolvedCoordinates = _profile.manualCoordinates;
    _locationMessage = result.message;
    bannerMessage = result.message;
  }

  Future<void> _syncNotifications({
    required bool requestPermissions,
  }) async {
    if (!_profile.onboardingComplete) {
      return;
    }

    _notificationSyncResult = await _notificationsService.syncPrayerSchedule(
      now: DateTime.now(),
      settings: prayerSettingsFor(DateTime.now()),
      preferences: notificationPreferences,
      calculatePrayerDay: prayerDayFor,
      coordinates: activeCoordinates,
      requestPermissions: requestPermissions,
    );
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

  Future<void> _initializeSubscriptions() async {
    final SubscriptionState state = await _subscriptionRepository.initialize();
    _applySubscriptionState(state);
  }

  void _applySubscriptionState(SubscriptionState state) {
    _subscriptionState = state;
    _entitlements = <AppEntitlement>{
      AppEntitlement.coreFree,
      ...state.activeEntitlements,
    };
  }

  Future<void> updateAnalyticsEnabled(bool enabled) async {
    _profile = _profile.copyWith(analyticsEnabled: enabled);
    await _profileStore.save(_profile);
    await _logger.log(
      AppLogLevel.info,
      'Privacy analytics opt-in changed to $enabled.',
    );
    notifyListeners();
  }

  Future<List<AppLogEntry>> loadDiagnosticsEntries() {
    return _logger.entries();
  }

  Future<void> clearDiagnosticsEntries() async {
    await _logger.clear();
  }

  Future<String> buildDiagnosticsReport() async {
    final List<AppLogEntry> entries = await _logger.entries();
    final List<String> lines = <String>[
      'Ummah App Support Report',
      'Generated: ${DateTime.now().toIso8601String()}',
      'Build: ${_environment.buildLabel}',
      'Hosted AI enabled: ${_environment.hostedAiEnabled}',
      'API base URL: ${_environment.apiBaseUrl.isEmpty ? 'Not set' : _environment.apiBaseUrl}',
      'Language: ${_profile.languageCode}',
      'Fiqh profile: ${_profile.fiqhProfile.label}',
      'Calculation method: ${_profile.calculationMethod.name}',
      'Location mode: ${_profile.locationMode.name}',
      'Manual location: ${_profile.manualLocationLabel}',
      'Manual time zone: ${_profile.manualTimeZoneId}',
      'Manual coordinates: ${_profile.manualCoordinates.latitude.toStringAsFixed(4)}, ${_profile.manualCoordinates.longitude.toStringAsFixed(4)}',
      'Quran startup mode: ${_profile.quranStartupMode.name}',
      'Analytics enabled: ${_profile.analyticsEnabled}',
      'Adhan sound: ${_profile.adhanSoundKey}',
      'Billing provider: ${billingProviderKind.label}',
      'Billing availability: ${billingAvailability.label}',
      'Billing status: ${subscriptionStatusMessage ?? 'No status yet'}',
      'Notification health: ${notificationHealth?.status.name ?? 'unknown'}',
      'Notification message: ${notificationHealth?.message ?? 'No message yet'}',
      'Resolved location: $locationSummary',
      'Active coordinates: ${activeCoordinates.latitude.toStringAsFixed(4)}, ${activeCoordinates.longitude.toStringAsFixed(4)}',
      'Active time zone offset: ${activeTimeZoneOffset.inMinutes} minutes',
      'Entitlements: ${entitlements.map((AppEntitlement entitlement) => entitlement.key).toList()..sort()}',
      '',
      'Local log entries (${entries.length}):',
    ];

    for (final AppLogEntry entry in entries) {
      lines.add(
        '- ${entry.timestamp.toIso8601String()} [${entry.level.name}] ${entry.message}',
      );
      if (entry.error != null) {
        lines.add('  error: ${entry.error}');
      }
      if (entry.stackTrace != null) {
        lines.add('  stack: ${entry.stackTrace}');
      }
    }

    return lines.join('\n');
  }

  static SubscriptionProvider _buildSubscriptionProvider(
    AppEnvironment environment,
  ) {
    switch (environment.entitlementProvider) {
      case EntitlementProviderMode.preview:
        return LocalPreviewSubscriptionProvider(
          keyValueStore: SharedPreferencesKeyValueStore(),
        );
      case EntitlementProviderMode.revenueCat:
        return RevenueCatMobileSubscriptionProvider(
          environment: environment,
        );
      case EntitlementProviderMode.none:
        return CatalogOnlySubscriptionProvider(
          providerKind: BillingProviderKind.revenueCat,
          unavailableMessage:
              'Billing is intentionally disabled in this build flavor.',
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

  String _timeZoneDescriptionForDate(String timeZoneId, DateTime date) {
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

  void _ensureTimeZonesReady() {
    if (_timeZonesReady) {
      return;
    }
    tz_data.initializeTimeZones();
    _timeZonesReady = true;
  }
}
