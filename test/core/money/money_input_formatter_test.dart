import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/money/money_input_formatter.dart';

TextEditingValue formatear(String texto) {
  return const MoneyInputFormatter().formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(text: texto),
  );
}

void main() {
  test('agrupa los miles con punto', () {
    expect(formatear('1000').text, '1.000');
    expect(formatear('1000000').text, '1.000.000');
    expect(formatear('123').text, '123');
    expect(formatear('0').text, '0');
  });

  test('interpreta y conserva decimales con coma', () {
    expect(formatear('1000.50').text, '1.000,50');
    expect(formatear('1.000,5').text, '1.000,5');
    expect(formatear('1234,567').text, '1.234,56');
    expect(formatear('1.000.000').text, '1.000.000');
  });

  test('format de montos existentes evita decimales vacíos', () {
    expect(
      MoneyInputFormatter.format(Decimal.parse('400000.00')),
      '400.000',
    );
    expect(MoneyInputFormatter.format(Decimal.parse('1234.50')), '1.234,5');
    expect(MoneyInputFormatter.format(Decimal.parse('0.00')), '0');
  });
}
