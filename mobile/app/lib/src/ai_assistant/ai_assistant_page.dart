import 'dart:async';

import 'package:ai_assistant/ai_assistant.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../bootstrap/app_controller.dart';
import '../subscriptions/subscriptions_page.dart';
import 'ai_assistant_controller.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({
    super.key,
    required this.appController,
  });

  final AppController appController;

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  late final AiAssistantController _controller;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _questionController;

  @override
  void initState() {
    super.initState();
    _controller = AiAssistantController();
    _apiKeyController = TextEditingController();
    _questionController = TextEditingController();
    Future<void>.microtask(
      () => _controller.initialize(
        preferredLanguageCode: widget.appController.languageCode,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_controller.close());
    _controller.dispose();
    _apiKeyController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _controller,
        widget.appController,
      ]),
      builder: (BuildContext context, _) {
        final bool quranUnlocked = widget.appController.hasAccess(
          AppEntitlement.aiQuran,
        );
        final bool hadithUnlocked = widget.appController.hasAccess(
          AppEntitlement.aiHadith,
        );
        final bool selectedModeUnlocked =
            _isModeUnlocked(_controller.selectedMode);

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Assistant'),
          ),
          body: !_controller.isReady
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    _PrivacyCard(controller: widget.appController),
                    const SizedBox(height: 12),
                    _AccessCard(
                      quranUnlocked: quranUnlocked,
                      hadithUnlocked: hadithUnlocked,
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      controller: _controller,
                      quranUnlocked: quranUnlocked,
                      hadithUnlocked: hadithUnlocked,
                    ),
                    const SizedBox(height: 12),
                    if (!selectedModeUnlocked)
                      _LockedModeCard(
                        mode: _controller.selectedMode,
                        appController: widget.appController,
                      )
                    else ...<Widget>[
                      _ApiKeyCard(
                        controller: _controller,
                        apiKeyController: _apiKeyController,
                      ),
                      const SizedBox(height: 12),
                      _QuestionCard(
                        controller: _controller,
                        questionController: _questionController,
                        isModeUnlocked: selectedModeUnlocked,
                      ),
                    ],
                    if (_controller.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _MessageCard(
                        title: 'Attention needed',
                        message: _controller.errorMessage!,
                        color: Theme.of(context).colorScheme.errorContainer,
                      ),
                    ],
                    if (_controller.statusMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _MessageCard(
                        title: 'Status',
                        message: _controller.statusMessage!,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                    ],
                    if (_controller.latestResponse != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _AssistantResponseView(
                        response: _controller.latestResponse!,
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  bool _isModeUnlocked(AssistantMode mode) {
    return widget.appController.hasAccess(mode.requiredEntitlement);
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('BYOK privacy model'),
        subtitle: Text(
          'Your OpenAI API key is stored in secure device storage. Your question and the retrieved local Quran or Hadith passages are sent to OpenAI only when you tap Ask. Billing provider: ${controller.billingProviderKind.label}.',
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.quranUnlocked,
    required this.hadithUnlocked,
  });

  final bool quranUnlocked;
  final bool hadithUnlocked;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            Chip(
              label:
                  Text(quranUnlocked ? 'Quran AI unlocked' : 'Quran AI locked'),
            ),
            Chip(
              label: Text(
                  hadithUnlocked ? 'Hadith AI unlocked' : 'Hadith AI locked'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.controller,
    required this.quranUnlocked,
    required this.hadithUnlocked,
  });

  final AiAssistantController controller;
  final bool quranUnlocked;
  final bool hadithUnlocked;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Assistant mode',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<AssistantMode>(
              segments: <ButtonSegment<AssistantMode>>[
                ButtonSegment<AssistantMode>(
                  value: AssistantMode.quran,
                  label: const Text('Quran'),
                  enabled: quranUnlocked,
                ),
                ButtonSegment<AssistantMode>(
                  value: AssistantMode.hadith,
                  label: const Text('Hadith'),
                  enabled: hadithUnlocked,
                ),
              ],
              selected: <AssistantMode>{controller.selectedMode},
              onSelectionChanged: (Set<AssistantMode> selection) {
                controller.selectMode(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedModeCard extends StatelessWidget {
  const _LockedModeCard({
    required this.mode,
    required this.appController,
  });

  final AssistantMode mode;
  final AppController appController;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${mode.title} is locked',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock the relevant AI module or the Mega Bundle to use this mode.',
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => PlansAndUnlocksScreen(
                      controller: appController,
                      focusEntitlement: mode.requiredEntitlement,
                    ),
                  ),
                );
              },
              child: const Text('View plans'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyCard extends StatelessWidget {
  const _ApiKeyCard({
    required this.controller,
    required this.apiKeyController,
  });

  final AiAssistantController controller;
  final TextEditingController apiKeyController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'OpenAI BYOK key',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              controller.apiKeyConfigured
                  ? 'A key is already saved in secure device storage.'
                  : 'Paste your OpenAI API key here if you want the assistant to use BYOK mode.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: apiKeyController,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'OpenAI API key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: controller.isWorking
                      ? null
                      : () async {
                          await controller.saveApiKey(apiKeyController.text);
                          if (controller.apiKeyConfigured) {
                            apiKeyController.clear();
                          }
                        },
                  child: const Text('Save key'),
                ),
                FilledButton.tonal(
                  onPressed:
                      controller.isWorking || !controller.apiKeyConfigured
                          ? null
                          : () => controller.clearApiKey(),
                  child: const Text('Remove key'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.controller,
    required this.questionController,
    required this.isModeUnlocked,
  });

  final AiAssistantController controller;
  final TextEditingController questionController;
  final bool isModeUnlocked;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              controller.selectedMode.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Only retrieved local sources are used. If the evidence is insufficient, the assistant should say so.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: questionController,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: controller.selectedMode == AssistantMode.quran
                    ? 'Ask a Quran question'
                    : 'Ask a Hadith question',
                hintText: controller.selectedMode == AssistantMode.quran
                    ? 'Example: What do the retrieved verses say about patience?'
                    : 'Example: What do the retrieved hadith say about intention?',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: controller.isWorking ||
                      !controller.apiKeyConfigured ||
                      !isModeUnlocked
                  ? null
                  : () => controller.askQuestion(questionController.text),
              child: Text(
                controller.isWorking ? 'Asking...' : 'Ask',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantResponseView extends StatelessWidget {
  const _AssistantResponseView({
    required this.response,
  });

  final AssistantResponse response;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (response.safetyReview.isHighRisk)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MessageCard(
              title: 'High-risk topic',
              message:
                  '${response.safetyReview.notice}\n\n${response.safetyReview.nextStep}',
              color: Theme.of(context).colorScheme.errorContainer,
            ),
          ),
        _SectionCard(
          title: 'Answer',
          body: response.answer,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Commentary',
          body: response.commentary,
        ),
        const SizedBox(height: 12),
        _SourcesCard(response: response),
        const SizedBox(height: 12),
        _SourceVersionsCard(response: response),
      ],
    );
  }
}

class _SourcesCard extends StatelessWidget {
  const _SourcesCard({
    required this.response,
  });

  final AssistantResponse response;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Sources',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (response.sources.isEmpty)
              const Text('No local sources were retrieved for this answer.')
            else
              for (final RetrievedPassage source in response.sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${source.reference} • ${source.attribution}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(source.title),
                      const SizedBox(height: 8),
                      SelectableText(source.quote),
                      if (source.note != null &&
                          source.note!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          source.note!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
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
    required this.response,
  });

  final AssistantResponse response;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Source versions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (response.sourceVersions.isEmpty)
              const Text('No source version metadata is available yet.')
            else
              for (final SourceVersion version in response.sourceVersions)
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: SelectableText(body),
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
