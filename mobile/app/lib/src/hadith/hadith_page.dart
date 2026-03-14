import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:hadith/hadith.dart';

import 'hadith_controller.dart';

class HadithLibraryScreen extends StatefulWidget {
  const HadithLibraryScreen({
    super.key,
    required this.preferredLanguageCode,
  });

  final String preferredLanguageCode;

  @override
  State<HadithLibraryScreen> createState() => _HadithLibraryScreenState();
}

class _HadithLibraryScreenState extends State<HadithLibraryScreen> {
  late final HadithController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controller = HadithController();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Hadith Library'),
          ),
          body: !_controller.isReady
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    if (_controller.errorMessage != null)
                      _MessageCard(
                        title: 'Attention needed',
                        message: _controller.errorMessage!,
                        color: Theme.of(context).colorScheme.errorContainer,
                      ),
                    if (_controller.statusMessage != null)
                      _MessageCard(
                        title: 'Hadith sync status',
                        message: _controller.statusMessage!,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                    _SearchCard(
                      controller: _controller,
                      searchController: _searchController,
                    ),
                    const SizedBox(height: 12),
                    _CategoryCard(controller: _controller),
                    const SizedBox(height: 12),
                    _ShiaPlaceholderCard(controller: _controller),
                    const SizedBox(height: 12),
                    _SourcesCard(controller: _controller),
                    const SizedBox(height: 12),
                    if (_controller.searchQuery.trim().isNotEmpty) ...<Widget>[
                      if (_controller.searchResults.isEmpty)
                        const _InfoCard(
                          title: 'No offline matches yet',
                          message:
                              'Download at least one category before searching cached hadith text offline.',
                        )
                      else
                        ..._controller.searchResults.map(
                          (HadithSearchResult result) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _HadithListCard(
                              result: result,
                              onTap: () => _openHadithDetail(result.id),
                            ),
                          ),
                        ),
                    ] else ...<Widget>[
                      if (_controller.cachedHadiths.isEmpty)
                        const _InfoCard(
                          title: 'No cached hadith yet',
                          message:
                              'Choose a category and download it to make the Sunni hadith library available offline.',
                        )
                      else
                        ..._controller.cachedHadiths.map(
                          (HadithSearchResult result) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _HadithListCard(
                              result: result,
                              onTap: () => _openHadithDetail(result.id),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Future<void> _openHadithDetail(int hadithId) async {
    final HadithDetail? detail = await _controller.loadHadithDetail(hadithId);
    if (!mounted || detail == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => HadithDetailScreen(detail: detail),
      ),
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
        title: const Text('Hadith Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                  Text(
                    detail.hadithText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      Chip(label: Text(detail.grade)),
                      Chip(label: Text(detail.attribution)),
                    ],
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
          if (detail.hints.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Hints',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    for (final String hint in detail.hints)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• $hint'),
                      ),
                  ],
                ),
              ),
            ),
          Card(
            child: ListTile(
              title: const Text('Arabic reference'),
              subtitle: Text(
                '${detail.hadithIntroArabic}\n${detail.hadithArabic}',
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Source'),
              subtitle: Text(
                'HadeethEnc.com • ${detail.languageCode.toUpperCase()} translation cached verbatim',
              ),
            ),
          ),
        ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Sunni Hadith Library',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search cached hadith text and explanations',
                hintText: 'Try blood, prayer, mercy',
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
              onChanged: controller.updateSearchQuery,
            ),
            const SizedBox(height: 12),
            Text(
              'Search runs fully offline once a category has been downloaded from HadeethEnc.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.controller,
  });

  final HadithController controller;

  @override
  Widget build(BuildContext context) {
    final HadithCategory? category = controller.selectedCategory;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Offline category sync',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey<int?>(controller.selectedCategoryId),
              initialValue: controller.selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: controller.categories
                  .map(
                    (HadithCategory item) => DropdownMenuItem<int>(
                      value: item.id,
                      child: Text(
                        '${item.title} (${item.cachedHadithCount}/${item.hadithCount})',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: controller.isWorking ? null : controller.selectCategory,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: controller.isWorking
                      ? null
                      : () => controller.refreshCategories(),
                  child: const Text('Refresh categories'),
                ),
                FilledButton.tonal(
                  onPressed: controller.isWorking || category == null
                      ? null
                      : () => controller.downloadSelectedCategory(),
                  child: const Text('Download category'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              category == null
                  ? 'Pick a category to sync it for offline use.'
                  : 'Selected category: ${category.title}\nCached ${category.cachedHadithCount} of ${category.hadithCount} hadith entries. Large categories can take time because each hadith is fetched and stored verbatim.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
    final ShiaHadithPackAvailability? availability = controller.shiaAvailability;
    return Card(
      child: ListTile(
        title: const Text('Shia Hadith Pack'),
        subtitle: Text(
          availability?.message ??
              'Shia Hadith Pack is coming; it depends on licensed content.',
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
            Text(
              'Sources & versions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'HadeethEnc content is cached verbatim. The app records the public API line as API/v1 and keeps the last sync timestamp locally until HadeethEnc exposes a finer-grained translation version field.',
            ),
            const SizedBox(height: 12),
            if (chips.isEmpty)
              const Text('No hadith source versions have been cached yet.')
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

class _HadithListCard extends StatelessWidget {
  const _HadithListCard({
    required this.result,
    required this.onTap,
  });

  final HadithSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(result.title),
        subtitle: Text(
          result.hadithText,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
