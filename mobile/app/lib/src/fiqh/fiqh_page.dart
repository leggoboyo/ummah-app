import 'package:core/core.dart';
import 'package:fiqh/fiqh.dart';
import 'package:flutter/material.dart';

import 'fiqh_controller.dart';

class FiqhGuideScreen extends StatefulWidget {
  const FiqhGuideScreen({
    super.key,
    required this.fiqhProfile,
  });

  final FiqhProfile fiqhProfile;

  @override
  State<FiqhGuideScreen> createState() => _FiqhGuideScreenState();
}

class _FiqhGuideScreenState extends State<FiqhGuideScreen> {
  late final FiqhController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FiqhController(
      fiqhProfile: widget.fiqhProfile,
    );
    Future<void>.microtask(_controller.initialize);
  }

  @override
  void dispose() {
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
            title: const Text('Fiqh Guide'),
          ),
          body: !_controller.isReady
              ? const Center(child: CircularProgressIndicator())
              : DefaultTabController(
                  length: 3,
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      12,
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        if (_controller.errorMessage != null)
                                          _MessageCard(
                                            title: 'Attention needed',
                                            message: _controller.errorMessage!,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .errorContainer,
                                          ),
                                        if (_controller.statusMessage != null)
                                          _MessageCard(
                                            title: 'Status',
                                            message: _controller.statusMessage!,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                          ),
                                        _OverviewCard(
                                          controller: _controller,
                                        ),
                                        const SizedBox(height: 12),
                                        const _SafetyCard(),
                                      ],
                                    ),
                                  ),
                                  const TabBar(
                                    tabs: <Widget>[
                                      Tab(text: 'Checklist'),
                                      Tab(text: 'Disputed'),
                                      Tab(text: 'Compare'),
                                    ],
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      children: <Widget>[
                                        _ChecklistTab(controller: _controller),
                                        _DisputedTab(controller: _controller),
                                        _CompareTab(controller: _controller),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    required this.controller,
  });

  final FiqhController controller;

  @override
  Widget build(BuildContext context) {
    final FiqhKnowledgePack? pack = controller.pack;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Profile: ${controller.fiqhProfile.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              pack?.disclaimer ??
                  'The app presents sourced views and does not replace qualified scholars.',
            ),
            const SizedBox(height: 8),
            Text(
              'Checklist progress is stored only on this device for ${_formatDate(controller.checklistDate)}.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistTab extends StatelessWidget {
  const _ChecklistTab({
    required this.controller,
  });

  final FiqhController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.checklistItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No checklist items are available for this profile yet.'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const _InfoCard(
          title: 'How to use this',
          message:
              'This checklist is a study and review aid. It helps you track topics and obligations, but it does not issue fatwas or replace local guidance.',
        ),
        const SizedBox(height: 12),
        ...controller.checklistItems.map(
          (FiqhChecklistItem item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChecklistItemCard(
              item: item,
              isCompleted: controller.isCompleted(item.id),
              onChanged: (bool value) {
                controller.toggleChecklistItem(
                  topicId: item.id,
                  isCompleted: value,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ChecklistItemCard extends StatelessWidget {
  const _ChecklistItemCard({
    required this.item,
    required this.isCompleted,
    required this.onChanged,
  });

  final FiqhChecklistItem item;
  final bool isCompleted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Checkbox(
                  value: isCompleted,
                  onChanged: (bool? value) => onChanged(value ?? false),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.topic.checklistLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _ClassificationChip(
                            classification: item.activeRuling.classification,
                          ),
                          Chip(label: Text(item.topic.frequencyLabel)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.activeRuling.summary),
            const SizedBox(height: 8),
            Text(
              'Notes: ${item.activeRuling.notes}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'When context changes: ${item.activeRuling.contextChanges}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _EvidenceCard(
              title: 'Evidence references',
              references: item.activeRuling.evidence,
            ),
            const SizedBox(height: 12),
            Text(
              'Ask a qualified scholar: ${item.topic.scholarEscalation}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DisputedTab extends StatelessWidget {
  const _DisputedTab({
    required this.controller,
  });

  final FiqhController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.disputedTopics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No disputed topics are available yet.'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const _InfoCard(
          title: 'Disputed issues',
          message:
              'These topics differ across schools. The app shows sourced views side by side and avoids forcing one answer.',
        ),
        const SizedBox(height: 12),
        ...controller.disputedTopics.map(
          (FiqhTopic topic) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DisputedTopicCard(
              topic: topic,
              currentSchool: controller.fiqhProfile.school,
              onCompare: () {
                controller.selectComparisonTopic(topic.id);
                DefaultTabController.of(context).animateTo(2);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DisputedTopicCard extends StatelessWidget {
  const _DisputedTopicCard({
    required this.topic,
    required this.currentSchool,
    required this.onCompare,
  });

  final FiqhTopic topic;
  final SchoolOfThought currentSchool;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final FiqhRuling? currentRuling = topic.rulingFor(currentSchool);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              topic.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (currentRuling != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _ClassificationChip(
                    classification: currentRuling.classification,
                  ),
                  Chip(label: Text(_schoolLabel(currentSchool))),
                ],
              ),
            const SizedBox(height: 12),
            Text(currentRuling?.summary ?? topic.summary),
            const SizedBox(height: 8),
            Text(
              'Context: ${currentRuling?.contextChanges ?? topic.scholarEscalation}',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCompare,
                child: const Text('Compare schools'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareTab extends StatelessWidget {
  const _CompareTab({
    required this.controller,
  });

  final FiqhController controller;

  @override
  Widget build(BuildContext context) {
    final FiqhTopic? selectedTopic = controller.selectedComparisonTopic;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: controller.selectedComparisonTopicId?.isEmpty == true
              ? null
              : controller.selectedComparisonTopicId,
          items: controller.topics
              .map(
                (FiqhTopic topic) => DropdownMenuItem<String>(
                  value: topic.id,
                  child: Text(topic.title),
                ),
              )
              .toList(growable: false),
          onChanged: controller.selectComparisonTopic,
          decoration: const InputDecoration(
            labelText: 'Topic',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedTopic != null) ...<Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    selectedTopic.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(selectedTopic.summary),
                  const SizedBox(height: 12),
                  Text(
                    'Ask a qualified scholar: ${selectedTopic.scholarEscalation}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final SchoolOfThought school in SchoolOfThought.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SchoolComparisonCard(
                school: school,
                topic: selectedTopic,
                highlight: school == controller.fiqhProfile.school,
              ),
            ),
          _SourceVersionsCard(sourceVersions: controller.sourceVersions),
        ] else
          const _InfoCard(
            title: 'No topic selected',
            message: 'Choose a topic to compare the schools.',
          ),
      ],
    );
  }
}

class _SchoolComparisonCard extends StatelessWidget {
  const _SchoolComparisonCard({
    required this.school,
    required this.topic,
    required this.highlight,
  });

  final SchoolOfThought school;
  final FiqhTopic topic;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final FiqhRuling? ruling = topic.rulingFor(school);
    final Color? cardColor =
        highlight ? Theme.of(context).colorScheme.secondaryContainer : null;
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ruling == null
            ? Text('${_schoolLabel(school)} mapping is not available yet.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _schoolLabel(school),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (highlight) const Chip(label: Text('Your profile')),
                      const SizedBox(width: 8),
                      _ClassificationChip(
                        classification: ruling.classification,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(ruling.summary),
                  const SizedBox(height: 8),
                  Text('Notes: ${ruling.notes}'),
                  const SizedBox(height: 8),
                  Text('When context changes: ${ruling.contextChanges}'),
                  const SizedBox(height: 12),
                  _EvidenceCard(
                    title: 'Evidence references',
                    references: ruling.evidence,
                  ),
                ],
              ),
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.title,
    required this.references,
  });

  final String title;
  final List<EvidenceReference> references;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final EvidenceReference reference in references)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _referenceLine(reference),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceVersionsCard extends StatelessWidget {
  const _SourceVersionsCard({
    required this.sourceVersions,
  });

  final List<SourceVersion> sourceVersions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Sources & Licenses',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (sourceVersions.isEmpty)
              const Text('No source versions are recorded yet.')
            else
              for (final SourceVersion version in sourceVersions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${version.providerKey}: ${version.contentKey} ${version.version}\n${version.attribution}',
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      title: 'Safety',
      message:
          'This guide presents school-based views with references. It is not a mufti, and it should not be used as the final word for divorce, violence, suicide, medical, legal, or other context-heavy cases.',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: color,
        child: ListTile(
          title: Text(title),
          subtitle: Text(message),
        ),
      ),
    );
  }
}

class _ClassificationChip extends StatelessWidget {
  const _ClassificationChip({
    required this.classification,
  });

  final FiqhClassification classification;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(classification.label),
      backgroundColor: _backgroundColor(context, classification),
    );
  }

  Color _backgroundColor(BuildContext context, FiqhClassification value) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    switch (value) {
      case FiqhClassification.obligatory:
      case FiqhClassification.necessary:
        return scheme.primaryContainer;
      case FiqhClassification.emphasizedRecommended:
      case FiqhClassification.recommended:
        return scheme.secondaryContainer;
      case FiqhClassification.permissible:
        return scheme.tertiaryContainer;
      case FiqhClassification.disliked:
      case FiqhClassification.disputed:
        return scheme.surfaceContainerHighest;
      case FiqhClassification.forbidden:
        return scheme.errorContainer;
    }
  }
}

String _referenceLine(EvidenceReference reference) {
  final StringBuffer buffer = StringBuffer()
    ..write('${reference.citation}: ${reference.title}');
  if (reference.note != null && reference.note!.isNotEmpty) {
    buffer.write(' (${reference.note})');
  }
  if (reference.url != null && reference.url!.isNotEmpty) {
    buffer.write('\n${reference.url}');
  }
  return buffer.toString();
}

String _schoolLabel(SchoolOfThought school) {
  switch (school) {
    case SchoolOfThought.hanafi:
      return 'Hanafi';
    case SchoolOfThought.maliki:
      return 'Maliki';
    case SchoolOfThought.shafii:
      return 'Shafi\'i';
    case SchoolOfThought.hanbali:
      return 'Hanbali';
    case SchoolOfThought.jafari:
      return 'Ja\'fari';
  }
}

String _formatDate(DateTime value) {
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
  return '$month ${value.day}, ${value.year}';
}
