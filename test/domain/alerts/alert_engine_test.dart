import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/domain/alerts/alert.dart';
import 'package:nurture/domain/alerts/alert_engine.dart';
import 'package:nurture/domain/alerts/symptom_rules.dart';

void main() {
  final engine = AlertEngine([
    SymptomRedFlagRule(
      redFlagMessages: {
        'heavy_bleeding': 'Heavy bleeding needs urgent assessment.',
        'severe_headache': 'Severe headache is a warning sign.',
      },
    ).rule,
  ]);

  test('red-flag symptom produces urgent alert', () {
    final alert = engine.evaluate(
      const SymptomLogged(typeKey: 'heavy_bleeding'),
    );
    expect(alert, isNotNull);
    expect(alert!.severity, AlertSeverity.urgent);
    expect(alert.message, contains('urgent assessment'));
  });

  test('common symptom produces no alert', () {
    expect(engine.evaluate(const SymptomLogged(typeKey: 'nausea')), isNull);
  });

  test('highest severity wins when multiple rules fire', () {
    final multi = AlertEngine([
      (e) => const Alert(
        severity: AlertSeverity.warning,
        title: 'w',
        message: 'w',
      ),
      (e) =>
          const Alert(severity: AlertSeverity.urgent, title: 'u', message: 'u'),
    ]);
    expect(multi.evaluate(Object())!.severity, AlertSeverity.urgent);
  });

  test('ignores unrelated event types', () {
    expect(engine.evaluate('not a symptom'), isNull);
  });
}
