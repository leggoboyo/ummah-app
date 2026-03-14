import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart';

import '../app/app_strings.dart';
import 'quran_controller.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({
    super.key,
    required this.controller,
  });

  final QuranController controller;

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  Timer? _searchDebounce;
  Timer? _prepareTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.controller.searchQuery,
    );
    _searchFocusNode = FocusNode()
      ..addListener(() {
        if (_searchFocusNode.hasFocus) {
          _prepareTimer?.cancel();
          widget.controller.pauseBackgroundPreparation();
        } else {
          _scheduleInitialPreparation();
        }
      });
    _scheduleInitialPreparation();
  }

  @override
  void dispose() {
    _prepareTimer?.cancel();
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, _) {
        final AppStrings strings =
            AppStrings.forCode(Localizations.localeOf(context).languageCode);
        if (!widget.controller.isReady) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final List<Widget> sections = <Widget>[
          if (widget.controller.errorMessage != null)
            _MessageCard(
              title: strings.attentionNeededTitle,
              message: widget.controller.errorMessage!,
              color: Theme.of(context).colorScheme.errorContainer,
            ),
          if (widget.controller.statusMessage != null)
            _MessageCard(
              title: strings.quranSyncStatusTitle,
              message: widget.controller.statusMessage!,
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
          _SearchCard(
            controller: widget.controller,
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            onSearchChanged: _handleSearchChanged,
          ),
          if (widget.controller.searchAssistMessage != null)
            _SuggestionCard(
              controller: widget.controller,
              searchController: _searchController,
            ),
          _TranslationCard(controller: widget.controller),
          _SourcesCard(controller: widget.controller),
        ];

        if (widget.controller.searchQuery.trim().isNotEmpty) {
          sections.addAll(
            widget.controller.searchResults.map(
              (QuranSearchResult result) => _SearchResultCard(result: result),
            ),
          );
          if (widget.controller.searchResults.isEmpty) {
            sections.add(
              _InfoCard(
                title: strings.noMatchesYetTitle,
                message: strings.noMatchesYetMessage,
              ),
            );
          }
        } else {
          sections.add(
            _SurahHeaderCard(controller: widget.controller),
          );
          sections.addAll(
            widget.controller.currentAyahs.map(
              (QuranAyah ayah) => _AyahCard(ayah: ayah),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
          itemCount: sections.length,
          itemBuilder: (BuildContext context, int index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: sections[index],
          ),
        );
      },
    );
  }

  void _scheduleInitialPreparation() {
    _prepareTimer?.cancel();
    _prepareTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _searchFocusNode.hasFocus) {
        return;
      }
      widget.controller.prepareInitialExperience();
    });
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    widget.controller.pauseBackgroundPreparation();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) {
        return;
      }
      widget.controller.updateSearchQuery(value);
    });
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.controller,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
  });

  final QuranController controller;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings =
        AppStrings.forCode(Localizations.localeOf(context).languageCode);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _QuranSectionHeader(
              title: strings.quranReaderTitle,
              subtitle: strings.quranSearchHelp,
              icon: Icons.auto_stories_outlined,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              decoration: InputDecoration(
                labelText: strings.quranSearchLabel,
                hintText: strings.quranSearchHint,
                border: const OutlineInputBorder(),
                suffixIcon: controller.searchQuery.isEmpty
                    ? const Icon(Icons.search)
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          controller.updateSearchQuery('');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: onSearchChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslationCard extends StatelessWidget {
  const _TranslationCard({
    required this.controller,
  });

  final QuranController controller;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings =
        AppStrings.forCode(Localizations.localeOf(context).languageCode);
    final QuranTranslationInfo? selectedTranslation =
        controller.selectedTranslation;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              strings.translationCacheTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey<String>(
                controller.selectedTranslationKey ?? 'arabic-only',
              ),
              initialValue: controller.selectedTranslationKey ?? '',
              isExpanded: true,
              decoration: InputDecoration(
                labelText: strings.translationLabel,
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(strings.arabicOnlyLabel),
                ),
                ...controller.availableTranslations.map(
                  (QuranTranslationInfo translation) =>
                      DropdownMenuItem<String>(
                    value: translation.key,
                    child: Text(
                      '${translation.title}${translation.isFullyDownloaded ? ' (downloaded)' : translation.isDownloaded ? ' (partial)' : ''}',
                    ),
                  ),
                ),
              ],
              onChanged: controller.isWorking
                  ? null
                  : (String? value) => controller.selectTranslation(value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: controller.isWorking
                      ? null
                      : () => controller.refreshTranslationCatalog(),
                  child: Text(strings.refreshCatalogLabel),
                ),
                FilledButton.tonal(
                  onPressed: controller.isWorking ||
                          controller.selectedTranslationKey == null
                      ? null
                      : () => controller.downloadFullTranslation(),
                  child: const Text('Download full translation'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  selectedTranslation == null
                      ? 'Arabic is bundled offline. Your phone-language translation will download automatically the first time you open Quran, and you can add more languages later.'
                      : '${selectedTranslation.title}\nVersion ${selectedTranslation.version}\n${selectedTranslation.attribution}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.controller,
    required this.searchController,
  });

  final QuranController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final String? suggestion = controller.suggestedQuery;
    if (suggestion == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                controller.searchAssistMessage ?? 'Did you mean "$suggestion"?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: () async {
                searchController.text = suggestion;
                searchController.selection = TextSelection.collapsed(
                  offset: suggestion.length,
                );
                await controller.useSuggestedQuery();
              },
              child: const Text('Use this'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcesCard extends StatelessWidget {
  const _SourcesCard({
    required this.controller,
  });

  final QuranController controller;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings =
        AppStrings.forCode(Localizations.localeOf(context).languageCode);
    final List<Widget> chips = controller.sourceVersions
        .map(
          (SourceVersion version) => Chip(
            label: Text(
              '${version.contentKey} ${version.version}',
            ),
          ),
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _QuranSectionHeader(
              title: strings.sourcesVersionsTitle,
              subtitle: strings.sourcesVersionsHelp,
              icon: Icons.verified_outlined,
            ),
            const SizedBox(height: 12),
            if (chips.isEmpty)
              Text(strings.noTranslationVersionsLabel)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips,
              ),
          ],
        ),
      ),
    );
  }
}

class _SurahHeaderCard extends StatelessWidget {
  const _SurahHeaderCard({
    required this.controller,
  });

  final QuranController controller;

  @override
  Widget build(BuildContext context) {
    final SurahSummary? surah = controller.selectedSurah;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DropdownButtonFormField<int>(
              key: ValueKey<int>(controller.selectedSurahNumber),
              initialValue: controller.selectedSurahNumber,
              decoration: const InputDecoration(
                labelText: 'Surah',
                border: OutlineInputBorder(),
              ),
              items: controller.surahs
                  .map(
                    (SurahSummary candidate) => DropdownMenuItem<int>(
                      value: candidate.number,
                      child: Text(
                        '${candidate.number}. ${candidate.transliteration}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: controller.isWorking
                  ? null
                  : (int? value) {
                      if (value != null) {
                        controller.selectSurah(value);
                      }
                    },
            ),
            if (surah != null) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  surah.arabicName,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Chip(label: Text(surah.englishName)),
                  Chip(label: Text('${surah.ayahCount} ayahs')),
                  Chip(label: Text(surah.revelationType)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    required this.ayah,
  });

  final QuranAyah ayah;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _AyahTag(
              label: '${ayah.surahNumber}:${ayah.ayahNumber}',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                ayah.arabicText,
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (ayah.translationText != null &&
                ayah.translationText!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                ayah.translationText!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            if (ayah.footnotes != null &&
                ayah.footnotes!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                ayah.footnotes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.result,
  });

  final QuranSearchResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _AyahTag(
              label:
                  '${result.surahNumber}:${result.ayahNumber} • ${result.surahEnglishName}',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                result.arabicText,
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (result.translationText != null &&
                result.translationText!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(result.translationText!),
            ],
            if (result.footnotes != null &&
                result.footnotes!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                result.footnotes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Chip(
              label: Text(
                result.matchScope == QuranSearchScope.translation
                    ? 'Translation match'
                    : 'Arabic match',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuranSectionHeader extends StatelessWidget {
  const _QuranSectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AyahTag extends StatelessWidget {
  const _AyahTag({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
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
