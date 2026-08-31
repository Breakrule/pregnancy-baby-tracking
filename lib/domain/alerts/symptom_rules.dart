import 'alert.dart';
import 'alert_engine.dart';

/// Event emitted when a symptom is saved.
class SymptomLogged {
  const SymptomLogged({required this.typeKey});
  final String typeKey;
}

class SymptomRedFlagRule {
  SymptomRedFlagRule({required this.redFlagMessages});

  /// key -> urgent message, loaded from red_flags.json.
  final Map<String, String> redFlagMessages;

  AlertRule get rule => (event) {
    if (event is! SymptomLogged) return null;
    final message = redFlagMessages[event.typeKey];
    if (message == null) return null;
    return Alert(
      severity: AlertSeverity.urgent,
      title: 'Contact your provider',
      message: message,
    );
  };
}
