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
                child: const ListTile(
                  title: Text('Analytics posture'),
                  subtitle: Text(
                    'No analytics or telemetry SDK is connected in this build. The app does not send usage tracking by default.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _SectionCard(
                title: 'Stored locally on this device',
                lines: <String>[
                  'Prayer settings, fiqh profile, language, manual coordinates, and notification preferences.',
                  'Your setup choices: which content packs to download now, which ones to defer, Wi‑Fi-only preference, and storage-saver mode.',
                  'Prayer notification planning state and notification health snapshots.',
                  'Quran Arabic text plus any translations you explicitly cache for offline use.',
                  'Installed Sunni Hadith language packs plus your offline Hadith Finder search state.',
                  'Fiqh checklist progress, scholar-feed follow choices, and local diagnostics logs.',
                  'Your OpenAI API key, if you enable BYOK, is stored in secure OS storage.',
                ],
              ),
              const SizedBox(height: 12),
              const _SectionCard(
                title: 'Sent over the network only when you ask',
                lines: <String>[
                  'QuranEnc requests when you refresh the translation catalog or when setup downloads the translation packs you selected.',
                  'HadeethEnc requests only when you install or refresh Sunni Hadith language packs that are not already on the device.',
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
                    'Location mode: ${appController.locationMode.name}. Billing: ${appController.billingAvailability.label}. Analytics SDK: disabled.',
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
