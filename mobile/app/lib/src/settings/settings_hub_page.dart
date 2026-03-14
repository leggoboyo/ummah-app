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
