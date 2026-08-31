import 'alert.dart';

typedef AlertRule = Alert? Function(Object event);

/// Evaluates every rule against a saved event and returns the highest
/// severity alert produced, or null. Pure and synchronous.
class AlertEngine {
  AlertEngine(this.rules);

  final List<AlertRule> rules;

  Alert? evaluate(Object event) {
    Alert? worst;
    for (final rule in rules) {
      final alert = rule(event);
      if (alert == null) continue;
      if (worst == null || alert.severity.index > worst.severity.index) {
        worst = alert;
      }
    }
    return worst;
  }
}
