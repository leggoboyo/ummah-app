import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:scholar_feed/scholar_feed.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bootstrap/app_controller.dart';
import 'scholar_feed_controller.dart';

class ScholarFeedScreen extends StatefulWidget {
  const ScholarFeedScreen({
    super.key,
    required this.appController,
  });

  final AppController appController;

  @override
  State<ScholarFeedScreen> createState() => _ScholarFeedScreenState();
}

class _ScholarFeedScreenState extends State<ScholarFeedScreen> {
  late final ScholarFeedController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScholarFeedController();
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
            title: const Text('Scholar Feed'),
          ),
          body: !_controller.isReady
              ? const Center(child: CircularProgressIndicator())
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            _OverviewCard(
                              appController: widget.appController,
                              controller: _controller,
                            ),
                            if (_controller.errorMessage != null) ...<Widget>[
                              const SizedBox(height: 12),
                              _MessageCard(
                                title: 'Attention needed',
                                message: _controller.errorMessage!,
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                              ),
                            ],
                            if (_controller.statusMessage != null) ...<Widget>[
                              const SizedBox(height: 12),
                              _MessageCard(
                                title: 'Feed status',
                                message: _controller.statusMessage!,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const TabBar(
                        tabs: <Widget>[
                          Tab(text: 'Feed'),
                          Tab(text: 'Sources'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: <Widget>[
                            _FeedTab(controller: _controller),
                            _SourcesTab(controller: _controller),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.appController,
    required this.controller,
  });

  final AppController appController;
  final ScholarFeedController controller;

  @override
  Widget build(BuildContext context) {
    final DateTime? lastSyncedAt = controller.lastSyncedAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Source directory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This module stores feed metadata locally and links out to the original publisher. It does not rewrite or republish the article body.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(
                  label: Text(
                    'Following ${controller.followedSourceIds.length} source${controller.followedSourceIds.length == 1 ? '' : 's'}',
                  ),
                ),
                if (lastSyncedAt != null)
                  Chip(
                      label:
                          Text('Last sync ${_formatDateTime(lastSyncedAt)}')),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed:
                  controller.isWorking ? null : () => controller.refresh(),
              child: const Text('Refresh feed'),
            ),
            const SizedBox(height: 12),
            Text(
              'Entitlement status: ${appController.hasAccess(AppEntitlement.scholarFeed) ? 'Unlocked' : 'Locked'}',
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.controller,
  });

  final ScholarFeedController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.cachedItems.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          Card(
            child: ListTile(
              title: Text('No cached items yet'),
              subtitle: Text(
                'Follow at least one source and refresh the feed. The app stores only metadata locally and opens the original source URL in the browser later.',
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.cachedItems.length,
      itemBuilder: (BuildContext context, int index) {
        final ScholarFeedItem item = controller.cachedItems[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      Chip(label: Text(item.providerName)),
                      Chip(label: Text(item.categoryLabel)),
                      Chip(label: Text(item.languageCode.toUpperCase())),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (item.summary.trim().isNotEmpty)
                    Text(item.summary)
                  else
                    const Text('No summary was provided in the feed metadata.'),
                  const SizedBox(height: 12),
                  Text(
                    item.url,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (item.publishedAt != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      'Published ${_formatDateTime(item.publishedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () => _openSourceUrl(context, item.url),
                      child: const Text('Open source'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _openSourceUrl(BuildContext context, String url) async {
  final Uri uri = Uri.parse(url);
  final bool launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the source link on this device.'),
      ),
    );
  }
}

class _SourcesTab extends StatelessWidget {
  const _SourcesTab({
    required this.controller,
  });

  final ScholarFeedController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.availableSources.length,
      itemBuilder: (BuildContext context, int index) {
        final ScholarFeedSource source = controller.availableSources[index];
        final bool followed = controller.isFollowed(source.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: SwitchListTile(
              value: followed,
              onChanged: controller.isWorking
                  ? null
                  : (bool value) => controller.toggleSource(
                        sourceId: source.id,
                        isFollowed: value,
                      ),
              title: Text(source.title),
              subtitle: Text(
                '${source.description}\n${source.feedUrl}',
              ),
              secondary: Chip(label: Text(source.languageCode.toUpperCase())),
            ),
          ),
        );
      },
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

String _formatDateTime(DateTime value) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final String month = months[value.month - 1];
  final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final String minute = value.minute.toString().padLeft(2, '0');
  final String suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$month ${value.day}, ${value.year} at $hour:$minute $suffix';
}
