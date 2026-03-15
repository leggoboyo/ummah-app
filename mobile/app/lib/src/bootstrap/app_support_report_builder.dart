import 'package:core/core.dart';
import 'package:prayer/prayer.dart';
import 'package:subscriptions/subscriptions.dart';

import 'app_environment.dart';
import 'app_profile.dart';
import 'diagnostics_redactor.dart';

class AppSupportReportBuilder {
  const AppSupportReportBuilder();

  Future<String> build({
    required AppEnvironment environment,
    required AppProfile profile,
    required Set<AppEntitlement> entitlements,
    required BillingProviderKind billingProviderKind,
    required BillingAvailability billingAvailability,
    required String? subscriptionStatusMessage,
    required NotificationHealth? notificationHealth,
    required String locationSummary,
    required Coordinates activeCoordinates,
    required Duration activeTimeZoneOffset,
    required String? revenueCatAppUserId,
    required List<AppLogEntry> entries,
    required bool includeSensitiveDetails,
  }) async {
    final List<String> lines = <String>[
      includeSensitiveDetails
          ? 'Ummah App Detailed Support Report'
          : 'Ummah App Support Report',
      'Generated: ${DateTime.now().toIso8601String()}',
      'Build: ${environment.buildLabel}',
      'Hosted AI enabled: ${environment.hostedAiEnabled}',
      'API base URL: ${environment.apiBaseUrl.isEmpty ? 'Not set' : environment.apiBaseUrl}',
      'Language: ${profile.languageCode}',
      'Fiqh profile: ${profile.fiqhProfile.label}',
      'Calculation method: ${profile.calculationMethod.name}',
      'Location mode: ${profile.locationMode.name}',
      'Manual location: ${profile.manualLocationLabel}',
      'Manual time zone: ${profile.manualTimeZoneId}',
      'Manual coordinates: ${DiagnosticsRedactor.formatCoordinates(profile.manualCoordinates, includeSensitiveDetails: includeSensitiveDetails)}',
      'Quran startup mode: ${profile.quranStartupMode.name}',
      'Setup preset: ${profile.startupSelection.preset.name}',
      'Selected content packs: ${profile.startupSelection.selectedPackIds}',
      'Deferred content packs: ${profile.startupSelection.deferredPackIds}',
      'Wi-Fi only downloads: ${profile.startupSelection.wifiOnlyDownloads}',
      'Storage saver mode: ${profile.startupSelection.storageSaverMode}',
      'Analytics SDK active: false',
      'Adhan sound: ${profile.adhanSoundKey}',
      'Billing provider: ${billingProviderKind.label}',
      'Billing availability: ${billingAvailability.label}',
      'Billing status: ${subscriptionStatusMessage ?? 'No status yet'}',
      'RevenueCat App User ID: ${DiagnosticsRedactor.formatIdentifier(revenueCatAppUserId, includeSensitiveDetails: includeSensitiveDetails)}',
      'Notification health: ${notificationHealth?.status.name ?? 'unknown'}',
      'Notification message: ${notificationHealth?.message ?? 'No message yet'}',
      'Notification action hint: ${notificationHealth?.actionHint ?? 'No action hint'}',
      'Notification coverage until: ${notificationHealth?.coverageUntil?.toIso8601String() ?? 'Unknown'}',
      'Resolved location: ${DiagnosticsRedactor.redactText(locationSummary)}',
      'Active coordinates: ${DiagnosticsRedactor.formatCoordinates(activeCoordinates, includeSensitiveDetails: includeSensitiveDetails)}',
      'Active time zone offset: ${activeTimeZoneOffset.inMinutes} minutes',
      'Entitlements: ${entitlements.map((AppEntitlement entitlement) => entitlement.key).toList()..sort()}',
      '',
      'Local log entries (${entries.length}):',
    ];

    for (final AppLogEntry entry in entries) {
      lines.add(
        '- ${entry.timestamp.toIso8601String()} [${entry.level.name}] ${DiagnosticsRedactor.redactText(entry.message)}',
      );
      if (entry.error != null) {
        lines.add(
          '  error: ${DiagnosticsRedactor.redactText(entry.error.toString())}',
        );
      }
      if (entry.stackTrace != null) {
        lines.add(
          '  stack: ${DiagnosticsRedactor.redactText(entry.stackTrace.toString())}',
        );
      }
    }

    return lines.join('\n');
  }
}
