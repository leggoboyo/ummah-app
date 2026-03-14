enum AppLogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogEntry {
  const AppLogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  final AppLogLevel level;
  final String message;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;
}

abstract interface class AppLogger {
  Future<void> log(
    AppLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  Future<List<AppLogEntry>> entries();
}

class InMemoryAppLogger implements AppLogger {
  InMemoryAppLogger({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final List<AppLogEntry> _entries = <AppLogEntry>[];

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
        message: message,
        timestamp: _clock(),
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
