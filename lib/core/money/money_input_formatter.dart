import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';

/// Formateador de montos mientras se escriben: separa miles con `.` y
/// decimales con `,` (máximo 2).
///
/// Es tolerante con lo que escribe la persona:
/// - `1000` → `1.000`
/// - `1000.50` → `1.000,50` (un punto seguido de 1-2 dígitos se toma como
///   decimal si no hay coma; un grupo de 3 dígitos se toma como miles).
/// - `1.000.000` → `1.000.000`
/// - `1.000,5` → `1.000,5`
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  static final RegExp _nonNumeric = RegExp(r'[^\d,.]');
  static final RegExp _nonDigits = RegExp(r'[^\d]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String raw = newValue.text.replaceAll(_nonNumeric, '');
    if (raw.isEmpty) {
      return const TextEditingValue();
    }

    String entero = raw;
    String? decimales;

    final int coma = raw.lastIndexOf(',');
    if (coma >= 0) {
      entero = raw.substring(0, coma);
      decimales = raw.substring(coma + 1);
    } else {
      final int punto = raw.lastIndexOf('.');
      if (punto >= 0) {
        final String despues = raw.substring(punto + 1);
        if (despues.length <= 2) {
          entero = raw.substring(0, punto);
          decimales = despues;
        }
      }
    }

    entero = entero.replaceAll(_nonDigits, '');
    if (decimales != null) {
      decimales = decimales.replaceAll(_nonDigits, '');
      if (decimales.length > 2) {
        decimales = decimales.substring(0, 2);
      }
    }

    entero = _sinCerosIzquierda(entero);
    String texto = _agrupar(entero);
    if (decimales != null) {
      if (texto.isEmpty) {
        texto = '0';
      }
      texto = '$texto,$decimales';
    }
    if (texto.isEmpty) {
      return const TextEditingValue();
    }
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  /// Texto inicial para editar un monto ya existente: sin decimales si son
  /// cero, y sin ceros a la izquierda.
  static String format(Decimal valor) {
    final String raw = valor.abs().toString();
    final List<String> partes = raw.split('.');
    final String entero = _sinCerosIzquierda(partes.first);
    String decimales = partes.length > 1
        ? partes[1].replaceFirst(RegExp(r'0+$'), '')
        : '';
    if (decimales.length > 2) {
      decimales = decimales.substring(0, 2);
    }
    final String agrupado = _agrupar(entero);
    return decimales.isEmpty ? agrupado : '$agrupado,$decimales';
  }

  static String _sinCerosIzquierda(String digits) {
    final String sin = digits.replaceFirst(RegExp(r'^0+'), '');
    if (sin.isNotEmpty) {
      return sin;
    }
    return digits.isEmpty ? '' : '0';
  }

  static String _agrupar(String digits) {
    if (digits.isEmpty) {
      return '';
    }
    final StringBuffer salida = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        salida.write('.');
      }
      salida.write(digits[i]);
    }
    return salida.toString();
  }
}

/// Lista reutilizable para `NeoInput.inputFormatters`.
const List<TextInputFormatter> moneyInputFormatters = <TextInputFormatter>[
  MoneyInputFormatter(),
];
