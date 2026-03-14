class NotificationHealth {
  const NotificationHealth({
    required this.status,
    required this.message,
    this.coverageUntil,
    this.scheduledCount = 0,
  });

  final NotificationHealthStatus status;
  final String message;
  final DateTime? coverageUntil;
  final int scheduledCount;
}

enum NotificationHealthStatus {
  healthy,
  warning,
  critical,
}
