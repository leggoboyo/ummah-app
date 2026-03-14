import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer/prayer.dart';
import 'package:subscriptions/subscriptions.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_environment.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_profile.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_support_report_builder.dart';

void main() {
  test('redacted support report hides identifiers and coordinates', () async {
    const AppSupportReportBuilder builder = AppSupportReportBuilder();
    final AppProfile profile = AppProfile.defaults();

    final String report = await builder.build(
      environment: const AppEnvironment(
        flavor: AppFlavor.staging,
        hostedAiEnabled: false,
        entitlementProvider: EntitlementProviderMode.preview,
        apiBaseUrl: '',
        revenueCatAndroidPublicSdkKey: '',
        revenueCatIosPublicSdkKey: '',
      ),
      profile: profile,
      entitlements: const <AppEntitlement>{AppEntitlement.coreFree},
      billingProviderKind: BillingProviderKind.revenueCat,
      billingAvailability: BillingAvailability.unavailable,
      subscriptionStatusMessage: 'Preview mode',
      notificationHealth: const NotificationHealth(
        status: NotificationHealthStatus.healthy,
        message: 'Ready.',
      ),
      locationSummary: 'Using Chicago (CST) at 41.8781, -87.6298',
      activeCoordinates: const Coordinates(
        latitude: 41.8781,
        longitude: -87.6298,
      ),
      activeTimeZoneOffset: const Duration(hours: -5),
      revenueCatAppUserId: 'ummah_0123456789abcdef0123456789abcdef',
      entries: <AppLogEntry>[
        AppLogEntry(
          level: AppLogLevel.info,
          message:
              'Synced at 41.8781, -87.6298 for ummah_0123456789abcdef0123456789abcdef',
          timestamp: DateTime(2026, 3, 14),
        ),
      ],
      includeSensitiveDetails: false,
    );

    expect(report.contains('ummah_0123456789abcdef0123456789abcdef'), isFalse);
    expect(report.contains('41.8781, -87.6298'), isFalse);
    expect(report.contains('Redacted in the standard support report.'), isTrue);
  });
}
