import 'package:flutter/services.dart';

/// Formatea el RUT mientras se escribe: deja solo dígitos/K, en mayúscula,
/// y agrega el guion antes del dígito verificador cuando el cuerpo ya tiene
/// 7 u 8 dígitos (8 o 9 caracteres en total).
///
/// - `123456789` → `12345678-9`
/// - `12345678k` → `12345678-K`
/// - `12.345.678-9` → `12345678-9`
class RutInputFormatter extends TextInputFormatter {
  const RutInputFormatter();

  static final RegExp _invalid = RegExp(r'[^\dkK]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String raw = newValue.text.replaceAll(_invalid, '').toUpperCase();
    if (raw.length > 9) {
      raw = raw.substring(0, 9);
    }
    final String texto;
    if (raw.length >= 8) {
      texto =
          '${raw.substring(0, raw.length - 1)}-${raw.substring(raw.length - 1)}';
    } else {
      texto = raw;
    }
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Lista reutilizable para `NeoInput.inputFormatters`.
const List<TextInputFormatter> rutInputFormatters = <TextInputFormatter>[
  RutInputFormatter(),
];
