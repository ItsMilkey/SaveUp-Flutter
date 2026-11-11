import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/features/auth/presentation/rut_input_formatter.dart';

TextEditingValue formatear(String texto) {
  return const RutInputFormatter().formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(text: texto),
  );
}

void main() {
  test('agrega el guion en RUT de 8 dígitos más DV', () {
    expect(formatear('123456789').text, '12345678-9');
    expect(formatear('12345678k').text, '12345678-K');
  });

  test('agrega el guion en RUT de 7 dígitos más DV', () {
    expect(formatear('12345675').text, '1234567-5');
    expect(formatear('1234567K').text, '1234567-K');
  });

  test('limpia puntos y guiones y deja la K en mayúscula', () {
    expect(formatear('12.345.678-9').text, '12345678-9');
    expect(formatear('12.345.678-k').text, '12345678-K');
  });

  test('no inventa el guion antes de tener un DV', () {
    expect(formatear('1234567').text, '1234567');
    expect(formatear('1').text, '1');
  });
}
