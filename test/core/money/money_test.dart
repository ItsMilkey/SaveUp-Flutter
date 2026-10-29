import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/money/money.dart';

void main() {
  group('Money.parseUserInput', () {
    test('parsea un decimal con punto', () {
      expect(Money.parseUserInput('1234.50'), Decimal.parse('1234.5'));
    });

    test('acepta coma como separador decimal', () {
      expect(Money.parseUserInput('1234,50'), Decimal.parse('1234.5'));
    });

    test('acepta separador de miles con puntos', () {
      expect(Money.parseUserInput('1.234.567'), Decimal.fromInt(1234567));
    });

    test('interpreta un único punto con grupos de 3 como miles', () {
      expect(Money.parseUserInput('12.500'), Decimal.fromInt(12500));
    });

    test('acepta punto de miles y coma decimal', () {
      expect(Money.parseUserInput('12.500,75'), Decimal.parse('12500.75'));
    });

    test('acepta coma de miles y punto decimal', () {
      expect(Money.parseUserInput('12,500.75'), Decimal.parse('12500.75'));
    });

    test('acepta símbolo de peso y espacios', () {
      expect(Money.parseUserInput(r' $ 1.234 '), Decimal.fromInt(1234));
    });

    test('mantiene el cero inicial como decimal', () {
      expect(Money.parseUserInput('0.123'), Decimal.parse('0.123'));
    });

    test('acepta montos negativos', () {
      expect(Money.parseUserInput('-12.500'), Decimal.fromInt(-12500));
    });

    test('rechaza un texto vacío', () {
      expect(() => Money.parseUserInput('   '), throwsFormatException);
    });

    test('rechaza texto que no es un monto', () {
      expect(() => Money.parseUserInput('mil pesos'), throwsFormatException);
    });

    test('rechaza notación científica', () {
      expect(() => Money.parseUserInput('1e3'), throwsFormatException);
    });
  });

  group('Money.formatClp', () {
    test('formatea un monto entero con separador de miles', () {
      expect(Money.formatClp(Decimal.fromInt(1234567)), r'$1.234.567');
    });

    test('formatea cero', () {
      expect(Money.formatClp(Decimal.zero), r'$0');
    });

    test('redondea a peso sin usar double', () {
      expect(Money.formatClp(Decimal.parse('1234.4')), r'$1.234');
      expect(Money.formatClp(Decimal.parse('1234.5')), r'$1.235');
    });

    test('formatea montos negativos', () {
      expect(Money.formatClp(Decimal.parse('-1234')), r'-$1.234');
    });

    test('mantiene precisión en montos grandes', () {
      expect(Money.formatClp(Decimal.parse('123456789.99')), r'$123.456.790');
    });
  });
}
