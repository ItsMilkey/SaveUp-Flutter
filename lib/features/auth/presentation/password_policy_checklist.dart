import 'package:flutter/material.dart';

import '../domain/validators.dart';

/// Checklist visible de la política de contraseña (reglas del backend).
///
/// Una sola copia compartida: registro, cambio de contraseña y
/// restablecimiento muestran las mismas cuatro reglas.
class PasswordPolicyChecklist extends StatelessWidget {
  const PasswordPolicyChecklist({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final PasswordCheck check = PasswordCheck.evaluate(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _check(context, check.hasLength, 'Entre 8 y 64 caracteres'),
        _check(context, check.hasLetter, 'Al menos una letra'),
        _check(context, check.hasNumber, 'Al menos un número'),
        _check(
          context,
          check.hasByteLimit,
          'Máximo 72 bytes en UTF-8 (tildes y ñ cuentan doble)',
        ),
      ],
    );
  }

  Widget _check(BuildContext context, bool ok, String label) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(
            ok ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: ok ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
