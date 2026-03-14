import 'package:core/core.dart';

class DiagnosticsRedactor {
  const DiagnosticsRedactor._();

  static final RegExp _appUserIdPattern = RegExp(r'ummah_[0-9a-f]{32}');
  static final RegExp _coordinatePairPattern = RegExp(
    r'-?\d{1,3}\.\d{3,}\s*,\s*-?\d{1,3}\.\d{3,}',
  );
  static final RegExp _apiKeyPattern = RegExp(r'sk-[A-Za-z0-9_-]{16,}');
  static final RegExp _bearerTokenPattern =
      RegExp(r'Bearer\s+[A-Za-z0-9._-]{12,}');

  static String redactText(String value) {
    return value
        .replaceAll(_appUserIdPattern, 'ummah_[redacted]')
        .replaceAll(_coordinatePairPattern, '[coordinates redacted]')
        .replaceAll(_apiKeyPattern, '[api-key redacted]')
        .replaceAll(_bearerTokenPattern, 'Bearer [redacted]');
  }

  static Object? redactError(Object? error) {
    if (error == null) {
      return null;
    }
    return redactText('$error');
  }

  static StackTrace? redactStackTrace(StackTrace? stackTrace) {
    if (stackTrace == null) {
      return null;
    }
    final List<String> lines = redactText(stackTrace.toString())
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .take(8)
        .toList(growable: false);
    if (lines.isEmpty) {
      return null;
    }
    return StackTrace.fromString(lines.join('\n'));
  }

  static String formatCoordinates(
    Coordinates coordinates, {
    required bool includeSensitiveDetails,
  }) {
    if (!includeSensitiveDetails) {
      return 'Redacted in the standard support report.';
    }
    return '${coordinates.latitude.toStringAsFixed(4)}, '
        '${coordinates.longitude.toStringAsFixed(4)}';
  }

  static String formatIdentifier(
    String? value, {
    required bool includeSensitiveDetails,
  }) {
    if (value == null || value.isEmpty) {
      return 'Not generated';
    }
    if (!includeSensitiveDetails) {
      return 'Redacted in the standard support report.';
    }
    return value;
  }
}
