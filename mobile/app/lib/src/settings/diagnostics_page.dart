import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bootstrap/app_controller.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({
    super.key,
    required this.appController,
  });

  final AppController appController;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  List<AppLogEntry> _entries = const <AppLogEntry>[];
  bool _isLoading = true;
  bool _isCopying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<AppLogEntry> entries =
          await widget.appController.loadDiagnosticsEntries();
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = entries.reversed.toList(growable: false);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copyReport() async {
    setState(() {
      _isCopying = true;
    });
    try {
      final String report = await widget.appController.buildDiagnosticsReport();
      await Clipboard.setData(ClipboardData(text: report));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support report copied to the clipboard.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCopying = false;
        });
      }
    }
  }

  Future<void> _clearLogs() async {
    await widget.appController.clearDiagnosticsEntries();
    await _loadEntries();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Local diagnostics log cleared on this device.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppController appController = widget.appController;

    return AnimatedBuilder(
      animation: appController,
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Diagnostics & Support'),
            actions: <Widget>[
              IconButton(
                onPressed: _isLoading ? null : _loadEntries,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh diagnostics',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Device support snapshot',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          Chip(
                              label:
                                  Text(appController.environment.buildLabel)),
                          Chip(
                              label: Text(
                                  appController.billingProviderKind.label)),
                          Chip(
                            label: Text(
                              appController.notificationHealth?.status.name ??
                                  'notifications unknown',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        appController.subscriptionStatusMessage ??
                            'Billing status has not been loaded yet.',
                      ),
                      const SizedBox(height: 8),
                      Text('Location: ${appController.locationSummary}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.tonal(
                        onPressed: _isCopying ? null : _copyReport,
                        child: const Text('Copy support report'),
                      ),
                      FilledButton.tonal(
                        onPressed: appController.isWorking
                            ? null
                            : appController.refreshNotifications,
                        child: const Text('Refresh notifications'),
                      ),
                      FilledButton.tonal(
                        onPressed: appController.isWorking ? null : _clearLogs,
                        child: const Text('Clear local logs'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null) ...<Widget>[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    title: const Text('Diagnostics error'),
                    subtitle: Text(_errorMessage!),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Local log history',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _entries.isEmpty
                            ? 'No local log entries are stored yet.'
                            : '${_entries.length} entries stored on this device.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_entries.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('Nothing to review yet'),
                    subtitle: Text(
                      'Once the app records warnings or state changes, they will appear here.',
                    ),
                  ),
                )
              else
                for (final AppLogEntry entry in _entries) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        title: Text(entry.message),
                        subtitle: Text(
                          '${entry.level.name.toUpperCase()} • ${_formatDateTime(entry.timestamp)}${entry.error == null ? '' : '\n${entry.error}'}',
                        ),
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
}

String _formatDateTime(DateTime value) {
  final DateTime local = value.toLocal();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
