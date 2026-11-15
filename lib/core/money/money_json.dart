import 'package:decimal/decimal.dart';

/// Borde de serialización JSON del dinero.
///
/// Es el **único** lugar de la app donde se admite `num`/`double` para montos.
/// En dominio, estado y UI el dinero es siempre [Decimal].
///
/// El backend envía y recibe montos como número JSON con escala 2
/// (`12500.00`) y admite hasta 13 enteros + 2 decimales.

/// Máximo valor permitido: 10^13 (13 dígitos enteros, sin signo).
final Decimal _maxAmount = Decimal.fromInt(10000000000000);

/// Valida si [value] puede serializarse con las restricciones del contrato.
///
/// Devuelve `null` si es válido o un mensaje apto para mostrar desde un
/// validador Flutter. Por ejemplo:
/// ```dart
/// validator: (value) => value == null ? null : validateMoneyForJson(value),
/// ```
/// La escala admitida es ≤ 2 y la magnitud absoluta debe ser menor que 10^13.
String? validateMoneyForJson(Decimal value) {
  if (value.scale > 2) {
    return 'El monto no puede tener más de 2 decimales.';
  }

  if (value.abs() >= _maxAmount) {
    return 'El monto excede el máximo (13 enteros + 2 decimales).';
  }

  return null;
}

/// Convierte un [Decimal] que no representa dinero (p. ej. una tasa) a número
/// JSON sin aplicar los límites de escala y magnitud de un monto.
num decimalToJsonNumber(Decimal value) => num.parse(value.toString());

/// Convierte un número JSON (int o double) a [Decimal].
///
/// Lanza [FormatException] si el valor es `null`, un `String`, no es finito
/// (NaN/infinito) o viene en notación exponencial inesperada.
Decimal moneyFromJson(Object? value) {
  if (value is int) {
    return Decimal.parse(value.toString());
  }

  if (value is double) {
    if (value.isNaN || value.isInfinite) {
      throw FormatException('El monto no es un número finito: $value.');
    }
    final String text = value.toString();
    if (text.contains('e') || text.contains('E')) {
      throw FormatException(
        'El monto llegó en notación exponencial inesperada: $text.',
      );
    }
    return Decimal.parse(text);
  }

  throw FormatException(
    'Se esperaba un número JSON para el monto y llegó '
    '${value == null ? 'null' : value.runtimeType}.',
  );
}

/// Convierte un [Decimal] al número JSON que espera el backend.
///
/// Valida escala ≤ 2 y magnitud < 10^13; lanza [ArgumentError] si no se cumple
/// (es un error de programación, no de datos del usuario).
num moneyToJson(Decimal value) {
  final String? validationError = validateMoneyForJson(value);
  if (validationError != null) {
    throw ArgumentError.value(value, 'value', validationError);
  }

  if (value.scale == 0) {
    return value.toBigInt().toInt();
  }

  return double.parse(value.toString());
}
