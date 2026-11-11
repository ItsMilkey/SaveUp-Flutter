import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/features/auth/domain/validators.dart';

/// RUT cuyo dígito verificador termina en K, construido con la misma operación
/// del módulo 11 para no acoplar la prueba a un RUT real de persona.
String rutTerminadoEnK() {
  for (int i = 4000000; i < 4010000; i++) {
    if (rutCheckDigit('$i') == 'K') {
      return '$i-K';
    }
  }
  throw StateError('No se encontró un RUT con K.');
}

void main() {
  group('validatePassword — política de registro', () {
    test('acepta contraseñas válidas', () {
      const List<String> validas = <String>[
        'password1',
        'ab1cdefg',
        'Mi señora gusta ñoquis 1',
      ];
      for (final String contrasena in validas) {
        expect(validatePassword(contrasena), isNull, reason: contrasena);
      }
      // 64 caracteres: justo en el tope.
      expect(validatePassword('a1bcdefg' * 8), isNull);
    });

    test('rechaza vacía', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword(null), isNotNull);
    });

    test('rechaza corta (<8) y larga (>64)', () {
      expect(validatePassword('ab1cde7'), isNotNull);
      expect(validatePassword('a1bcdefg' * 8 + 'x'), isNotNull);
    });

    test('rechaza sin número y sin letra', () {
      expect(validatePassword('abcdefghi'), isNotNull);
      expect(validatePassword('123456789'), isNotNull);
    });

    test('rechaza más de 72 bytes UTF-8 (tildes y ñ pesan 2)', () {
      // 74 bytes: 35 tildes (70) + 4 ascii.
      final String excede = 'ñ' * 35 + 'a1bb';
      expect(utf8.encode(excede).length, 74);
      expect(validatePassword(excede), isNotNull);

      // Justo en 72 bytes: 32 tildes (64) + 8 ASCII = 72.
      final String justo = 'ñ' * 32 + 'a1bcdefg';
      expect(utf8.encode(justo).length, 72);
      expect(validatePassword(justo), isNull);
    });
  });

  group('validateLoginPassword — no aplica la política', () {
    test('acepta cualquier no vacía', () {
      expect(validateLoginPassword('corta'), isNull);
      expect(validateLoginPassword('12345678'), isNull);
    });

    test('rechaza vacía', () {
      expect(validateLoginPassword(''), isNotNull);
      expect(validateLoginPassword(null), isNotNull);
    });
  });

  group('validateRut', () {
    test('acepta RUT válido, con o sin puntos', () {
      final String digits = '76261480';
      final String dv = rutCheckDigit(digits);
      expect(validateRut('$digits-$dv'), isNull);
      expect(validateRut('7.6.2.6.1.4.8.0-$dv'), isNull);
      expect(validateRut(normalizeRut('$digits$dv')), isNull);
      expect(validateRut('${'12345678'}-${rutCheckDigit('12345678')}'), isNull);
    });

    test('acepta terminado en K (mayúscula o minúscula)', () {
      final String rut = rutTerminadoEnK();
      expect(validateRut(rut), isNull);
      expect(validateRut(rut.toLowerCase()), isNull);
      expect(validateRut(rut.replaceFirst('-', '')), isNull);
    });

    test('normaliza: quita puntos y espacios, mayúscula y guion', () {
      expect(normalizeRut('1.234.567 8-5'), '12345678-5');
      expect(normalizeRut('12345678k'), '12345678-K');
      expect(normalizeRut('12345678'), '1234567-8');
      expect(normalizeRut('123456789'), '12345678-9');
    });

    test('rechaza formato inválido', () {
      expect(validateRut(''), isNotNull);
      expect(validateRut('abcdef'), isNotNull);
      expect(validateRut('762614800-8'), isNotNull); // 9 dígitos
      expect(validateRut('7626148-08'), isNotNull);
      expect(validateRut('1234567 8'), isNotNull); // sin guion: se normaliza,
      // pero sobran 8 dígitos para 9 posiciones… ver caso siguiente.
      // Un RUT de 8 dígitos sin guion se normaliza a 8+DV; si el DV no
      // corresponde falla por dígito, no por formato.
      expect(validateRut(normalizeRut('123456789')), isNotNull);
    });

    test('rechaza dígito verificador incorrecto', () {
      expect(validateRut('12345678-9'), isNotNull);
      final String digits = '76261480';
      expect(
        validateRut('$digits-${rutCheckDigit(digits) == '9' ? '8' : '9'}'),
        isNotNull,
      );
    });
  });

  group('rutCheckDigit — módulo 11', () {
    test('11 → 0 y 10 → K (caso límite del módulo 11)', () {
      String? conCero;
      for (int i = 3000000; i < 3010000; i++) {
        if (rutCheckDigit('$i') == '0') {
          conCero = '$i';
          break;
        }
      }
      expect(conCero, isNotNull);
      expect(rutCheckDigit(conCero!), '0');

      final String conK = rutTerminadoEnK();
      expect(isValidRutCheckDigit(conK.split('-')[0], 'k'), isTrue);
    });
  });

  group('validateEmail', () {
    test('acepta formatos básicos y recorta bordes', () {
      expect(validateEmail('usuario@dominio.cl'), isNull);
      expect(validateEmail('  a.b+x@sub.dominio.io  '), isNull);
    });

    test('rechaza inválidos y vacíos', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail(null), isNotNull);
      expect(validateEmail('sin-arroba'), isNotNull);
      expect(validateEmail('a@b'), isNotNull);
      expect(validateEmail('a b@c.d'), isNotNull);
    });
  });

  group('validateName', () {
    test('acepta 2–50 tras recortar', () {
      expect(validateName(' María Inés ', label: 'El nombre'), isNull);
      expect(validateName('a' * 50), isNull);
    });

    test('rechaza <2 y >50', () {
      expect(validateName('a'), isNotNull);
      expect(validateName(''), isNotNull);
      expect(validateName('a' * 51), isNotNull);
    });
  });
}
