enum AlertSeverity { warning, urgent }

class Alert {
  const Alert({
    required this.severity,
    required this.title,
    required this.message,
  });

  final AlertSeverity severity;
  final String title;
  final String message;
}
