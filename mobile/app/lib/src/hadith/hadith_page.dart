import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const List<String> _sampleQuestions = <String>[
    'How should I treat my parents?',
    'How do I control anger?',
    'What do hadith say about honesty?',
    'How should I seek forgiveness?',
    'What do hadith say about lowering the gaze?',
  ];

  late final HadithController _controller;
  late final TextEditingController _searchController;

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
            title: Text(
              'Hadith Finder',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            actions: <Widget>[
              if (_controller.availablePacks.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.layers_outlined),
                  tooltip: 'Choose hadith pack',
                  onSelected: (String value) async {
                    if (!value.startsWith('pack:')) {
                      return;
                    }
                    final String languageCode = value.substring(5);
                    if (_controller.isPackInstalled(languageCode)) {
                      await _controller.setActiveLanguageCode(languageCode);
                      return;
                    }
                    await _controller.installPack(languageCode);
                  },
                  itemBuilder: (BuildContext context) {
                    return _controller.availablePacks
                        .map((HadithPackManifest pack) {
                      final bool installed =
                          _controller.isPackInstalled(pack.languageCode);
                      final bool active =
                          _controller.activeLanguageCode == pack.languageCode;
                      final bool canInstall = _controller.canInstallPack(pack);
                      final bool recommended =
                          _controller.recommendedPack?.languageCode ==
                              pack.languageCode;
                      return PopupMenuItem<String>(
                        value: 'pack:${pack.languageCode}',
                        enabled: installed || canInstall,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                recommended
                                    ? '${pack.languageName} (recommended)'
                                    : pack.languageName,
                              ),
                            ),
                            if (active)
                              const Icon(Icons.check_rounded, size: 18)
                            else if (!installed && !canInstall)
                              const Icon(Icons.lock_outline, size: 18),
                          ],
                        ),
                      );
                    }).toList(growable: false);
                  },
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
                    _SearchCard(
                      controller: _controller,
                      searchController: _searchController,
                      sampleQuestions: _sampleQuestions,
                      onSampleQuestionTap: _useSampleQuestion,
                    ),
                    const SizedBox(height: 12),
                    if (_controller.latestAnswer != null &&
                        _controller.latestAnswer!.status !=
                            HadithGroundedAnswerStatus.noEvidence) ...<Widget>[
                      _GroundedAnswerCard(
                        answer: _controller.latestAnswer!,
                        primaryCitation: _controller.searchResults.isEmpty
                            ? null
                            : _controller.searchResults.first,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_controller.latestAnswer?.status ==
                        HadithGroundedAnswerStatus.noEvidence)
                      _NoResultsCard(
                        controller: _controller,
                        searchController: _searchController,
                      ),
                    if (_controller.searchResults.isNotEmpty)
                      _CitationLinksCard(
                        results: _controller.searchResults,
                        onTap: _openHadithDetail,
                      ),
                    if (_controller.hasInstalledPack) ...<Widget>[
                      const SizedBox(height: 12),
                      _MoreInfoCard(controller: _controller),
                    ],
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

  Future<void> _useSampleQuestion(String question) async {
    _searchController.value = TextEditingValue(
      text: question,
      selection: TextSelection.collapsed(offset: question.length),
    );
    _controller.updateSearchQuery(question);
    await _controller.submitSearchQuery();
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<String> narrations = _splitNarrations(detail.hadithText);
    final String sourceReference = _detailSourceReference(detail);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hadith detail',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      detail.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sourceReference,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        detail.languageCode.toUpperCase(),
                        _gradeForDisplay(detail.grade),
                      ].where((String part) => part.isNotEmpty).join(' • '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Here’s exactly what the hadith says',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: colorScheme.primaryContainer
                            .withValues(alpha: 0.42),
                      ),
                      child: Text(
                        _firstNarrationSnippet(detail.hadithText),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.55,
                            ),
                      ),
                    ),
                    if (narrations.length > 1) ...<Widget>[
                      const SizedBox(height: 14),
                      Text(
                        'Other narrations',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      for (final (int, String) narration
                          in narrations.skip(1).indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: colorScheme.surfaceContainerLowest,
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Narration ${narration.$1 + 2}',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  narration.$2,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'In plain words',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _plainWordsFromDetail(detail),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.55,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (detail.explanation.trim().isNotEmpty)
              Card(
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  title: const Text('Read the full explanation'),
                  children: <Widget>[
                    Text(
                      detail.explanation.trim(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
            if (detail.benefits.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Key takeaways',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 10),
                      for (final String benefit in detail.benefits.take(4))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• $benefit',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (detail.hadithArabic.trim().isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Arabic text',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        detail.hadithArabic.trim(),
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.9,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Verify this source',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sourceReference,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.tonalIcon(
                          onPressed: detail.sourceUrl.isEmpty
                              ? null
                              : () => _openExternalSourceUrl(detail.sourceUrl),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Open public source'),
                        ),
                        OutlinedButton.icon(
                          onPressed: detail.sourceUrl.isEmpty
                              ? null
                              : () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: detail.sourceUrl),
                                  );
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Source link copied'),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy link'),
                        ),
                      ],
                    ),
                    if (detail.sourceUrl.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      SelectableText(
                        detail.sourceUrl,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const _SafetyFooterCard(),
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
    required this.sampleQuestions,
    required this.onSampleQuestionTap,
  });

  final HadithController controller;
  final TextEditingController searchController;
  final List<String> sampleQuestions;
  final Future<void> Function(String question) onSampleQuestionTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!controller.hasInstalledPack) ...<Widget>[
              Text(
                'Use the top-right pack menu to install your first Sunni Hadith pack.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: colorScheme.surface,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      enabled: controller.hasInstalledPack,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      decoration: InputDecoration(
                        hintText: 'Ask a hadith question',
                        hintStyle:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        isCollapsed: true,
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: controller.updateSearchQuery,
                      onSubmitted: (_) => controller.submitSearchQuery(),
                    ),
                  ),
                  if (controller.searchQuery.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        searchController.clear();
                        controller.updateSearchQuery('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10, left: 4),
                    child: FilledButton(
                      onPressed: !controller.hasInstalledPack ||
                              controller.isWorking ||
                              controller.searchQuery.trim().length < 2
                          ? null
                          : controller.submitSearchQuery,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(13),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ),
                ],
              ),
            ),
            if (controller.hasInstalledPack &&
                controller.latestAnswer == null &&
                controller.searchQuery.trim().isEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'Try one',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sampleQuestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final String question = sampleQuestions[index];
                    return ActionChip(
                      label: Text(question),
                      visualDensity: VisualDensity.compact,
                      onPressed:
                          controller.isWorking || !controller.hasInstalledPack
                              ? null
                              : () => unawaited(onSampleQuestionTap(question)),
                    );
                  },
                ),
              ),
            ],
            if (controller.isWorking) ...<Widget>[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroundedAnswerCard extends StatelessWidget {
  const _GroundedAnswerCard({
    required this.answer,
    required this.primaryCitation,
  });

  final HadithGroundedAnswer answer;
  final HadithFinderResult? primaryCitation;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDirect = answer.status == HadithGroundedAnswerStatus.answered;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isDirect
                  ? 'Here’s exactly what the hadith says'
                  : 'Closest related hadith',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isDirect
                    ? colorScheme.primaryContainer.withValues(alpha: 0.42)
                    : colorScheme.secondaryContainer.withValues(alpha: 0.42),
              ),
              child: Text(
                _hadithSaysText(primaryCitation, answer),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'In plain words',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _plainWordsText(primaryCitation, answer),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
            if (answer.usedLanguageFallback) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'Using the installed English fallback pack for this answer.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _hadithSaysText(
    HadithFinderResult? primary,
    HadithGroundedAnswer answer,
  ) {
    final String text = primary?.result.hadithText.trim() ?? answer.answerText;
    return _firstNarrationSnippet(text);
  }

  String _plainWordsText(
    HadithFinderResult? primary,
    HadithGroundedAnswer answer,
  ) {
    if (answer.status == HadithGroundedAnswerStatus.related) {
      return 'I could not find a direct hadith for this exact question, but the references below are the closest matches I found.';
    }
    final String explanation = primary?.result.explanation.trim() ?? '';
    final String simplified = _simplifyExplanation(explanation);
    if (simplified.isNotEmpty) {
      return simplified;
    }
    return _clipText(answer.answerText.trim(), 180);
  }
}

class _NoResultsCard extends StatelessWidget {
  const _NoResultsCard({
    required this.controller,
    required this.searchController,
  });

  final HadithController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'No clear hadith found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'I could not find a reliable hadith in the installed packs that directly answers this question.',
            ),
            if (controller.suggestedQuery != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () {
                  final String nextQuery = controller.suggestedQuery!;
                  searchController.value = TextEditingValue(
                    text: nextQuery,
                    selection:
                        TextSelection.collapsed(offset: nextQuery.length),
                  );
                  unawaited(controller.applySuggestedQuery());
                },
                child: Text('Try "${controller.suggestedQuery}"'),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 8),
              const Text(
                'Try a clearer topic phrase, another pack, or a qualified scholar for a context-specific answer.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CitationLinksCard extends StatelessWidget {
  const _CitationLinksCard({
    required this.results,
    required this.onTap,
  });

  final List<HadithFinderResult> results;
  final Future<void> Function(HadithSearchResult result) onTap;

  static const double _minimumVisibleConfidence = 0.42;

  @override
  Widget build(BuildContext context) {
    final List<HadithFinderResult> visibleResults = results
        .where(
          (HadithFinderResult result) =>
              result.confidence >= _minimumVisibleConfidence,
        )
        .take(3)
        .toList(growable: false);
    final List<HadithFinderResult> rankedResults = visibleResults.isEmpty
        ? results.take(1).toList(growable: false)
        : visibleResults;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Top ${rankedResults.length} most relevant hadith',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Only showing matches at about 42% confidence or higher.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            for (final (int, HadithFinderResult) entry
                in rankedResults.indexed) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CitationLinkTile(
                  index: entry.$1 + 1,
                  result: entry.$2,
                  isPrimary: entry.$1 == 0,
                  onTap: () => onTap(entry.$2.result),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CitationLinkTile extends StatelessWidget {
  const _CitationLinkTile({
    required this.index,
    required this.result,
    required this.isPrimary,
    required this.onTap,
  });

  final int index;
  final HadithFinderResult result;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final HadithSearchResult data = result.result;
    final String title =
        data.title.trim().isEmpty ? 'Hadith source $index' : data.title.trim();
    final String snippet = _clipText(
      _firstNarrationSnippet(data.hadithText),
      120,
    );
    final int confidencePercent = (result.confidence * 100).round();
    final List<String> metadata = <String>[
      if (isPrimary) 'Most relevant',
      _visibleSourceReference(data),
      if (_gradeForDisplay(data.grade).isNotEmpty) _gradeForDisplay(data.grade),
      data.languageCode.toUpperCase(),
    ]..removeWhere((String part) => part.isEmpty);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: colorScheme.surfaceContainerLowest,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.85),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            metadata.join(' • '),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '$confidencePercent%',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (data.sourceUrl.trim().isNotEmpty)
                IconButton(
                  tooltip: 'Open public source',
                  onPressed: () => _openExternalSourceUrl(data.sourceUrl),
                  icon: const Icon(Icons.open_in_new_rounded),
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreInfoCard extends StatelessWidget {
  const _MoreInfoCard({
    required this.controller,
  });

  final HadithController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: const Text('Sources & safety'),
        children: <Widget>[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Hadith Finder uses official HadeethEnc packs stored verbatim on-device and searched offline.',
            ),
          ),
          const SizedBox(height: 12),
          if (controller.sourceVersions.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No Hadith packs have been installed on this device yet.',
              ),
            )
          else
            for (final SourceVersion version in controller.sourceVersions)
              _HadithSourceVersionCard(
                version: version,
                install: _matchingInstall(
                  controller.installedPacks,
                  version.languageCode,
                ),
              ),
          const SizedBox(height: 6),
          const _SafetyFooterCard(compact: true),
        ],
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
          if (_publicSourceUrlForVersion(version).isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text('Public source: ${_publicSourceUrlForVersion(version)}'),
          ],
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
  const _SafetyFooterCard({
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('Safety'),
        subtitle: Text(
          'This is a reference tool, not a fatwa service.',
        ),
      );
    }
    return Card(
      child: ListTile(
        title: const Text('Safety'),
        subtitle: const Text(
          'This finder shows cited hadith and explanations. It is not a fatwa service.',
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

String _formatDate(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _publicSourceUrlForVersion(SourceVersion version) {
  if (version.providerKey.toLowerCase() == 'hadeethenc') {
    return 'https://hadeethenc.com/${version.languageCode}/home';
  }
  return '';
}

Future<void> _openExternalSourceUrl(String rawUrl) async {
  final Uri? uri = Uri.tryParse(rawUrl);
  if (uri == null) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

List<String> _splitNarrations(String text) {
  final String cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) {
    return const <String>[];
  }
  final List<String> pieces = cleaned
      .split(RegExp(r'Another narration reads:\s*', caseSensitive: false))
      .map((String piece) => piece.trim())
      .where((String piece) => piece.isNotEmpty)
      .toList(growable: false);
  return pieces.isEmpty ? <String>[cleaned] : pieces;
}

String _firstNarrationSnippet(String text) {
  final List<String> narrations = _splitNarrations(text);
  if (narrations.isEmpty) {
    return '';
  }
  return _clipText(narrations.first, 220);
}

String _plainWordsFromDetail(HadithDetail detail) {
  if (detail.benefits.isNotEmpty) {
    return _clipText(detail.benefits.first.trim(), 180);
  }
  final String simplified = _simplifyExplanation(detail.explanation);
  if (simplified.isNotEmpty) {
    return simplified;
  }
  return _firstNarrationSnippet(detail.hadithText);
}

String _simplifyExplanation(String explanation) {
  final String cleaned =
      explanation.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleaned.isEmpty) {
    return '';
  }

  final List<String> sentences = cleaned
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((String sentence) => _rewriteExplanationSentence(sentence))
      .where((String sentence) => sentence.isNotEmpty)
      .toList(growable: false);

  if (sentences.isEmpty) {
    return _clipText(cleaned, 180);
  }

  final StringBuffer summary = StringBuffer();
  for (final String sentence in sentences) {
    final String next =
        summary.isEmpty ? sentence : '${summary.toString()} $sentence';
    if (next.length > 200) {
      break;
    }
    if (summary.isNotEmpty) {
      summary.write(' ');
    }
    summary.write(sentence);
    if (summary.length >= 150) {
      break;
    }
  }
  return _clipText(summary.toString().trim(), 200);
}

String _rewriteExplanationSentence(String sentence) {
  String text = sentence
      .replaceAll(RegExp(r'\(may Allah[^)]*\)', caseSensitive: false), '')
      .replaceAll('(ﷺ)', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.isEmpty) {
    return '';
  }

  if (text.startsWith('To clarify,') ||
      text.startsWith('In other words,') ||
      text.startsWith('Likewise,')) {
    return '';
  }

  text = text.replaceFirst(
    RegExp(r'^[A-Z][^.]{0,140}? conveys a message regarding '),
    'This hadith is about ',
  );
  text = text.replaceFirst(
    RegExp(r'^[A-Z][^.]{0,140}? highlights '),
    'This hadith teaches ',
  );
  text = text.replaceFirst(
    RegExp(r'^[A-Z][^.]{0,160}? reported that the Prophet[^.]*? that '),
    'It teaches that ',
  );
  text = text.replaceFirst(
    RegExp(r'^This Had[īi]th indicates that ', caseSensitive: false),
    'This hadith teaches that ',
  );
  text = text.replaceAll('  ', ' ').trim();

  if (_looksTooTechnical(text)) {
    return '';
  }
  return _clipText(_ensureSentence(text), 170);
}

bool _looksTooTechnical(String value) {
  final String normalized = value.toLowerCase();
  return normalized.contains('communal duty') ||
      normalized.contains('polytheism') ||
      normalized.contains('companions never practiced') ||
      normalized.contains('based on religious texts');
}

String _clipText(String value, int maxLength) {
  final String trimmed = value.trim();
  if (trimmed.length <= maxLength) {
    return trimmed;
  }
  return '${trimmed.substring(0, maxLength - 1).trim()}…';
}

String _visibleSourceReference(HadithSearchResult data) {
  if (data.sourceReference.trim().isNotEmpty) {
    return _stripBrackets(data.sourceReference);
  }
  final String fromGrade = _sourceReferenceFromGrade(data.grade);
  if (fromGrade.isNotEmpty) {
    return fromGrade;
  }
  return 'HadeethEnc';
}

String _detailSourceReference(HadithDetail detail) {
  if (detail.sourceReference.trim().isNotEmpty) {
    return _stripBrackets(detail.sourceReference);
  }
  final String fromGrade = _sourceReferenceFromGrade(detail.grade);
  if (fromGrade.isNotEmpty) {
    return fromGrade;
  }
  return 'HadeethEnc';
}

String _sourceReferenceFromGrade(String grade) {
  final String cleaned = _stripBrackets(grade);
  final String normalized = cleaned.toLowerCase();
  if (normalized.contains('narrated by') ||
      normalized.contains('reported by') ||
      normalized.contains('bukhari') ||
      normalized.contains('muslim') ||
      normalized.contains('tirmidhi') ||
      normalized.contains('abu dawud') ||
      normalized.contains('ibn majah') ||
      normalized.contains('ahmad')) {
    return cleaned;
  }
  return '';
}

String _gradeForDisplay(String grade) {
  return _stripBrackets(grade);
}

String _stripBrackets(String value) {
  return value.trim().replaceAll(RegExp(r'^\[|\]$'), '');
}

String _ensureSentence(String value) {
  if (value.isEmpty) {
    return value;
  }
  if (value.endsWith('.') || value.endsWith('!') || value.endsWith('?')) {
    return value;
  }
  return '$value.';
}
