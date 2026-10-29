import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/time/instants.dart';

void main() {
  group('parseInstant', () {
    test('parsea un instante UTC con Z', () {
      expect(
        parseInstant('2026-10-22T12:15:00.000Z'),
        DateTime.utc(2026, 10, 22, 12, 15),
      );
    });

    test('convierte un offset explícito a UTC', () {
      expect(
        parseInstant('2026-10-22T09:15:00-03:00'),
        DateTime.utc(2026, 10, 22, 12, 15),
      );
    });

    test('convierte un offset positivo a UTC', () {
      expect(
        parseInstant('2026-10-22T12:15:00+02:00'),
        DateTime.utc(2026, 10, 22, 10, 15),
      );
    });

    test('rechaza un instante sin zona', () {
      expect(
        () => parseInstant('2026-10-22T12:15:00'),
        throwsFormatException,
      );
    });

    test('rechaza una fecha de calendario', () {
      expect(() => parseInstant('2026-10-22'), throwsFormatException);
    });

    test('rechaza un texto vacío', () {
      expect(() => parseInstant('  '), throwsFormatException);
    });

    test('rechaza basura', () {
      expect(() => parseInstant('mañana'), throwsFormatException);
    });
  });

  group('formatInstant', () {
    test('serializa en ISO-8601 UTC con Z', () {
      expect(
        formatInstant(DateTime.utc(2026, 10, 22, 12, 15)),
        '2026-10-22T12:15:00.000Z',
      );
    });

    test('conserva los milisegundos', () {
      expect(
        formatInstant(DateTime.utc(2026, 1, 2, 3, 4, 5, 678)),
        '2026-01-02T03:04:05.678Z',
      );
    });

    test('hace ida y vuelta', () {
      final DateTime instant = DateTime.utc(2026, 3, 4, 5, 6, 7, 89);

      expect(parseInstant(formatInstant(instant)), instant);
    });
  });
}
