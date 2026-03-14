import 'package:flutter/material.dart';

import '../bootstrap/app_controller.dart';

class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({
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
            title: const Text('Data & Privacy'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: SwitchListTile(
                  value: appController.analyticsEnabled,
                  onChanged: (bool value) =>
                      appController.updateAnalyticsEnabled(value),
                  title: const Text('Privacy analytics opt-in'),
                  subtitle: const Text(
                    'Off by default. No analytics SDK is connected in this build today. This setting is stored now so analytics can stay consent-based later.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _SectionCard(
                title: 'Stored locally on this device',
                lines: <String>[
                  'Prayer settings, fiqh profile, language, manual coordinates, notification preferences, and analytics opt-in.',
                  'Prayer notification planning state and notification health snapshots.',
                  'Quran Arabic text plus any translations you explicitly cache for offline use.',
                  'Hadith categories and hadith text you explicitly download for offline use.',
                  'Fiqh checklist progress, scholar-feed follow choices, and local diagnostics logs.',
                  'Your OpenAI API key, if you enable BYOK, is stored in secure OS storage.',
                ],
              ),
              const SizedBox(height: 12),
              const _SectionCard(
                title: 'Sent over the network only when you ask',
                lines: <String>[
                  'QuranEnc requests when you refresh the translation catalog or download translations.',
                  'HadeethEnc requests when you refresh hadith categories or download hadith content.',
                  'IslamHouse public feed requests when you refresh followed scholar feeds.',
                  'OpenAI requests only when you open AI Assistant and submit a question with BYOK enabled.',
                ],
              ),
              const SizedBox(height: 12),
              const _SectionCard(
                title: 'Never required for the free core',
                lines: <String>[
                  'No account is required for prayer times, adhan notifications, qibla bearing, or the base Quran reader.',
                  'No ads are shown in the free prayer and notification core.',
                  'No cloud sync is required for the free tier.',
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('Current privacy posture'),
                  subtitle: Text(
                    'Location mode: ${appController.locationMode.name}. Billing: ${appController.billingAvailability.label}. Analytics: ${appController.analyticsEnabled ? 'enabled' : 'disabled'}.',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final String line in lines) ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: Icon(Icons.circle, size: 8),
                  ),
                  Expanded(child: Text(line)),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
