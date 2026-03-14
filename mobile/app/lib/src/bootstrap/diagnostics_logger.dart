import 'dart:convert';

import 'package:core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'diagnostics_redactor.dart';

abstract interface class DiagnosticsLogger implements AppLogger {
  Future<void> clear();
}

class PersistentDiagnosticsLogger implements DiagnosticsLogger {
  PersistentDiagnosticsLogger({
    SharedPreferencesAsync? preferences,
    DateTime Function()? clock,
  })  : _preferences = preferences ?? SharedPreferencesAsync(),
        _clock = clock ?? DateTime.now;

  static const String _storageKey = 'diagnostics_log_v1';
  static const int _maxEntries = 200;

  final SharedPreferencesAsync _preferences;
  final DateTime Function() _clock;

  @override
  Future<void> clear() async {
    await _preferences.remove(_storageKey);
  }

  @override
  Future<List<AppLogEntry>> entries() async {
    final String? raw = await _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const <AppLogEntry>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_entryFromJson)
          .toList(growable: false);
    } catch (_) {
      return const <AppLogEntry>[];
    }
  }

  @override
  Future<void> log(
    AppLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final List<AppLogEntry> current = await entries();
    final AppLogEntry nextEntry = AppLogEntry(
      level: level,
      message: DiagnosticsRedactor.redactText(message),
      timestamp: _clock(),
      error: DiagnosticsRedactor.redactError(error),
      stackTrace: DiagnosticsRedactor.redactStackTrace(stackTrace),
    );
    final List<Map<String, Object?>> encoded = <AppLogEntry>[
      ...current,
      nextEntry
    ]
        .skip(current.length + 1 > _maxEntries
            ? current.length + 1 - _maxEntries
            : 0)
        .map(_entryToJson)
        .toList(growable: false);
    await _preferences.setString(_storageKey, jsonEncode(encoded));
  }

  Map<String, Object?> _entryToJson(AppLogEntry entry) {
    return <String, Object?>{
      'level': entry.level.name,
      'message': entry.message,
      'timestamp': entry.timestamp.toIso8601String(),
      'error': entry.error?.toString(),
      'stackTrace': entry.stackTrace?.toString(),
    };
  }

  AppLogEntry _entryFromJson(Map<String, dynamic> json) {
    final AppLogLevel level = AppLogLevel.values.firstWhere(
      (AppLogLevel value) => value.name == json['level'],
      orElse: () => AppLogLevel.info,
    );
    return AppLogEntry(
      level: level,
      message: json['message'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      error: json['error'],
      stackTrace: json['stackTrace'] == null
          ? null
          : StackTrace.fromString(json['stackTrace'] as String),
    );
  }
}

class InMemoryDiagnosticsLogger implements DiagnosticsLogger {
  InMemoryDiagnosticsLogger({
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final List<AppLogEntry> _entries = <AppLogEntry>[];

  @override
  Future<void> clear() async {
    _entries.clear();
  }

  @override
  Future<List<AppLogEntry>> entries() async {
    return List<AppLogEntry>.unmodifiable(_entries);
  }

  @override
  Future<void> log(
    AppLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    _entries.add(
      AppLogEntry(
        level: level,
        message: DiagnosticsRedactor.redactText(message),
        timestamp: _clock(),
        error: DiagnosticsRedactor.redactError(error),
        stackTrace: DiagnosticsRedactor.redactStackTrace(stackTrace),
      ),
    );
  }
}
