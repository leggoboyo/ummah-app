import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer/prayer.dart';
import 'package:quran/quran.dart';
import 'package:subscriptions/subscriptions.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_controller.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_environment.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_identity_store.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_profile.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_profile_store.dart';
import 'package:ummah_mobile_app/src/bootstrap/device_capabilities_service.dart';
import 'package:ummah_mobile_app/src/bootstrap/device_location_service.dart';
import 'package:ummah_mobile_app/src/bootstrap/local_notifications_service.dart';
import 'package:ummah_mobile_app/src/home/home_shell.dart';
import 'package:ummah_mobile_app/src/quran/quran_controller.dart';

void main() {
  testWidgets('Quran controller is created only when the Quran tab is opened', (
    WidgetTester tester,
  ) async {
    int quranFactoryCalls = 0;
    final AppController controller = AppController(
      environment: const AppEnvironment(
        flavor: AppFlavor.dev,
        hostedAiEnabled: false,
        entitlementProvider: EntitlementProviderMode.preview,
        apiBaseUrl: '',
        revenueCatAndroidPublicSdkKey: '',
        revenueCatIosPublicSdkKey: '',
      ),
      profileStore: InMemoryAppProfileStore(),
      identityStore: _TestAppIdentityStore(),
      subscriptionRepository: SubscriptionRepository(
        provider: LocalPreviewSubscriptionProvider(
          keyValueStore: _InMemoryKeyValueStore(),
        ),
      ),
      locationService: FakeDeviceLocationService(
        const DeviceLocationResult(
          status: DeviceLocationStatus.ready,
          message: 'Using device location.',
          coordinates: Coordinates(latitude: 41.8781, longitude: -87.6298),
        ),
      ),
      notificationsService: FakePrayerNotificationsService(
        NotificationSyncResult(
          health: const NotificationHealth(
            status: NotificationHealthStatus.healthy,
            message: 'Notifications are scheduled.',
          ),
          scheduledCount: 5,
          notificationsEnabled: true,
        ),
      ),
      deviceCapabilitiesService: _FakeDeviceCapabilitiesService(
        UiPerformanceMode.standard,
      ),
    );

    await controller.initialize();
    await controller.completeOnboarding(
      selectedLanguageCode: 'en',
      selectedFiqhProfile: const FiqhProfile(
        tradition: FiqhTradition.sunni,
        school: SchoolOfThought.hanafi,
      ),
      selectedMethod: PrayerCalculationMethod.muslimWorldLeague,
      selectedLocationMode: AppLocationMode.device,
      selectedManualLocationId: 'chicago_us',
      selectedManualLocationLabel: 'Chicago',
      selectedManualCoordinates: const Coordinates(
        latitude: 41.8781,
        longitude: -87.6298,
      ),
      selectedManualTimeZoneId: 'America/Chicago',
      preciseAndroidAlarms: true,
      selectedQuranStartupMode: QuranStartupMode.arabicOnly,
      startupSelection: AppProfile.defaults().startupSelection,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          controller: controller,
          quranControllerFactory: () {
            quranFactoryCalls += 1;
            return QuranController(
              repository: _FakeQuranRepository(),
              startupMode: QuranStartupMode.arabicOnly,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(quranFactoryCalls, 0);

    await tester.tap(find.text('Quran'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(quranFactoryCalls, 1);
  });
}

class _FakeQuranRepository extends QuranRepository {
  _FakeQuranRepository();

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<List<SurahSummary>> getSurahs() async {
    return <SurahSummary>[
      const SurahSummary(
        number: 1,
        arabicName: 'الفاتحة',
        transliteration: 'Al-Fatihah',
        englishName: 'The Opening',
        ayahCount: 7,
        revelationType: 'Meccan',
        revelationOrder: 5,
        rukus: 1,
      ),
    ];
  }

  @override
  Future<List<QuranTranslationInfo>> getLocalTranslations({
    String? languageCode,
  }) async {
    return const <QuranTranslationInfo>[];
  }

  @override
  Future<List<SourceVersion>> getSourceVersions() async {
    return <SourceVersion>[
      const SourceVersion(
        providerKey: 'tanzil',
        contentKey: 'quran_ar',
        languageCode: 'ar',
        version: '1.0.0',
        attribution: 'Tanzil Project',
      ),
    ];
  }

  @override
  Future<List<QuranAyah>> getSurahAyahs(
    int surahNumber, {
    String? translationKey,
  }) async {
    if (!_initialized) {
      throw StateError('Repository initialize should run before ayah reads.');
    }
    return <QuranAyah>[
      const QuranAyah(
        surahNumber: 1,
        ayahNumber: 1,
        arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      ),
    ];
  }
}

class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _storage = <String, String>{};

  @override
  Future<String?> readString(String key) async => _storage[key];

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    _storage[key] = value;
  }
}

class _TestAppIdentityStore implements AppIdentityStore {
  String? _appUserId;

  @override
  Future<String> ensureAppUserId() async {
    return _appUserId ??= 'ummah_test_home_shell';
  }

  @override
  Future<String> ensureRevenueCatAppUserId() {
    return ensureAppUserId();
  }

  @override
  Future<String?> readAppUserId() async => _appUserId;

  @override
  Future<String?> readRevenueCatAppUserId() async => _appUserId;
}

class _FakeDeviceCapabilitiesService extends DeviceCapabilitiesService {
  _FakeDeviceCapabilitiesService(this.mode);

  final UiPerformanceMode mode;

  @override
  Future<UiPerformanceMode> resolve({
    UiPerformanceMode? override,
  }) async {
    return override ?? mode;
  }
}
