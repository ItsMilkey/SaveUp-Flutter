/// Patrón de un instante ISO-8601 con zona explícita (`Z` u offset).
final RegExp _zoneSuffix = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

/// Parseaa un instante ISO-8601 **con zona** y lo devuelve en UTC.
///
/// El backend envía instantes terminados en `Z` (por ejemplo
/// `2026-10-22T12:15:00.000Z`). Se aceptan también offsets explícitos
/// (`-03:00`), que se convierten a UTC.
///
/// Lanza [FormatException] si falta la zona, la fecha es inválida o el texto
/// está vacío: interpretar una fecha de calendario como instante es un error.
DateTime parseInstant(String raw) {
  final String text = raw.trim();
  if (text.isEmpty) {
    throw const FormatException('El instante está vacío.');
  }
  if (!_zoneSuffix.hasMatch(text)) {
    throw FormatException(
      'El instante debe incluir zona horaria (por ejemplo "...Z"): "$raw".',
      raw,
    );
  }

  final DateTime? parsed = DateTime.tryParse(text);
  if (parsed == null) {
    throw FormatException('Instante inválido: "$raw".', raw);
  }

  return parsed.toUtc();
}

/// Serializa un instante como ISO-8601 UTC con sufijo `Z`.
///
/// Es el formato que espera el backend para `fecha`, `desde` y `hasta`.
String formatInstant(DateTime instant) => instant.toUtc().toIso8601String();
