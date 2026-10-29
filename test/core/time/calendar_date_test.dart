import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/time/calendar_date.dart';

void main() {
  group('CalendarDate.parse', () {
    test('parsea yyyy-MM-dd', () {
      final CalendarDate date = CalendarDate.parse('2026-10-22');

      expect(date.year, 2026);
      expect(date.month, 10);
      expect(date.day, 22);
    });

    test('serializa con toJson y toString', () {
      final CalendarDate date = CalendarDate.parse('2026-01-05');

      expect(date.toJson(), '2026-01-05');
      expect(date.toString(), '2026-01-05');
    });

    test('acepta el 29 de febrero de un año bisiesto', () {
      expect(
        CalendarDate.parse('2024-02-29').toJson(),
        '2024-02-29',
      );
    });

    test('rechaza el 29 de febrero de un año no bisiesto', () {
      expect(
        () => CalendarDate.parse('2025-02-29'),
        throwsFormatException,
      );
    });

    test('rechaza meses y días fuera de rango', () {
      expect(() => CalendarDate.parse('2026-13-01'), throwsFormatException);
      expect(() => CalendarDate.parse('2026-04-31'), throwsFormatException);
      expect(() => CalendarDate.parse('2026-00-10'), throwsFormatException);
    });

    test('rechaza formatos distintos a yyyy-MM-dd', () {
      expect(() => CalendarDate.parse('22-10-2026'), throwsFormatException);
      expect(() => CalendarDate.parse('2026-10-22T00:00:00Z'),
          throwsFormatException);
      expect(() => CalendarDate.parse('2026/10/22'), throwsFormatException);
      expect(() => CalendarDate.parse(''), throwsFormatException);
    });

    test('rellena con ceros a la izquierda', () {
      expect(CalendarDate(999, 1, 2).toString(), '0999-01-02');
    });
  });

  group('comparación', () {
    test('dos fechas iguales son iguales', () {
      expect(CalendarDate(2026, 10, 22), CalendarDate(2026, 10, 22));
      expect(
        CalendarDate(2026, 10, 22).hashCode,
        CalendarDate(2026, 10, 22).hashCode,
      );
    });

    test('ordena por año, mes y día', () {
      final List<CalendarDate> dates = <CalendarDate>[
        CalendarDate(2026, 10, 22),
        CalendarDate(2025, 12, 31),
        CalendarDate(2026, 9, 30),
        CalendarDate(2026, 10, 1),
      ]..sort();

      expect(
        dates.map((CalendarDate date) => date.toString()).toList(),
        <String>[
          '2025-12-31',
          '2026-09-30',
          '2026-10-01',
          '2026-10-22',
        ],
      );
    });
  });
}
