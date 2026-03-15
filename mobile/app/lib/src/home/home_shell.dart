import 'dart:async';
import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:prayer/prayer.dart';

import '../ai_assistant/ai_assistant_page.dart';
import '../app/app_strings.dart';
import '../bootstrap/app_controller.dart';
import '../bootstrap/app_profile.dart';
import '../bootstrap/manual_location_preset.dart';
import '../fiqh/fiqh_page.dart';
import '../hadith/hadith_page.dart';
import '../qibla/device_heading_service.dart';
import '../quran/quran_controller.dart';
import '../quran/quran_page.dart';
import '../scholar_feed/scholar_feed_page.dart';
import '../settings/settings_hub_page.dart';
import '../subscriptions/subscriptions_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const int _resumeSyncDebounceSeconds = 30;

  int _selectedIndex = 0;
  late final QuranController _quranController;
  late final Timer _clockTimer;
  DateTime _now = DateTime.now();
  DateTime? _lastForegroundRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _quranController = QuranController(
      startupMode: widget.controller.quranStartupMode,
      startupSelection: widget.controller.startupSelection,
    );
    Future<void>.microtask(
      () => _quranController.initialize(
        preferredLanguageCode: widget.controller.languageCode,
      ),
    );
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _clockTimer.cancel();
    _quranController.dispose();
    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _AppLifecycleObserver(onResume: _handleForegroundResume);

  Future<void> _handleForegroundResume() async {
    final DateTime now = DateTime.now();
    if (_lastForegroundRefreshAt != null &&
        now.difference(_lastForegroundRefreshAt!) <
            const Duration(seconds: _resumeSyncDebounceSeconds)) {
      return;
    }
    _lastForegroundRefreshAt = now;
    await widget.controller.refreshForegroundReliability();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings =
        AppStrings.forCode(Localizations.localeOf(context).languageCode);
    final List<Widget> pages = <Widget>[
      _DashboardPage(controller: widget.controller, now: _now),
      _PrayerPage(controller: widget.controller, now: _now),
      QuranPage(controller: _quranController),
      _QiblaPage(controller: widget.controller),
      _MorePage(
        quranController: _quranController,
        appController: widget.controller,
      ),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(strings.appName),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: strings.homeTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.schedule_outlined),
                  selectedIcon: const Icon(Icons.schedule),
                  label: strings.prayerTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  selectedIcon: const Icon(Icons.menu_book),
                  label: strings.quranTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: const Icon(Icons.explore),
                  label: strings.qiblaTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.more_horiz_outlined),
                  selectedIcon: const Icon(Icons.more_horiz),
                  label: strings.moreTab,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.controller,
    required this.now,
  });

  final AppController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings =
        AppStrings.forCode(Localizations.localeOf(context).languageCode);
    final PrayerDay prayerDay = controller.prayerDayFor(now);
    final PrayerName? nextPrayer = controller.nextPrayer(now);
    final DateTime? nextPrayerTime =
        nextPrayer == null ? null : prayerDay.timeFor(nextPrayer);
    final NotificationHealth? notificationHealth =
        controller.notificationHealth;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
      children: <Widget>[
        _GradientHeroCard(
          eyebrow: strings.nextPrayerTitle,
          title: nextPrayer == null
              ? strings.allPrayersPassedMessage
              : nextPrayer.label,
          subtitle: nextPrayerTime == null
              ? 'Your next schedule will appear after midnight.'
              : '${_formatTime(nextPrayerTime)} • ${_formatCountdownExact(nextPrayerTime.difference(now))}',
          footer: _HeroSettingsFooter(
            controller: controller,
            strings: strings,
          ),
        ),
        if (controller.bannerMessage != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              title: Text(strings.actionNeededTitle),
              subtitle: Text(controller.bannerMessage!),
            ),
          ),
        _DetailPanelCard(
          icon: Icons.notifications_active_outlined,
          title: strings.notificationHealthTitle,
          subtitle:
              notificationHealth?.message ?? strings.notificationsPendingSetup,
          trailing: _HealthBadge(
            status:
                notificationHealth?.status ?? NotificationHealthStatus.warning,
          ),
          footer: _NotificationReliabilityFooter(
            controller: controller,
            notificationHealth: notificationHealth,
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SectionHeader(
                  title: 'Today at a glance',
                  subtitle: 'Today\'s full prayer schedule.',
                ),
                const SizedBox(height: 16),
                for (final PrayerName prayer in PrayerName.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PrayerSnapshotTile(
                      label: prayer.label,
                      timeLabel: _formatTime(prayerDay.timeFor(prayer)),
                      highlighted: nextPrayer == prayer,
                      detailLabel:
                          nextPrayer == prayer && nextPrayerTime != null
                              ? _formatCountdownExact(
                                  nextPrayerTime.difference(now))
                              : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PrayerPage extends StatelessWidget {
  const _PrayerPage({
    required this.controller,
    required this.now,
  });

  final AppController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings =
        AppStrings.forCode(Localizations.localeOf(context).languageCode);
    final PrayerDay prayerDay = controller.prayerDayFor(now);
    final PrayerName? nextPrayer = controller.nextPrayer(now);
    final DateTime? nextPrayerTime =
        nextPrayer == null ? null : prayerDay.timeFor(nextPrayer);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
      children: <Widget>[
        _GradientHeroCard(
          eyebrow: 'Prayer Schedule',
          title: 'Today',
          subtitle: 'Today\'s schedule for ${_locationBadgeLabel(controller)}.',
          footer: _HeroSettingsFooter(
            controller: controller,
            strings: strings,
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SectionHeader(
                  title: 'Today',
                  subtitle:
                      'Prayer times are calculated locally on your device.',
                ),
                const SizedBox(height: 16),
                for (final PrayerName prayer in PrayerName.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PrayerSnapshotTile(
                      label: prayer.label,
                      timeLabel: _formatTime(prayerDay.timeFor(prayer)),
                      highlighted: nextPrayer == prayer,
                      detailLabel:
                          nextPrayer == prayer && nextPrayerTime != null
                              ? _formatCountdownExact(
                                  nextPrayerTime.difference(now))
                              : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _QiblaViewMode {
  compass,
  bearing,
}

class _QiblaPage extends StatefulWidget {
  const _QiblaPage({
    required this.controller,
  });

  final AppController controller;

  @override
  State<_QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<_QiblaPage> {
  final DeviceHeadingService _headingService =
      const FlutterCompassHeadingService();
  _QiblaViewMode _mode = _QiblaViewMode.compass;

  @override
  Widget build(BuildContext context) {
    final double bearing =
        widget.controller.qiblaDirection.bearingFromTrueNorth;

    return StreamBuilder<DeviceHeading?>(
      stream: _headingService.headingStream(),
      builder: (BuildContext context, AsyncSnapshot<DeviceHeading?> snapshot) {
        final DeviceHeading? heading = snapshot.data;
        final bool canUseCompass = heading != null;
        final bool showingCompass =
            canUseCompass && _mode == _QiblaViewMode.compass;
        final double arrowRotationDegrees = showingCompass
            ? ((bearing - heading.degreesFromNorth) + 360.0) % 360.0
            : bearing;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
          children: <Widget>[
            _GradientHeroCard(
              eyebrow: 'Qibla',
              title: '${bearing.toStringAsFixed(1)}°',
              subtitle: showingCompass
                  ? 'Compass mode is live. Point the top of your phone forward and line up the arrow.'
                  : 'Bearing mode works fully offline for your current prayer location.',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SegmentedButton<_QiblaViewMode>(
                        segments: const <ButtonSegment<_QiblaViewMode>>[
                          ButtonSegment<_QiblaViewMode>(
                            value: _QiblaViewMode.compass,
                            icon: Icon(Icons.explore_outlined),
                            label: Text('Compass'),
                          ),
                          ButtonSegment<_QiblaViewMode>(
                            value: _QiblaViewMode.bearing,
                            icon: Icon(Icons.public),
                            label: Text('Bearing'),
                          ),
                        ],
                        selected: <_QiblaViewMode>{_mode},
                        onSelectionChanged:
                            (Set<_QiblaViewMode> selectedModes) {
                          setState(() {
                            _mode = selectedModes.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _QiblaDial(
                      rotationDegrees: arrowRotationDegrees,
                      compassHeadingDegrees: heading?.degreesFromNorth,
                      showingCompass: showingCompass,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      showingCompass
                          ? _compassInstruction(
                              bearing, heading.degreesFromNorth)
                          : canUseCompass
                              ? 'Switch to Compass when you want the arrow to react to phone movement.'
                              : 'Compass mode needs a phone with heading sensors. Bearing mode still works offline.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (showingCompass) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        'If the arrow drifts, move your phone in a figure-eight and keep away from magnets or metal surfaces.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MorePage extends StatelessWidget {
  const _MorePage({
    required this.quranController,
    required this.appController,
  });

  final QuranController quranController;
  final AppController appController;

  Future<void> _openHadithFinder(BuildContext context) async {
    final String appUserId = await appController.ensureAppUserId();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => HadithLibraryScreen(
          preferredLanguageCode: appController.languageCode,
          hasPremiumLanguageAccess:
              appController.hasAccess(AppEntitlement.hadithPlus),
          startupSelection: appController.startupSelection,
          appUserId: appUserId,
          refreshPackAccess: appController.refreshEntitlements,
        ),
      ),
    );
  }

  void _openAiOrPaywall(BuildContext context) {
    final bool hasAnyAiAccess =
        appController.hasAccess(AppEntitlement.aiQuran) ||
            appController.hasAccess(AppEntitlement.aiHadith);

    if (hasAnyAiAccess) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => AiAssistantScreen(
            appController: appController,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => PlansAndUnlocksScreen(
          controller: appController,
          focusEntitlement: AppEntitlement.aiQuran,
        ),
      ),
    );
  }

  void _openScholarFeedOrPaywall(BuildContext context) {
    if (appController.hasAccess(AppEntitlement.scholarFeed)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ScholarFeedScreen(
            appController: appController,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => PlansAndUnlocksScreen(
          controller: appController,
          focusEntitlement: AppEntitlement.scholarFeed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: quranController,
      builder: (BuildContext context, _) {
        final List<Widget> sourceChips = quranController.sourceVersions
            .map(
              (SourceVersion version) => Chip(
                label: Text(
                  '${version.providerKey}: ${version.contentKey} ${version.version}',
                ),
              ),
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
          children: <Widget>[
            _GradientHeroCard(
              eyebrow: 'More',
              title: 'Tools, learning, and support',
              subtitle:
                  'Everything beyond the core prayer experience lives here.',
            ),
            _ModuleCard(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle:
                  'Privacy controls, source versions, and local diagnostics.',
              statusLabel: 'Open',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => SettingsHubScreen(
                      appController: appController,
                    ),
                  ),
                );
              },
            ),
            _ModuleCard(
              icon: Icons.workspace_premium_outlined,
              title: 'Plans & Unlocks',
              subtitle: appController.subscriptionStatusMessage ??
                  'Manage premium modules and restore purchases.',
              statusLabel: 'Open',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => PlansAndUnlocksScreen(
                      controller: appController,
                    ),
                  ),
                );
              },
            ),
            _ModuleCard(
              icon: appController.hasAccess(AppEntitlement.aiQuran) ||
                      appController.hasAccess(AppEntitlement.aiHadith)
                  ? Icons.auto_awesome_outlined
                  : Icons.lock_outline,
              title: 'AI Assistant',
              subtitle: appController.hasAccess(AppEntitlement.aiQuran) ||
                      appController.hasAccess(AppEntitlement.aiHadith)
                  ? 'Citation-first Quran and Hadith answers with BYOK key storage.'
                  : 'Unlock Ask Quran AI, Ask Hadith AI, or Mega Bundle to use the assistant.',
              statusLabel: appController.hasAccess(AppEntitlement.aiQuran) ||
                      appController.hasAccess(AppEntitlement.aiHadith)
                  ? 'Unlocked'
                  : 'Locked',
              highlighted: appController.hasAccess(AppEntitlement.aiQuran) ||
                  appController.hasAccess(AppEntitlement.aiHadith),
              onTap: () => _openAiOrPaywall(context),
            ),
            _ModuleCard(
              icon: appController.hasAccess(AppEntitlement.scholarFeed)
                  ? Icons.rss_feed_outlined
                  : Icons.lock_outline,
              title: 'Scholar Feed',
              subtitle: appController.hasAccess(AppEntitlement.scholarFeed)
                  ? 'Curated public source feeds with local metadata caching and source selection.'
                  : 'Unlock Scholar Feed or Mega Bundle to follow trusted source feeds.',
              statusLabel: appController.hasAccess(AppEntitlement.scholarFeed)
                  ? 'Unlocked'
                  : 'Locked',
              highlighted: appController.hasAccess(AppEntitlement.scholarFeed),
              onTap: () => _openScholarFeedOrPaywall(context),
            ),
            _ModuleCard(
              icon: Icons.rule_folder_outlined,
              title: 'Fiqh Guide',
              subtitle:
                  'Daily obligation checklists, disputed issues, and side-by-side school comparison with sourced references.',
              statusLabel: 'Open',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => FiqhGuideScreen(
                      fiqhProfile: appController.fiqhProfile,
                    ),
                  ),
                );
              },
            ),
            _ModuleCard(
              icon: Icons.library_books_outlined,
              title: 'Hadith Finder',
              subtitle: appController.hasAccess(AppEntitlement.hadithPlus)
                  ? 'Free Sunni Hadith Finder with extra language packs unlocked.'
                  : 'Free Sunni Hadith Finder with one recommended offline pack. Hadith Plus unlocks extra language packs and future advanced study tools.',
              statusLabel: appController.hasAccess(AppEntitlement.hadithPlus)
                  ? 'Open + extras'
                  : 'Free',
              highlighted: true,
              onTap: () => _openHadithFinder(context),
            ),
            _DetailPanelCard(
              icon: Icons.verified_user_outlined,
              title: 'Safety',
              subtitle:
                  'The app presents sourced views, not definitive fatwas. Users should consult qualified scholars for context-heavy issues.',
            ),
            if (sourceChips.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sourceChips,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  _AppLifecycleObserver({
    required Future<void> Function() onResume,
  }) : _onResume = onResume;

  final Future<void> Function() _onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResume());
    }
  }
}

class _GradientHeroCard extends StatelessWidget {
  const _GradientHeroCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.footer,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
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
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  eyebrow.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                if (footer != null) ...<Widget>[
                  const SizedBox(height: 18),
                  footer!,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _PrayerSnapshotTile extends StatelessWidget {
  const _PrayerSnapshotTile({
    required this.label,
    required this.timeLabel,
    required this.highlighted,
    this.detailLabel,
  });

  final String label;
  final String timeLabel;
  final bool highlighted;
  final String? detailLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted
            ? colorScheme.primaryContainer.withValues(alpha: 0.72)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? colorScheme.primary.withValues(alpha: 0.25)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (detailLabel != null) ...<Widget>[
              Text(
                detailLabel!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 10),
            ] else if (highlighted) ...<Widget>[
              Icon(
                Icons.brightness_1,
                size: 10,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
            ],
            Text(
              timeLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPanelCard extends StatelessWidget {
  const _DetailPanelCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
            if (footer != null) ...<Widget>[
              const SizedBox(height: 14),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroSettingsFooter extends StatelessWidget {
  const _HeroSettingsFooter({
    required this.controller,
    required this.strings,
  });

  final AppController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _InteractiveTinyPill(
          label: controller.fiqhProfile.label,
          icon: Icons.balance_outlined,
          onTap: () => _showFiqhPicker(context),
        ),
        _InteractiveTinyPill(
          label: strings.methodLabel(controller.calculationMethod),
          icon: Icons.schedule_outlined,
          onTap: () => _showMethodPicker(context),
        ),
        _InteractiveTinyPill(
          label: _locationBadgeLabel(controller),
          icon: Icons.location_on_outlined,
          onTap: () => _showLocationPicker(context),
        ),
      ],
    );
  }

  Future<void> _showFiqhPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        final List<FiqhProfile> options = <FiqhProfile>[
          const FiqhProfile(
            tradition: FiqhTradition.sunni,
            school: SchoolOfThought.hanafi,
          ),
          const FiqhProfile(
            tradition: FiqhTradition.sunni,
            school: SchoolOfThought.maliki,
          ),
          const FiqhProfile(
            tradition: FiqhTradition.sunni,
            school: SchoolOfThought.shafii,
          ),
          const FiqhProfile(
            tradition: FiqhTradition.sunni,
            school: SchoolOfThought.hanbali,
          ),
          const FiqhProfile(
            tradition: FiqhTradition.shia,
            school: SchoolOfThought.jafari,
          ),
        ];
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: <Widget>[
            Text(
              'Fiqh profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Pick the school you want Ummah App to use by default. You can still compare different schools later.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final FiqhProfile option in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option.label),
                trailing: option == controller.fiqhProfile
                    ? const Icon(Icons.check_circle)
                    : null,
                onTap: () async {
                  Navigator.of(context).pop();
                  await controller.updateFiqhProfile(option);
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _showMethodPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: <Widget>[
            Text(
              'Prayer method',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'These methods use different Fajr and Isha angles. Most people choose the one used by their local mosque.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final PrayerCalculationMethod method
                in PrayerCalculationMethod.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.methodLabel(method)),
                subtitle: Text(strings.methodDescription(method)),
                trailing: method == controller.calculationMethod
                    ? const Icon(Icons.check_circle)
                    : null,
                onTap: () async {
                  Navigator.of(context).pop();
                  await controller.updateCalculationMethod(method);
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _showLocationPicker(BuildContext context) async {
    String selectedLocationId = controller.profile.manualLocationId;
    AppLocationMode selectedMode = controller.locationMode;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  Text(
                    'Prayer location',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('City'),
                        selected: selectedMode == AppLocationMode.manual,
                        onSelected: (_) {
                          setState(() {
                            selectedMode = AppLocationMode.manual;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Location'),
                        selected: selectedMode == AppLocationMode.device,
                        onSelected: (_) {
                          setState(() {
                            selectedMode = AppLocationMode.device;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (selectedMode == AppLocationMode.manual)
                    DropdownMenu<String>(
                      key: ValueKey<String>(selectedLocationId),
                      width: double.infinity,
                      initialSelection: selectedLocationId,
                      enableFilter: true,
                      enableSearch: true,
                      requestFocusOnTap: true,
                      label: const Text('City'),
                      hintText: 'Search by city or country',
                      dropdownMenuEntries: kManualLocationPresets
                          .map(
                            (ManualLocationPreset preset) =>
                                DropdownMenuEntry<String>(
                              value: preset.id,
                              label: preset.label,
                            ),
                          )
                          .toList(growable: false),
                      onSelected: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          selectedLocationId = value;
                        });
                      },
                    )
                  else
                    Text(
                      'Use your phone location when you want prayer times to follow you automatically while you travel.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      if (selectedMode == AppLocationMode.device) {
                        await controller
                            .updateLocationMode(AppLocationMode.device);
                        await controller.refreshDeviceLocation();
                        return;
                      }

                      await controller.updateManualLocationPreset(
                        manualLocationPresetById(selectedLocationId),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Use this location'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InteractiveTinyPill extends StatelessWidget {
  const _InteractiveTinyPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = Colors.white.withValues(alpha: 0.18);
    final Color foreground = Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: background),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontSize: 11,
                        ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: foreground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: highlighted
          ? colorScheme.primaryContainer.withValues(alpha: 0.34)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: highlighted
                      ? colorScheme.primary.withValues(alpha: 0.14)
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: highlighted
                      ? colorScheme.primary
                      : colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        _TinyPill(
                          label: statusLabel,
                          icon: highlighted
                              ? Icons.check_circle_outline
                              : Icons.lock_outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color resolvedForeground = colorScheme.primary;
    final Color resolvedBackground = colorScheme.primaryContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: resolvedBackground,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 14,
              color: resolvedForeground,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: resolvedForeground,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({
    required this.status,
  });

  final NotificationHealthStatus status;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings =
        AppStrings.forCode(Localizations.localeOf(context).languageCode);
    switch (status) {
      case NotificationHealthStatus.healthy:
        return Chip(label: Text(strings.healthyLabel));
      case NotificationHealthStatus.warning:
        return Chip(label: Text(strings.needsRefreshLabel));
      case NotificationHealthStatus.critical:
        return Chip(label: Text(strings.criticalLabel));
    }
  }
}

class _NotificationReliabilityFooter extends StatelessWidget {
  const _NotificationReliabilityFooter({
    required this.controller,
    required this.notificationHealth,
  });

  final AppController controller;
  final NotificationHealth? notificationHealth;

  @override
  Widget build(BuildContext context) {
    final DateTime? coverageUntil = notificationHealth?.coverageUntil;
    final String? actionHint = notificationHealth?.actionHint;
    final List<Widget> children = <Widget>[
      if (coverageUntil != null)
        Text(
          'Scheduled through ${_formatCoverageUntil(coverageUntil)}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      if (actionHint != null && actionHint.isNotEmpty) ...<Widget>[
        if (coverageUntil != null) const SizedBox(height: 6),
        Text(
          actionHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: controller.isWorking
              ? null
              : () => controller.refreshNotifications(),
          child: const Text('Refresh prayer alerts'),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _QiblaDial extends StatelessWidget {
  const _QiblaDial({
    required this.rotationDegrees,
    required this.showingCompass,
    this.compassHeadingDegrees,
  });

  final double rotationDegrees;
  final bool showingCompass;
  final double? compassHeadingDegrees;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorScheme.primaryContainer,
            Colors.white,
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          for (final ({String label, Alignment alignment}) marker
              in <({String label, Alignment alignment})>[
            (label: 'N', alignment: Alignment.topCenter),
            (label: 'E', alignment: Alignment.centerRight),
            (label: 'S', alignment: Alignment.bottomCenter),
            (label: 'W', alignment: Alignment.centerLeft),
          ])
            Align(
              alignment: marker.alignment,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  marker.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          Container(
            width: 164,
            height: 164,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.18),
                width: 12,
              ),
            ),
          ),
          Transform.rotate(
            angle: rotationDegrees * math.pi / 180,
            child: Icon(
              Icons.navigation,
              size: 100,
              color: colorScheme.primary,
            ),
          ),
          if (showingCompass && compassHeadingDegrees != null)
            Positioned(
              bottom: 30,
              child: Text(
                'Heading ${compassHeadingDegrees!.toStringAsFixed(0)}°',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
        ],
      ),
    );
  }
}

String _formatCountdownExact(Duration duration) {
  final Duration safeDuration = duration.isNegative ? Duration.zero : duration;
  final int hours = safeDuration.inHours;
  final int minutes = safeDuration.inMinutes.remainder(60);
  final int seconds = safeDuration.inSeconds.remainder(60);
  final List<String> parts = <String>[
    if (hours > 0) '${hours}h',
    if (hours > 0 || minutes > 0) '${minutes}m',
    '${seconds}s',
  ];
  return 'in ${parts.join(' ')}';
}

String _formatTime(DateTime value) {
  final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final String minute = value.minute.toString().padLeft(2, '0');
  final String suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _formatCoverageUntil(DateTime value) {
  final String month = <String>[
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
  ][value.month - 1];
  return '$month ${value.day} at ${_formatTime(value)}';
}

String _locationBadgeLabel(AppController controller) {
  if (controller.locationMode == AppLocationMode.device) {
    return 'Phone location';
  }
  return controller.manualLocationLabel;
}

String _compassInstruction(double bearing, double heading) {
  final double turnDegrees = ((bearing - heading) + 540.0) % 360.0 - 180.0;
  if (turnDegrees.abs() < 3) {
    return 'Qibla is almost straight ahead.';
  }
  if (turnDegrees > 0) {
    return 'Turn ${turnDegrees.abs().toStringAsFixed(0)}° to your right.';
  }
  return 'Turn ${turnDegrees.abs().toStringAsFixed(0)}° to your left.';
}
