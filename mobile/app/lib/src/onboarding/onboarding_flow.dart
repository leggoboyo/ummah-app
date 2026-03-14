import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:prayer/prayer.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../app/app_strings.dart';
import '../bootstrap/app_controller.dart';
import '../bootstrap/app_profile.dart';
import '../bootstrap/manual_location_preset.dart';
import 'world_time_zone_picker.dart';

enum _LocationSelectionMode {
  city,
  worldMap,
  device,
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  String _languageCode = 'en';
  FiqhTradition _tradition = FiqhTradition.sunni;
  SchoolOfThought _school = SchoolOfThought.shafii;
  PrayerCalculationMethod _method = PrayerCalculationMethod.muslimWorldLeague;
  AppLocationMode _locationMode = AppLocationMode.manual;
  _LocationSelectionMode _locationSelectionMode = _LocationSelectionMode.city;
  String _manualLocationId = kManualLocationPresets.first.id;
  bool _preciseAndroidAlarms = false;
  QuranStartupMode _quranStartupMode = QuranStartupMode.fullTranslation;

  static bool _timeZonesReady = false;

  @override
  void initState() {
    super.initState();
    final AppProfile profile = widget.controller.profile;
    _languageCode = _initialLanguageCode(profile);
    _tradition = profile.fiqhProfile.tradition;
    _school = profile.fiqhProfile.school;
    _method = profile.calculationMethod;
    _locationMode = profile.locationMode;
    _locationSelectionMode = profile.locationMode == AppLocationMode.device
        ? _LocationSelectionMode.device
        : _LocationSelectionMode.city;
    _manualLocationId = profile.manualLocationId;
    _preciseAndroidAlarms = profile.preciseAndroidAlarms;
    _quranStartupMode = profile.quranStartupMode;
  }

  String _initialLanguageCode(AppProfile profile) {
    if (profile.onboardingComplete) {
      return profile.languageCode;
    }

    if (profile.languageCode != AppProfile.defaults().languageCode) {
      return profile.languageCode;
    }

    final String deviceLanguage =
        SchedulerBinding.instance.platformDispatcher.locale.languageCode;
    if (deviceLanguage == 'ar' || deviceLanguage == 'ur') {
      return deviceLanguage;
    }
    return 'en';
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.forCode(_languageCode);
    final ManualLocationPreset manualPreset =
        manualLocationPresetById(_manualLocationId);

    return Directionality(
      textDirection: strings.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              _WelcomePanel(
                title: strings.welcomeTitle,
                message: strings.welcomeIntro,
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: strings.languageTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      initialValue: _languageCode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'App language',
                        border: OutlineInputBorder(),
                      ),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: 'en',
                          child: Text('English'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'ar',
                          child: Text('Arabic'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'ur',
                          child: Text('Urdu'),
                        ),
                      ],
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _languageCode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ummah App starts with your phone language when it is supported. You can change it here anytime.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _SectionCard(
                title: strings.fiqhProfileTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _OptionChip(
                          label: strings.languageCode == 'ar'
                              ? 'سني'
                              : strings.languageCode == 'ur'
                                  ? 'سنی'
                                  : 'Sunni',
                          selected: _tradition == FiqhTradition.sunni,
                          onSelected: () {
                            setState(() {
                              _tradition = FiqhTradition.sunni;
                              _school = SchoolOfThought.shafii;
                              if (_method == PrayerCalculationMethod.jafari) {
                                _method =
                                    PrayerCalculationMethod.muslimWorldLeague;
                              }
                            });
                          },
                        ),
                        _OptionChip(
                          label: strings.languageCode == 'ar'
                              ? 'شيعي'
                              : strings.languageCode == 'ur'
                                  ? 'شیعہ'
                                  : 'Shia',
                          selected: _tradition == FiqhTradition.shia,
                          onSelected: () {
                            setState(() {
                              _tradition = FiqhTradition.shia;
                              _school = SchoolOfThought.jafari;
                              _method = PrayerCalculationMethod.jafari;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.schoolHelp,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<SchoolOfThought>(
                      initialValue: _school,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: strings.schoolTitle,
                        border: const OutlineInputBorder(),
                      ),
                      items: _schoolsFor(_tradition)
                          .map(
                            (SchoolOfThought school) =>
                                DropdownMenuItem<SchoolOfThought>(
                              value: school,
                              child: Text(strings.schoolLabel(school)),
                            ),
                          )
                          .toList(),
                      onChanged: (SchoolOfThought? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _school = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _InfoBlurb(
                      title: strings.schoolLabel(_school),
                      message: strings.schoolDescription(_school),
                    ),
                  ],
                ),
              ),
              _SectionCard(
                title: strings.prayerMethodTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DropdownButtonFormField<PrayerCalculationMethod>(
                      initialValue: _method,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: strings.prayerMethodTitle,
                        border: const OutlineInputBorder(),
                      ),
                      items: PrayerCalculationMethod.values
                          .map(
                            (PrayerCalculationMethod method) =>
                                DropdownMenuItem<PrayerCalculationMethod>(
                              value: method,
                              child: Text(strings.methodLabel(method)),
                            ),
                          )
                          .toList(),
                      onChanged: (PrayerCalculationMethod? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _method = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _InfoBlurb(
                      title: strings.methodLabel(_method),
                      message: strings.methodDescription(_method),
                    ),
                  ],
                ),
              ),
              _SectionCard(
                title: strings.notificationsTitle,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.notificationsToggleTitle),
                  subtitle: Text(strings.notificationsToggleSubtitle),
                  value: _preciseAndroidAlarms,
                  onChanged: (bool value) {
                    setState(() {
                      _preciseAndroidAlarms = value;
                    });
                  },
                ),
              ),
              _SectionCard(
                title: strings.locationTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _OptionChip(
                          label: strings.manualLocationSegmentLabel,
                          selected:
                              _locationSelectionMode == _LocationSelectionMode.city,
                          onSelected: () {
                            setState(() {
                              _locationSelectionMode =
                                  _LocationSelectionMode.city;
                              _locationMode = AppLocationMode.manual;
                            });
                          },
                        ),
                        _OptionChip(
                          label: 'World Map',
                          selected: _locationSelectionMode ==
                              _LocationSelectionMode.worldMap,
                          onSelected: () {
                            setState(() {
                              _locationSelectionMode =
                                  _LocationSelectionMode.worldMap;
                              _locationMode = AppLocationMode.manual;
                            });
                          },
                        ),
                        _OptionChip(
                          label: 'Location',
                          selected:
                              _locationSelectionMode == _LocationSelectionMode.device,
                          onSelected: () {
                            setState(() {
                              _locationSelectionMode =
                                  _LocationSelectionMode.device;
                              _locationMode = AppLocationMode.device;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_locationSelectionMode == _LocationSelectionMode.city)
                      DropdownMenu<String>(
                        key: ValueKey<String>(_manualLocationId),
                        width: double.infinity,
                        initialSelection: _manualLocationId,
                        enableFilter: true,
                        enableSearch: true,
                        requestFocusOnTap: true,
                        label: Text(strings.manualLocationTitle),
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
                            _manualLocationId = value;
                          });
                        },
                      ),
                    if (_locationSelectionMode ==
                        _LocationSelectionMode.worldMap) ...<Widget>[
                      WorldTimeZonePicker(
                        bands: _worldMapBands(),
                        selectedPreset: manualPreset,
                        onPresetSelected: (ManualLocationPreset preset) {
                          setState(() {
                            _manualLocationId = preset.id;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_locationSelectionMode == _LocationSelectionMode.device)
                      Text(
                        strings.gpsLocationHelp,
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else ...<Widget>[
                      const SizedBox(height: 12),
                      _InfoBlurb(
                        title: manualPreset.label,
                        message:
                            '${strings.manualLocationHelp} ${_timeZoneLabel(manualPreset.timeZoneId)}',
                      ),
                    ],
                  ],
                ),
              ),
              _SectionCard(
                title: strings.quranSetupTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _InfoBlurb(
                      title: 'Arabic + your phone language',
                      message:
                          'The full Quran Arabic text is bundled offline. The first time you open Quran, Ummah App will also download the full translation in your phone language when one is available. Other languages can be added later.',
                    ),
                  ],
                ),
              ),
              _SectionCard(
                title: 'What you get on day one',
                child: const _SetupComparisonPanel(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.controller.isWorking
                      ? null
                      : () async {
                          await widget.controller.completeOnboarding(
                            selectedLanguageCode: _languageCode,
                            selectedFiqhProfile: FiqhProfile(
                              tradition: _tradition,
                              school: _school,
                            ),
                            selectedMethod: _method,
                            selectedLocationMode: _locationMode,
                            selectedManualLocationId: manualPreset.id,
                            selectedManualLocationLabel: manualPreset.label,
                            selectedManualTimeZoneId: manualPreset.timeZoneId,
                            selectedManualCoordinates: manualPreset.coordinates,
                            preciseAndroidAlarms: _preciseAndroidAlarms,
                            selectedQuranStartupMode: _quranStartupMode,
                          );
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(strings.continueLabel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<SchoolOfThought> _schoolsFor(FiqhTradition tradition) {
    if (tradition == FiqhTradition.shia) {
      return const <SchoolOfThought>[SchoolOfThought.jafari];
    }

    return const <SchoolOfThought>[
      SchoolOfThought.hanafi,
      SchoolOfThought.maliki,
      SchoolOfThought.shafii,
      SchoolOfThought.hanbali,
    ];
  }

  List<WorldTimeZoneBand> _worldMapBands() {
    final Map<double, List<ManualLocationPreset>> grouped =
        <double, List<ManualLocationPreset>>{};
    for (final ManualLocationPreset preset in kManualLocationPresets) {
      final double offsetHours = _timeZoneOffsetHours(preset.timeZoneId);
      grouped.putIfAbsent(offsetHours, () => <ManualLocationPreset>[]).add(
            preset,
          );
    }

    final List<double> offsets = grouped.keys.toList()..sort();
    return offsets
        .map(
          (double offsetHours) => WorldTimeZoneBand(
            utcOffsetHours: offsetHours,
            label: _utcLabel(offsetHours),
            presets: grouped[offsetHours]!..sort(
                (ManualLocationPreset a, ManualLocationPreset b) =>
                    a.city.compareTo(b.city),
              ),
          ),
        )
        .toList(growable: false);
  }

  String _timeZoneLabel(String timeZoneId) {
    _ensureTimeZonesReady();
    try {
      final tz.TZDateTime zonedNow = tz.TZDateTime.now(
        tz.getLocation(timeZoneId),
      );
      final Duration offset = zonedNow.timeZoneOffset;
      final int totalMinutes = offset.inMinutes.abs();
      final int hours = totalMinutes ~/ 60;
      final int minutes = totalMinutes % 60;
      final String sign = offset.isNegative ? '-' : '+';
      return '${zonedNow.timeZoneName} • UTC$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeZoneId;
    }
  }

  double _timeZoneOffsetHours(String timeZoneId) {
    _ensureTimeZonesReady();
    try {
      final tz.TZDateTime zonedNow = tz.TZDateTime.now(
        tz.getLocation(timeZoneId),
      );
      return zonedNow.timeZoneOffset.inMinutes / 60.0;
    } catch (_) {
      return DateTime.now().timeZoneOffset.inMinutes / 60.0;
    }
  }

  String _utcLabel(double offsetHours) {
    final bool negative = offsetHours.isNegative;
    final double absolute = offsetHours.abs();
    final int hours = absolute.floor();
    final int minutes = ((absolute - hours) * 60).round();
    final String sign = negative ? '-' : '+';
    return 'UTC$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  void _ensureTimeZonesReady() {
    if (_timeZonesReady) {
      return;
    }
    tz_data.initializeTimeZones();
    _timeZonesReady = true;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoBlurb extends StatelessWidget {
  const _InfoBlurb({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorScheme.primary.withValues(alpha: 0.96),
            const Color(0xFF2B866A),
            const Color(0xFF9BA864),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
        ],
      ),
    );
  }
}

class _SetupComparisonPanel extends StatelessWidget {
  const _SetupComparisonPanel();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        horizontalMargin: 8,
        columnSpacing: 18,
        headingRowColor: WidgetStatePropertyAll<Color>(
          colorScheme.secondaryContainer.withValues(alpha: 0.55),
        ),
        columns: const <DataColumn>[
          DataColumn(label: Text('Feature')),
          DataColumn(label: Text('Free core')),
          DataColumn(label: Text('Study')),
          DataColumn(label: Text('AI')),
          DataColumn(label: Text('Bundle')),
        ],
        rows: const <DataRow>[
          DataRow(
            cells: <DataCell>[
              DataCell(Text('Prayer times + adhan')),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
            ],
          ),
          DataRow(
            cells: <DataCell>[
              DataCell(Text('Qibla + Hijri date')),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
            ],
          ),
          DataRow(
            cells: <DataCell>[
              DataCell(Text('Quran reader + phone-language translation')),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
            ],
          ),
          DataRow(
            cells: <DataCell>[
              DataCell(Text('Fiqh starter guide')),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
            ],
          ),
          DataRow(
            cells: <DataCell>[
              DataCell(Text('Hadith library')),
              DataCell(_ComparisonMark.locked()),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.locked()),
              DataCell(_ComparisonMark.included()),
            ],
          ),
          DataRow(
            cells: <DataCell>[
              DataCell(Text('Scholar feed')),
              DataCell(_ComparisonMark.locked()),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.locked()),
              DataCell(_ComparisonMark.included()),
            ],
          ),
          DataRow(
            cells: <DataCell>[
              DataCell(Text('Ask Quran / Ask Hadith AI')),
              DataCell(_ComparisonMark.locked()),
              DataCell(_ComparisonMark.locked()),
              DataCell(_ComparisonMark.included()),
              DataCell(_ComparisonMark.included()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonMark extends StatelessWidget {
  const _ComparisonMark.included()
      : included = true,
        label = 'Included';

  const _ComparisonMark.locked()
      : included = false,
        label = 'Optional';

  final bool included;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          included ? Icons.check_circle : Icons.add_circle_outline,
          size: 16,
          color: included ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
