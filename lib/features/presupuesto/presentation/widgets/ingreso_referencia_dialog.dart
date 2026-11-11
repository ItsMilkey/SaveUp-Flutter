import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/money_input_formatter.dart';

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
      text: widget.actual == null
          ? ''
          : MoneyInputFormatter.format(widget.actual!),
    );
  }

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeoDialog(
      title: 'Ingreso de referencia',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        NeoButton(
          label: 'Quitar',
          variant: NeoButtonVariant.ghost,
          onPressed: () =>
              Navigator.of(context).pop(const IngresoReferenciaValor(null)),
        ),
        NeoButton(
          label: 'Guardar',
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }
            Navigator.of(context).pop(
              IngresoReferenciaValor(Money.parseUserInput(_monto.text)),
            );
          },
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeoInput(
              controller: _monto,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              label: 'Ingreso mensual',
              prefixIcon: Icons.attach_money,
              inputFormatters: moneyInputFormatters,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Se usa para calcular el remanente y el margen de seguridad.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
