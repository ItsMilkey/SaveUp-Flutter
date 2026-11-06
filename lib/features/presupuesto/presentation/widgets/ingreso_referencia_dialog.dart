import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/money/money.dart';

/// Resultado del diálogo de ingreso de referencia: [monto] nulo = quitarlo.
class IngresoReferenciaValor {
  const IngresoReferenciaValor(this.monto);

  final Decimal? monto;
}

/// Edita el ingreso de referencia del plan (`PUT /planes/{mes}/ingreso-referencia`).
class IngresoReferenciaDialog extends StatefulWidget {
  const IngresoReferenciaDialog({super.key, this.actual});

  final Decimal? actual;

  static Future<IngresoReferenciaValor?> show(
    BuildContext context, {
    Decimal? actual,
  }) {
    return showDialog<IngresoReferenciaValor>(
      context: context,
      builder: (_) => IngresoReferenciaDialog(actual: actual),
    );
  }

  @override
  State<IngresoReferenciaDialog> createState() =>
      _IngresoReferenciaDialogState();
}

class _IngresoReferenciaDialogState extends State<IngresoReferenciaDialog> {
  late final TextEditingController _monto;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _monto = TextEditingController(
      text: widget.actual == null ? '' : widget.actual!.toString(),
    );
  }

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ingreso de referencia'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _monto,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s$]')),
              ],
              validator: (String? value) {
                final String text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Ingresa el monto o usa "Quitar".';
                }
                try {
                  final Decimal monto = Money.parseUserInput(text);
                  if (monto < Decimal.zero) {
                    return 'No puede ser negativo.';
                  }
                } on FormatException {
                  return 'Monto inválido.';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Ingreso mensual',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Se usa para calcular el remanente y el margen de seguridad.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const IngresoReferenciaValor(null)),
          child: const Text('Quitar'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }
            Navigator.of(context).pop(
              IngresoReferenciaValor(Money.parseUserInput(_monto.text)),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
