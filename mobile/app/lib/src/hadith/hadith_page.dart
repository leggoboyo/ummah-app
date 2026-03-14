import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:hadith/hadith.dart';
import 'package:url_launcher/url_launcher.dart';

import 'hadith_controller.dart';

class HadithLibraryScreen extends StatefulWidget {
  const HadithLibraryScreen({
    super.key,
    required this.preferredLanguageCode,
    required this.hasPremiumLanguageAccess,
    required this.startupSelection,
    required this.appUserId,
    this.refreshPackAccess,
  });

  final String preferredLanguageCode;
  final bool hasPremiumLanguageAccess;
  final StartupSelection startupSelection;
  final String appUserId;
  final Future<void> Function()? refreshPackAccess;

  @override
  State<HadithLibraryScreen> createState() => _HadithLibraryScreenState();
}

class _HadithLibraryScreenState extends State<HadithLibraryScreen> {
  late final HadithController _controller;
  late final TextEditingController _searchController;
  bool _dismissedPackChooser = false;

  @override
  void initState() {
    super.initState();
    _controller = HadithController(
      hasPremiumLanguageAccess: widget.hasPremiumLanguageAccess,
      startupSelection: widget.startupSelection,
      appUserId: widget.appUserId,
      refreshPackAccess: widget.refreshPackAccess,
    );
    _searchController = TextEditingController();
    Future<void>.microtask(
      () => _controller.initialize(
        preferredLanguageCode: widget.preferredLanguageCode,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Hadith Finder'),
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
                        color: colorScheme.errorContainer,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_controller.statusMessage != null) ...<Widget>[
                      _MessageCard(
                        title: 'Hadith pack status',
                        message: _controller.statusMessage!,
                        color: colorScheme.secondaryContainer,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _HeroCard(
                      hasInstalledPack: _controller.hasInstalledPack,
                      activePack: _controller.activeInstalledPack,
                    ),
                    const SizedBox(height: 12),
                    if (_controller.shouldShowPackChooser &&
                        !_dismissedPackChooser) ...<Widget>[
                      _PackChooserCard(
                        controller: _controller,
                        onChooseAnotherLanguage: _showPackPicker,
                        onNotNow: () {
                          setState(() {
                            _dismissedPackChooser = true;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_controller.installedPacks.isNotEmpty) ...<Widget>[
                      _InstalledPackCard(
                        controller: _controller,
                        onChooseAnotherLanguage: _showPackPicker,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _SearchCard(
                      controller: _controller,
                      searchController: _searchController,
                    ),
                    const SizedBox(height: 12),
                    if (_controller.isUsingFallbackLanguage)
                      const _InfoCard(
                        title: 'Showing fallback results',
                        message:
                            'No local-language offline matches were found, so the finder is showing English Sunni Hadith results instead.',
                      ),
                    if (_controller.searchQuery.trim().length >= 2 &&
                        _controller.searchResults.isEmpty)
                      _NoResultsCard(controller: _controller),
                    if (_controller.searchResults.isNotEmpty)
                      ..._controller.searchResults.map(
                        (HadithFinderResult result) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FinderResultCard(
                            result: result,
                            onTap: () => _openHadithDetail(result.result),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _ShiaPlaceholderCard(controller: _controller),
                    const SizedBox(height: 12),
                    _SourcesCard(controller: _controller),
                    const SizedBox(height: 12),
                    const _SafetyFooterCard(),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _openHadithDetail(HadithSearchResult result) async {
    final HadithDetail? detail = await _controller.loadHadithDetail(
      languageCode: result.languageCode,
      hadithId: result.id,
    );
    if (!mounted || detail == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => HadithDetailScreen(detail: detail),
      ),
    );
  }

  Future<void> _showPackPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Choose a Sunni Hadith pack',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.hasPremiumLanguageAccess
                      ? 'You can install any HadeethEnc language pack available in this build.'
                      : 'Your recommended pack stays free. Extra languages are part of Hadith Plus.',
                ),
                const SizedBox(height: 16),
                for (final HadithPackManifest pack
                    in _controller.availablePacks)
                  _PackOptionTile(
                    pack: pack,
                    isInstalled: _controller.isPackInstalled(pack.languageCode),
                    isRecommended: _controller.recommendedPack?.languageCode ==
                        pack.languageCode,
                    canInstall: _controller.canInstallPack(pack),
                    hasUpdate:
                        _controller.isPackUpdateAvailable(pack.languageCode),
                    onTap: () async {
                      if (!_controller.canInstallPack(pack)) {
                        Navigator.of(context).pop();
                        return;
                      }
                      Navigator.of(context).pop();
                      await _controller.installPack(pack.languageCode);
                      if (mounted) {
                        setState(() {
                          _dismissedPackChooser = false;
                        });
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HadithDetailScreen extends StatelessWidget {
  const HadithDetailScreen({
    super.key,
    required this.detail,
  });

  final HadithDetail detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hadith detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    detail.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      Chip(label: Text(detail.languageCode.toUpperCase())),
                      Chip(label: Text(detail.grade)),
                      const Chip(label: Text('Sunni Hadith (HadeethEnc)')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    detail.hadithText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Explanation'),
              subtitle: Text(detail.explanation),
            ),
          ),
          if (detail.benefits.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Lessons and benefits',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    for (final String benefit in detail.benefits)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• $benefit'),
                      ),
                  ],
                ),
              ),
            ),
          if (detail.wordsMeaningsArabic.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Key word meanings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    for (final String entry in detail.wordsMeaningsArabic)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(entry),
                      ),
                  ],
                ),
              ),
            ),
          Card(
            child: ListTile(
              title: const Text('Arabic text'),
              subtitle: Text(
                detail.hadithArabic,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Source reference'),
              subtitle: Text(
                detail.sourceReference.isEmpty
                    ? 'HadeethEnc.com'
                    : detail.sourceReference,
              ),
            ),
          ),
          if (detail.sourceUrl.isNotEmpty)
            Card(
              child: ListTile(
                title: const Text('Original source URL'),
                subtitle: Text(detail.sourceUrl),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openSourceUrl(detail.sourceUrl),
              ),
            ),
          const _SafetyFooterCard(),
        ],
      ),
    );
  }

  Future<void> _openSourceUrl(String rawUrl) async {
    final Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.hasInstalledPack,
    required this.activePack,
  });

  final bool hasInstalledPack;
  final HadithPackInstall? activePack;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorScheme.primary.withValues(alpha: 0.95),
            const Color(0xFF2C8B6C),
            const Color(0xFF8FAE72),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'SUNNI HADITH',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ask about a use case',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              hasInstalledPack
                  ? 'Search your installed HadeethEnc pack offline for cited hadith, explanations, and practical match reasons.'
                  : 'Install one Sunni HadeethEnc language pack first, then search offline by use case instead of browsing categories.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
            ),
            if (activePack != null) ...<Widget>[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Chip(
                    label: Text(
                      activePack!.languageName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Chip(
                    label: Text('${activePack!.recordCount} hadith'),
                  ),
                  Chip(label: Text('v${activePack!.version}')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PackChooserCard extends StatelessWidget {
  const _PackChooserCard({
    required this.controller,
    required this.onChooseAnotherLanguage,
    required this.onNotNow,
  });

  final HadithController controller;
  final VoidCallback onChooseAnotherLanguage;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final HadithPackManifest? recommended = controller.recommendedPack;
    if (recommended == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Pick your first Sunni Hadith pack',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Recommended for this phone: ${recommended.languageName}. Download it once to keep Hadith Finder available offline.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    recommended.languageName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${recommended.recordCount} hadith • ${_formatPackSize(recommended.packSizeBytes)} • HadeethEnc v${recommended.version}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recommended.isStarterFreeEligible
                        ? 'This starter pack is free, downloaded on demand, and searched fully on-device.'
                        : 'This pack is downloaded on demand and searched fully on-device.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton(
                  onPressed: controller.isWorking
                      ? null
                      : controller.installRecommendedPack,
                  child: Text(
                    'Download ${recommended.languageName}',
                  ),
                ),
                FilledButton.tonal(
                  onPressed:
                      controller.isWorking ? null : onChooseAnotherLanguage,
                  child: const Text('Choose another language'),
                ),
                TextButton(
                  onPressed: onNotNow,
                  child: const Text('Not now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InstalledPackCard extends StatelessWidget {
  const _InstalledPackCard({
    required this.controller,
    required this.onChooseAnotherLanguage,
  });

  final HadithController controller;
  final VoidCallback onChooseAnotherLanguage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Installed Sunni Hadith packs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: controller.installedPacks.map((HadithPackInstall pack) {
                final bool isActive =
                    controller.activeLanguageCode == pack.languageCode;
                final bool hasUpdate =
                    controller.isPackUpdateAvailable(pack.languageCode);
                return ChoiceChip(
                  label: Text(
                    hasUpdate
                        ? '${pack.languageName} • update'
                        : '${pack.languageName} • ${pack.sourceType}',
                  ),
                  selected: isActive,
                  onSelected: (_) => controller.setActiveLanguageCode(
                    pack.languageCode,
                  ),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text(
              controller.hasPremiumLanguageAccess
                  ? 'You can install more language packs any time.'
                  : 'Your recommended language stays free. Hadith Plus unlocks the extra language packs.',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonal(
                    onPressed:
                        controller.isWorking ? null : onChooseAnotherLanguage,
                    child: const Text('Manage language packs'),
                  ),
                  FilledButton.tonal(
                    onPressed: controller.isWorking ||
                            controller.activeInstalledPack == null
                        ? null
                        : () => controller.removePack(
                              controller.activeInstalledPack!.languageCode,
                            ),
                    child: const Text('Remove active pack'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.controller,
    required this.searchController,
  });

  final HadithController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final HadithPackInstall? activePack = controller.activeInstalledPack;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Ask about a use case',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              activePack == null
                  ? 'Install a Sunni Hadith pack first, then describe a topic like caring for parents, honesty in trade, or controlling anger.'
                  : 'Searching ${activePack.languageName} offline right now. The finder ranks exact text, explanations, benefits, and related terms.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              enabled: controller.hasInstalledPack,
              decoration: InputDecoration(
                labelText: 'Ask about a use case',
                hintText: 'Try anger, parents, trade, mercy, prayer',
                border: const OutlineInputBorder(),
                suffixIcon: controller.searchQuery.isEmpty
                    ? const Icon(Icons.search)
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          unawaited(controller.updateSearchQuery(''));
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: controller.updateSearchQuery,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsCard extends StatelessWidget {
  const _NoResultsCard({
    required this.controller,
  });

  final HadithController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'No offline matches yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              controller.suggestedQuery == null
                  ? 'Try a shorter phrase, a clearer topic, or install another language pack.'
                  : 'No exact offline match was found. Try the suggested phrase instead.',
            ),
            if (controller.suggestedQuery != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: controller.applySuggestedQuery,
                child: Text('Did you mean "${controller.suggestedQuery}"?'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinderResultCard extends StatelessWidget {
  const _FinderResultCard({
    required this.result,
    required this.onTap,
  });

  final HadithFinderResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final HadithSearchResult data = result.result;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                data.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Chip(label: Text(data.languageCode.toUpperCase())),
                  Chip(label: Text(data.grade)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                data.hadithText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (data.matchReasons.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'Why this matched',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                for (final String reason in data.matchReasons.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $reason'),
                  ),
              ],
              if (data.sourceReference.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  data.sourceReference,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiaPlaceholderCard extends StatelessWidget {
  const _ShiaPlaceholderCard({
    required this.controller,
  });

  final HadithController controller;

  @override
  Widget build(BuildContext context) {
    final ShiaHadithPackAvailability? availability =
        controller.shiaAvailability;
    return Card(
      child: ListTile(
        title: const Text('Shia Hadith pack'),
        subtitle: Text(
          availability?.message ??
              'Shia Hadith Pack is coming. It depends on licensed content.',
        ),
        trailing: const Chip(label: Text('Coming soon')),
      ),
    );
  }
}

class _SourcesCard extends StatelessWidget {
  const _SourcesCard({
    required this.controller,
  });

  final HadithController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Sources and pack versions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sunni Hadith Finder uses official HadeethEnc language packs stored verbatim on-device. Packs are downloaded remotely, validated locally, and searched without model-generated answer text.',
            ),
            const SizedBox(height: 12),
            if (controller.sourceVersions.isEmpty)
              const Text(
                  'No Hadith packs have been installed on this device yet.')
            else
              for (final SourceVersion version in controller.sourceVersions)
                _HadithSourceVersionCard(
                  version: version,
                  install: _matchingInstall(
                    controller.installedPacks,
                    version.languageCode,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

HadithPackInstall? _matchingInstall(
  List<HadithPackInstall> installs,
  String languageCode,
) {
  for (final HadithPackInstall install in installs) {
    if (install.languageCode == languageCode) {
      return install;
    }
  }
  return null;
}

class _HadithSourceVersionCard extends StatelessWidget {
  const _HadithSourceVersionCard({
    required this.version,
    required this.install,
  });

  final SourceVersion version;
  final HadithPackInstall? install;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Chip(label: Text(version.providerKey)),
              Chip(label: Text(version.languageCode.toUpperCase())),
              Chip(label: Text(version.version)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Content key: ${version.contentKey}'),
          const SizedBox(height: 4),
          Text('Attribution: ${version.attribution}'),
          if (install != null) ...<Widget>[
            const SizedBox(height: 4),
            Text('Delivery: ${install!.sourceType} pack'),
            const SizedBox(height: 4),
            Text(
              'Archive version: ${install!.archiveVersion ?? install!.version}',
            ),
            if (install!.lastValidatedAt != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Validated: ${_formatDate(install!.lastValidatedAt!)}',
              ),
            ],
          ],
          if (version.lastSyncedAt != null) ...<Widget>[
            const SizedBox(height: 4),
            Text('Installed: ${_formatDate(version.lastSyncedAt!)}'),
          ],
        ],
      ),
    );
  }
}

class _SafetyFooterCard extends StatelessWidget {
  const _SafetyFooterCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('Safety'),
        subtitle: const Text(
          'This finder shows cited hadith and explanations. It is not a fatwa service. For context-heavy questions, ask a qualified scholar.',
        ),
      ),
    );
  }
}

class _PackOptionTile extends StatelessWidget {
  const _PackOptionTile({
    required this.pack,
    required this.isInstalled,
    required this.isRecommended,
    required this.canInstall,
    required this.hasUpdate,
    required this.onTap,
  });

  final HadithPackManifest pack;
  final bool isInstalled;
  final bool isRecommended;
  final bool canInstall;
  final bool hasUpdate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(pack.languageName),
      subtitle: Text(
        '${pack.recordCount} hadith • ${_formatPackSize(pack.packSizeBytes)} • v${pack.version}${pack.requiredEntitlementKey == null ? '' : ' • Hadith Plus'}',
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (isRecommended) const Chip(label: Text('Recommended')),
          if (hasUpdate) const Chip(label: Text('Update')),
          if (!canInstall) const Icon(Icons.lock_outline),
          if (isInstalled) const Icon(Icons.check_circle_outline),
        ],
      ),
      onTap: onTap,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(message),
      ),
    );
  }
}

String _formatPackSize(int bytes) {
  final double mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(1)} MB';
}

String _formatDate(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
