import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/time/business_month.dart';
import 'package:saveup_app/core/time/time_zones.dart';

void main() {
  setUpAll(initializeTimeZones);

  test('un instante de madrugada UTC cae en el mes anterior en Santiago', () {
    final BusinessMonth month =
        BusinessMonth.fromInstant(DateTime.utc(2026, 2, 1, 2));

    expect(month, const BusinessMonth(2026, 1));
  });

  test('los límites del mes usan horario de verano en enero', () {
    const BusinessMonth month = BusinessMonth(2026, 1);

    expect(month.startUtc, DateTime.utc(2026, 1, 1, 3));
    expect(month.endUtc, DateTime.utc(2026, 2, 1, 3));
  });

  test('los límites del mes usan horario de invierno en junio', () {
    const BusinessMonth month = BusinessMonth(2026, 6);

    expect(month.startUtc, DateTime.utc(2026, 6, 1, 4));
    expect(month.endUtc, DateTime.utc(2026, 7, 1, 4));
  });

  test('el cambio de horario de septiembre no rompe el mes', () {
    const BusinessMonth month = BusinessMonth(2026, 9);

    expect(month.startUtc, DateTime.utc(2026, 9, 1, 4));
    expect(month.endUtc, DateTime.utc(2026, 10, 1, 3));
  });

  test('el cambio de horario de abril no rompe el mes', () {
    const BusinessMonth month = BusinessMonth(2026, 4);

    expect(month.startUtc, DateTime.utc(2026, 4, 1, 3));
    expect(month.endUtc, DateTime.utc(2026, 5, 1, 4));
  });

  test('contains usa el rango semiabierto [inicio, fin)', () {
    const BusinessMonth month = BusinessMonth(2026, 1);

    expect(month.contains(DateTime.utc(2026, 1, 1, 3)), isTrue);
    expect(month.contains(DateTime.utc(2026, 2, 1, 2, 59)), isTrue);
    expect(month.contains(DateTime.utc(2026, 1, 1, 2, 59)), isFalse);
    expect(month.contains(DateTime.utc(2026, 2, 1, 3)), isFalse);
  });

  test('el inicio del mes pertenece a ese mes', () {
    for (int monthNumber = 1; monthNumber <= 12; monthNumber++) {
      final BusinessMonth month = BusinessMonth(2026, monthNumber);

      expect(
        BusinessMonth.fromInstant(month.startUtc),
        month,
        reason: 'mes $monthNumber',
      );
    }
  });

  test('ordena cronológicamente', () {
    final List<BusinessMonth> months = <BusinessMonth>[
      const BusinessMonth(2026, 2),
      const BusinessMonth(2025, 12),
      const BusinessMonth(2026, 1),
    ]..sort();

    expect(months, <BusinessMonth>[
      const BusinessMonth(2025, 12),
      const BusinessMonth(2026, 1),
      const BusinessMonth(2026, 2),
    ]);
  });
}
