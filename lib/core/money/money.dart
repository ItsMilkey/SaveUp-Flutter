import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Utilidades de dinero.
///
/// El backend envía los montos como string decimal para no perder precisión
/// al pasar por JSON. Aquí se convierten a [Decimal] y se formatean como CLP.
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

  /// Convierte un monto del backend (string decimal) a [Decimal].
  ///
  /// Acepta enteros y decimales con punto o coma (`"1234.50"`, `"1234,50"`),
  /// porque el formato exacto está pendiente de confirmar con el backend.
  /// TODO: fijar el separador decimal aceptado cuando esté documentado en
  /// `docs/CLIENTE_FLUTTER.md` del backend.
  ///
  /// Lanza [FormatException] si el valor no es un decimal válido.
  static Decimal parse(String rawAmount) {
    final String normalized = rawAmount.trim().replaceAll(',', '.');

    if (normalized.isEmpty) {
      throw const FormatException('El monto está vacío.');
    }

    return Decimal.parse(normalized);
  }

  /// Formatea un monto como pesos chilenos, sin decimales y con separador
  /// de miles (`$1.234.567`).
  ///
  /// El redondeo a peso se hace sobre [Decimal] (nunca con `double`).
  /// TODO: confirmar con el backend la regla de redondeo de CLP (hoy se usa
  /// el redondeo half-up por defecto de `decimal`).
  static String formatClp(Decimal amount) {
    final Decimal rounded = amount.round(scale: 0);

    return _clpFormat.format(rounded.toBigInt().toInt());
  }
}
