import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Utilidades de dinero para **datos escritos por la persona**.
///
/// Los montos que vienen del backend **no** se parsean aquí: viajan como número
/// JSON con escala 2 y se leen con `moneyFromJson` (`money_json.dart`).
///
/// Regla del proyecto: el dinero nunca se representa con `double`.
class Money {
  const Money._();

  /// `intl` ubica el símbolo al final del monto para `es_CL` ("1.234 $"),
  /// pero la convención local es con el símbolo delante ("$1.234"), de ahí
  /// el `customPattern`.
  static final NumberFormat _clpFormat = NumberFormat.currency(
    locale: 'es_CL',
    symbol: r'$',
    decimalDigits: 0,
    customPattern: '\u00A4#,##0',
  );

  static final RegExp _numericPattern = RegExp(r'^-?\d+(\.\d+)?$');
  static final RegExp _spacesAndCurrency = RegExp(r'[\s$]');

  /// Interpreta un monto escrito por la persona, de forma tolerante.
  ///
  /// Acepta:
  /// - punto o coma como separador decimal (`"1234,50"`, `"1234.50"`);
  /// - separador de miles con puntos (`"1.234.567"`, `"$1.234.567"`);
  /// - signo negativo (`"-12.500"`).
  ///
  /// Lanza [FormatException] si el texto no es un monto válido.
  static Decimal parseUserInput(String raw) {
    String text = raw.trim().replaceAll(_spacesAndCurrency, '');
    if (text.isEmpty) {
      throw const FormatException('El monto está vacío.');
    }

    final bool hasComma = text.contains(',');
    final bool hasDot = text.contains('.');

    if (hasComma && hasDot) {
      // El último separador que aparece es el decimal; el otro es de miles.
      final bool commaIsDecimal = text.lastIndexOf(',') > text.lastIndexOf('.');
      text = commaIsDecimal
          ? text.replaceAll('.', '').replaceAll(',', '.')
          : text.replaceAll(',', '');
    } else if (hasComma) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasDot) {
      final List<String> groups = text.split('.');
      final bool looksLikeThousands = groups.length > 1 &&
          groups.first != '0' &&
          groups.skip(1).every((String group) => group.length == 3);
      if (looksLikeThousands) {
        text = groups.join();
      }
    }

    if (!_numericPattern.hasMatch(text)) {
      throw FormatException('Monto inválido: "$raw".', raw);
    }

    return Decimal.parse(text);
  }

  /// Formatea un monto como pesos chilenos, sin decimales y con separador
  /// de miles (`$1.234.567`).
  ///
  /// El redondeo a peso se hace sobre [Decimal] (nunca con `double`).
  /// TODO: confirmar con producto si algún caso debe mostrar centavos.
  static String formatClp(Decimal amount) {
    final Decimal rounded = amount.round(scale: 0);

    return _clpFormat.format(rounded.toBigInt().toInt());
  }
}
