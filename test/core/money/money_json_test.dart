import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/money/money_json.dart';

void main() {
  group('moneyFromJson', () {
    test('acepta un entero JSON', () {
      expect(moneyFromJson(12500), Decimal.fromInt(12500));
    });

    test('acepta un double JSON con dos decimales', () {
      expect(moneyFromJson(1234.56), Decimal.parse('1234.56'));
    });

    test('acepta negativos', () {
      expect(moneyFromJson(-1234.56), Decimal.parse('-1234.56'));
    });

    test('rechaza null', () {
      expect(() => moneyFromJson(null), throwsFormatException);
    });

    test('rechaza un String', () {
      expect(() => moneyFromJson('12500.00'), throwsFormatException);
    });

    test('rechaza NaN', () {
      expect(() => moneyFromJson(double.nan), throwsFormatException);
    });

    test('rechaza infinito', () {
      expect(() => moneyFromJson(double.infinity), throwsFormatException);
    });

    test('rechaza notación exponencial', () {
      expect(() => moneyFromJson(1e21), throwsFormatException);
    });
  });

  group('moneyToJson', () {
    test('rechaza más de 2 decimales', () {
      expect(() => moneyToJson(Decimal.parse('1.999')), throwsArgumentError);
    });

    test('rechaza montos de 10^13 o más', () {
      expect(
        () => moneyToJson(Decimal.parse('10000000000000')),
        throwsArgumentError,
      );
    });

    test('acepta el máximo permitido', () {
      final Decimal max = Decimal.parse('9999999999999.99');

      expect(moneyFromJson(moneyToJson(max)), max);
    });

    test('envía enteros como int', () {
      expect(moneyToJson(Decimal.fromInt(12500)), isA<int>());
    });

    test('envía decimales como número', () {
      expect(moneyToJson(Decimal.parse('1234.56')), 1234.56);
    });
  });

  group('ida y vuelta', () {
    const List<String> values = <String>[
      '0.00',
      '0.01',
      '0.10',
      '1234.56',
      '12500.00',
      '9999999999999.99',
      '-1234.56',
      '-0.01',
      '-9999999999999.99',
    ];

    for (final String value in values) {
      test('preserva el monto $value', () {
        final Decimal original = Decimal.parse(value);

        expect(moneyFromJson(moneyToJson(original)), original);
      });
    }

    test('preserva 200 valores aleatorios de escala 2', () {
      final Random random = Random(42);

      for (int i = 0; i < 200; i++) {
        final int whole = random.nextInt(1000000000);
        final int cents = random.nextInt(100);
        final String sign = random.nextBool() ? '' : '-';
        final String raw = '$sign$whole.${cents.toString().padLeft(2, '0')}';
        final Decimal original = Decimal.parse(raw);

        expect(
          moneyFromJson(moneyToJson(original)),
          original,
          reason: 'valor $raw',
        );
      }
    });
  });
}
