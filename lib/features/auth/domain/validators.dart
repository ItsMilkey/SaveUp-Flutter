import 'dart:convert';

/// Validadores puros de los datos de cuenta.
///
/// Las reglas vienen del contrato del backend (`docs/contrato/openapi.json` y
/// `CLIENTE_FLUTTER.md`) y de `docs/CONTEXT.md`. Devuelven el mensaje de error
/// en español listo para mostrar, o `null` si el valor es válido.

/// Mínimo de caracteres de una contraseña (política del backend).
const int passwordMinLength = 8;

/// Máximo de caracteres de una contraseña (política del backend).
const int passwordMaxLength = 64;

/// Máximo de bytes UTF-8 que BCrypt cifra sin truncar.
const int passwordMaxBytes = 72;

final RegExp _letterPattern = RegExp(r'[A-Za-z]');
final RegExp _digitPattern = RegExp(r'\d');
final RegExp _rutPattern = RegExp(r'^\d{7,8}-[\dkK]$');
final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Resultado de evaluar la política de contraseña regla por regla.
///
/// La pantalla de registro lo usa como checklist visible.
class PasswordCheck {
  const PasswordCheck({
    required this.hasLength,
    required this.hasLetter,
    required this.hasNumber,
    required this.hasByteLimit,
  });

  /// Evalúa [value] contra las cuatro reglas del contrato.
  factory PasswordCheck.evaluate(String value) {
    return PasswordCheck(
      hasLength:
          value.length >= passwordMinLength &&
          value.length <= passwordMaxLength,
      hasLetter: _letterPattern.hasMatch(value),
      hasNumber: _digitPattern.hasMatch(value),
      hasByteLimit: utf8.encode(value).length <= passwordMaxBytes,
    );
  }

  /// Entre 8 y 64 caracteres.
  final bool hasLength;

  /// Al menos una letra.
  final bool hasLetter;

  /// Al menos un número.
  final bool hasNumber;

  /// Máximo 72 bytes en UTF-8 (tildes y 'ñ' pesan 2 bytes).
  final bool hasByteLimit;

  /// `true` solo si se cumplen todas las reglas.
  bool get isValid => hasLength && hasLetter && hasNumber && hasByteLimit;
}

/// Valida la política completa de contraseña.
String? validatePassword(String? value) {
  final String text = value ?? '';
  if (text.isEmpty) {
    return 'Ingresa una contraseña.';
  }

  final PasswordCheck check = PasswordCheck.evaluate(text);
  if (!check.hasLength) {
    return 'La contraseña debe tener entre $passwordMinLength y '
        '$passwordMaxLength caracteres.';
  }
  if (!check.hasByteLimit) {
    return 'La contraseña es demasiado larga: usa máximo $passwordMaxBytes '
        'bytes (las tildes y la ñ cuentan doble).';
  }
  if (!check.hasLetter || !check.hasNumber) {
    return 'La contraseña debe incluir al menos una letra y un número.';
  }
  return null;
}

/// Valida una contraseña de login.
///
/// El login **no** aplica la política: el backend compara contra el hash tal
/// cual. Solo se exige que no esté vacía para no enviar una petición inútil.
String? validateLoginPassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Ingresa tu contraseña.';
  }
  return null;
}

/// Normaliza un RUT: quita puntos y espacios, pasa la K a mayúscula y agrega
/// el guion si el usuario escribió solo dígitos (cuerpo de 7 u 8 dígitos, con
/// o sin K final).
String normalizeRut(String raw) {
  String text = raw.replaceAll(RegExp(r'[.\s]'), '').toUpperCase();
  final bool sinGuion = !text.contains('-');
  if (sinGuion &&
      (text.length == 8 || text.length == 9) &&
      RegExp(r'^\d{7,8}[\dkK]$').hasMatch(text)) {
    text =
        '${text.substring(0, text.length - 1)}-'
        '${text.substring(text.length - 1)}';
  }
  return text;
}

/// Valida un RUT chileno: formato `12345678-9` y dígito verificador (módulo 11).
String? validateRut(String? value) {
  final String text = normalizeRut(value ?? '');
  if (text.isEmpty) {
    return 'Ingresa tu RUT.';
  }
  if (!_rutPattern.hasMatch(text)) {
    return 'Usa el formato 12345678-9, sin puntos.';
  }

  final List<String> parts = text.split('-');
  if (!isValidRutCheckDigit(parts[0], parts[1])) {
    return 'El RUT no es válido.';
  }
  return null;
}

/// Calcula el dígito verificador (módulo 11) de [digits] como `0`–`9` o `K`.
String rutCheckDigit(String digits) {
  int sum = 0;
  int multiplier = 2;
  for (int i = digits.length - 1; i >= 0; i--) {
    sum += int.parse(digits[i]) * multiplier;
    multiplier = multiplier == 7 ? 2 : multiplier + 1;
  }
  final int remainder = 11 - (sum % 11);
  if (remainder == 11) {
    return '0';
  }
  if (remainder == 10) {
    return 'K';
  }
  return '$remainder';
}

/// `true` si [checkDigit] es el dígito verificador de [digits].
bool isValidRutCheckDigit(String digits, String checkDigit) {
  return rutCheckDigit(digits) == checkDigit.toUpperCase();
}

/// Valida un correo con formato básico (`usuario@dominio.cl`).
String? validateEmail(String? value) {
  final String text = (value ?? '').trim();
  if (text.isEmpty) {
    return 'Ingresa tu correo.';
  }
  if (!_emailPattern.hasMatch(text)) {
    return 'Ingresa un correo válido.';
  }
  return null;
}

/// Valida nombre o apellido: 2 a 50 caracteres tras recortar espacios.
String? validateName(String? value, {String label = 'Este campo'}) {
  final String text = (value ?? '').trim();
  if (text.length < 2) {
    return '$label debe tener al menos 2 caracteres.';
  }
  if (text.length > 50) {
    return '$label debe tener máximo 50 caracteres.';
  }
  return null;
}
