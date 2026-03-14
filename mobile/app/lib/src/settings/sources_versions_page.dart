import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:scholar_feed/scholar_feed.dart';

import '../bootstrap/app_controller.dart';
import 'settings_controller.dart';

class SourcesAndVersionsScreen extends StatefulWidget {
  const SourcesAndVersionsScreen({
    super.key,
    required this.appController,
  });

  final AppController appController;

  @override
  State<SourcesAndVersionsScreen> createState() =>
      _SourcesAndVersionsScreenState();
}

class _SourcesAndVersionsScreenState extends State<SourcesAndVersionsScreen> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController(
      preferredLanguageCode: widget.appController.languageCode,
    );
    Future<void>.microtask(_controller.initialize);
  }

  @override
  void dispose() {
    unawaited(_controller.close());
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sources & Versions'),
            actions: <Widget>[
              IconButton(
                onPressed: _controller.isWorking ? null : _controller.refresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh metadata',
              ),
            ],
          ),
          body: !_controller.isReady
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: <Widget>[
                    if (_controller.errorMessage != null) ...<Widget>[
                      _MessageCard(
                        title: 'Attention needed',
                        message: _controller.errorMessage!,
                        color: Theme.of(context).colorScheme.errorContainer,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _MessageCard(
                      title: 'How to read this page',
                      message:
                          'Source text is stored verbatim. Version labels come from the original provider or bundled asset metadata. If a provider does not expose a finer version number yet, the app records the best public version line available.',
                      color: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    const SizedBox(height: 12),
                    _InstalledPacksCard(
                      appController: widget.appController,
                      installedPacks: _controller.installedContentPacks,
                    ),
                    const SizedBox(height: 12),
                    const _ProjectSourceDirectoryCard(),
                    const SizedBox(height: 12),
                    _SourceSection(
                      title: 'Quran',
                      emptyMessage:
                          'Only the bundled Arabic text is guaranteed until you cache translations.',
                      versions: _controller.quranSourceVersions,
                    ),
                    const SizedBox(height: 12),
                    _SourceSection(
                      title: 'Hadith',
                      emptyMessage:
                          'No hadith content has been cached yet on this device.',
                      versions: _controller.hadithSourceVersions,
                    ),
                    const SizedBox(height: 12),
                    _SourceSection(
                      title: 'Fiqh knowledge pack',
                      emptyMessage:
                          'The bundled fiqh knowledge pack metadata is not available yet.',
                      versions: _controller.fiqhSourceVersions,
                    ),
                    const SizedBox(height: 12),
                    _ScholarFeedSection(controller: _controller),
                  ],
                ),
        );
      },
    );
  }
}

class _SourceSection extends StatelessWidget {
  const _SourceSection({
    required this.title,
    required this.emptyMessage,
    required this.versions,
  });

  final String title;
  final String emptyMessage;
  final List<SourceVersion> versions;

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
            if (versions.isEmpty)
              Text(emptyMessage)
            else
              for (final SourceVersion version in versions) ...<Widget>[
                _SourceVersionTile(version: version),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _SourceVersionTile extends StatelessWidget {
  const _SourceVersionTile({
    required this.version,
  });

  final SourceVersion version;

  @override
  Widget build(BuildContext context) {
    final _ProviderMetadata metadata =
        _providerMetadataFor(version.providerKey);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Chip(label: Text(version.providerKey)),
              Chip(label: Text(version.languageCode.toUpperCase())),
              Chip(label: Text(version.version)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Provider: ${metadata.label}'),
          const SizedBox(height: 4),
          Text('Content key: ${version.contentKey}'),
          const SizedBox(height: 4),
          Text('Attribution: ${version.attribution}'),
          const SizedBox(height: 4),
          Text('Homepage: ${metadata.homepageUrl}'),
          if (metadata.docsUrl != null) ...<Widget>[
            const SizedBox(height: 4),
            Text('Docs/API: ${metadata.docsUrl}'),
          ],
          if (metadata.reuseNote != null) ...<Widget>[
            const SizedBox(height: 4),
            Text('Reuse note: ${metadata.reuseNote}'),
          ],
          if (version.lastSyncedAt != null) ...<Widget>[
            const SizedBox(height: 4),
            Text('Last sync: ${_formatDateTime(version.lastSyncedAt!)}'),
          ],
        ],
      ),
    );
  }
}

class _ScholarFeedSection extends StatelessWidget {
  const _ScholarFeedSection({
    required this.controller,
  });

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final List<ScholarFeedSource> followedSources =
        controller.followedScholarSources;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Scholar Feed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              controller.scholarFeedLastSyncedAt == null
                  ? 'No feed metadata has been synced yet on this device.'
                  : 'Last sync: ${_formatDateTime(controller.scholarFeedLastSyncedAt!)}',
            ),
            const SizedBox(height: 8),
            Text('Cached items: ${controller.scholarFeedCachedItemCount}'),
            const SizedBox(height: 8),
            Text(
              'Followed sources: ${followedSources.isEmpty ? 'None yet' : followedSources.length}',
            ),
            const SizedBox(height: 8),
            const Text(
              'Source policy: feed items are not rewritten. The app stores metadata locally and links back to the publisher feed and site.',
            ),
            if (followedSources.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              for (final ScholarFeedSource source
                  in followedSources) ...<Widget>[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          Chip(label: Text(source.languageCode.toUpperCase())),
                          Chip(label: Text(source.category.name)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        source.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      SelectableText(source.feedUrl),
                      const SizedBox(height: 4),
                      SelectableText(source.siteUrl),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectSourceDirectoryCard extends StatelessWidget {
  const _ProjectSourceDirectoryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text(
              'Project source directory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text(
              'Quran Arabic: Tanzil Project (bundled, verbatim)',
            ),
            Text(
              'Quran translations: QuranEnc API (downloaded on demand, stored locally verbatim, version-tagged)',
            ),
            Text(
              'Sunni hadith: HadeethEnc official language packs (installed for offline use, stored verbatim)',
            ),
            Text(
              'Shia hadith: not shipped yet until licensed content is secured',
            ),
            Text(
              'Scholar feed: IslamHouse public RSS feeds (metadata cached, content linked out)',
            ),
            Text(
              'Fiqh starter pack: curated internal starter pack with cited references and explicit non-fatwa disclaimer',
            ),
          ],
        ),
      ),
    );
  }
}

class _InstalledPacksCard extends StatelessWidget {
  const _InstalledPacksCard({
    required this.appController,
    required this.installedPacks,
  });

  final AppController appController;
  final List<InstalledContentPack> installedPacks;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Installed content packs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Setup preset: ${appController.startupSelection.preset.name}. Wi‑Fi only: ${appController.startupSelection.wifiOnlyDownloads ? 'on' : 'off'}. Storage saver: ${appController.startupSelection.storageSaverMode ? 'on' : 'off'}.',
            ),
            const SizedBox(height: 12),
            if (installedPacks.isEmpty)
              const Text('Only the bundled core is installed right now.')
            else
              for (final InstalledContentPack pack
                  in installedPacks) ...<Widget>[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          Chip(label: Text(pack.module.name)),
                          if (pack.languageCode != null)
                            Chip(label: Text(pack.languageCode!.toUpperCase())),
                          Chip(label: Text(pack.version)),
                          Chip(label: Text(pack.installState.name)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pack.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      if (pack.providerKey != null)
                        Text('Provider: ${pack.providerKey}'),
                      if (pack.installedAt != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                            'Installed: ${_formatDateTime(pack.installedAt!)}'),
                      ],
                      if (pack.lastUsedAt != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text('Last used: ${_formatDateTime(pack.lastUsedAt!)}'),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Estimated device use: ${_formatBytes(pack.installedSizeBytes)}',
                      ),
                    ],
                  ),
                ),
              ],
            if (appController
                .startupSelection.deferredPackIds.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Deferred until later',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              for (final String packId
                  in appController.startupSelection.deferredPackIds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $packId'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.message,
    required this.color,
  });

  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: ListTile(
        title: Text(title),
        subtitle: Text(message),
      ),
    );
  }
}

class _ProviderMetadata {
  const _ProviderMetadata({
    required this.label,
    required this.homepageUrl,
    this.docsUrl,
    this.reuseNote,
  });

  final String label;
  final String homepageUrl;
  final String? docsUrl;
  final String? reuseNote;
}

_ProviderMetadata _providerMetadataFor(String providerKey) {
  switch (providerKey.toLowerCase()) {
    case 'quranenc':
      return const _ProviderMetadata(
        label: 'QuranEnc',
        homepageUrl: 'https://quranenc.com',
        docsUrl: 'https://quranenc.com/api/v1/docs',
        reuseNote:
            'Translations are stored verbatim and version-tagged locally.',
      );
    case 'tanzil':
      return const _ProviderMetadata(
        label: 'Tanzil Project',
        homepageUrl: 'https://tanzil.net',
        docsUrl: 'https://tanzil.net/download/',
        reuseNote:
            'Bundled Arabic text is kept verbatim from the bundled source asset.',
      );
    case 'hadeethenc':
      return const _ProviderMetadata(
        label: 'HadeethEnc',
        homepageUrl: 'https://hadeethenc.com/en/home',
        docsUrl: 'https://documenter.getpostman.com/view/5211979/TVev3j7q',
        reuseNote:
            'Hadith text is stored verbatim from official HadeethEnc packs or public source data.',
      );
    case 'fiqh_pack':
      return const _ProviderMetadata(
        label: 'Fiqh starter pack',
        homepageUrl: 'Local bundled data pack',
        reuseNote:
            'Internal starter pack with cited references. Not a fatwa service.',
      );
    default:
      return const _ProviderMetadata(
        label: 'Bundled or provider-managed source',
        homepageUrl: 'URL not recorded yet',
      );
  }
}

String _formatDateTime(DateTime value) {
  final DateTime local = value.toLocal();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _formatBytes(int bytes) {
  if (bytes >= 1000000) {
    return '${(bytes / 1000000).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1000) {
    return '${(bytes / 1000).toStringAsFixed(0)} KB';
  }
  return '$bytes B';
}
