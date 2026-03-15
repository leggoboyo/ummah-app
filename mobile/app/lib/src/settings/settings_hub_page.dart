import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../bootstrap/app_controller.dart';
import 'data_privacy_page.dart';
import 'diagnostics_page.dart';
import 'sources_versions_page.dart';

class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({
    super.key,
    required this.appController,
  });

  final AppController appController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appController,
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Trust & support',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Build ${appController.environment.buildLabel}. Billing is ${appController.billingAvailability.label.toLowerCase()}, notifications are ${appController.notificationHealth?.status.name ?? 'unknown'}, and analytics stay disabled in this build.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.speed_outlined,
                title: 'Performance mode',
                subtitle:
                    'Current mode: ${_performanceLabel(appController.uiPerformanceModeOverride, appController.uiPerformanceMode)}.',
                onTap: () async {
                  await _showPerformanceModePicker(
                    context,
                    appController,
                  );
                },
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Data & Privacy',
                subtitle:
                    'See what stays on your device, what ever leaves it, and review the offline-first privacy posture.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => DataPrivacyScreen(
                        appController: appController,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.verified_outlined,
                title: 'Sources & Versions',
                subtitle:
                    'Review installed packs, Quran/hadith source metadata, attributions, and last sync state.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          SourcesAndVersionsScreen(
                        appController: appController,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.support_agent_outlined,
                title: 'Diagnostics & Support',
                subtitle:
                    'Review local logs, copy a support report, and clear the diagnostics history on this device.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => DiagnosticsScreen(
                        appController: appController,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static String _performanceLabel(
    UiPerformanceMode? overrideMode,
    UiPerformanceMode resolvedMode,
  ) {
    if (overrideMode == null) {
      return 'Automatic (${resolvedMode.name})';
    }
    return overrideMode.name;
  }

  static Future<void> _showPerformanceModePicker(
    BuildContext context,
    AppController appController,
  ) async {
    final UiPerformanceMode? selected = await showModalBottomSheet<UiPerformanceMode?>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        final UiPerformanceMode? currentOverride =
            appController.uiPerformanceModeOverride;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _PerformanceModeTile(
                title: 'Automatic',
                subtitle:
                    'Use lean mode on lower-end Android devices and standard mode elsewhere.',
                selected: currentOverride == null,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              _PerformanceModeTile(
                title: 'Standard',
                subtitle: 'Use the full visual layout on this device.',
                selected: currentOverride == UiPerformanceMode.standard,
                onTap: () {
                  Navigator.of(context).pop(UiPerformanceMode.standard);
                },
              ),
              _PerformanceModeTile(
                title: 'Lean',
                subtitle:
                    'Prefer lighter visuals and lower runtime cost on this device.',
                selected: currentOverride == UiPerformanceMode.lean,
                onTap: () {
                  Navigator.of(context).pop(UiPerformanceMode.lean);
                },
              ),
            ],
          ),
        );
      },
    );

    if (selected == appController.uiPerformanceModeOverride) {
      return;
    }
    await appController.updateUiPerformanceModeOverride(selected);
  }
}

class _PerformanceModeTile extends StatelessWidget {
  const _PerformanceModeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
