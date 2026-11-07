import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/money/money.dart';
import '../../domain/meta_ahorro.dart';

/// Sentido de la operación sobre una meta.
enum ModoMovimientoMeta { abono, retiro }

/// Resultado del diálogo de abono/retiro.
class MovimientoMetaValor {
  const MovimientoMetaValor({
    required this.monto,
    required this.descripcion,
  });

  final Decimal monto;
  final String descripcion;
}

/// Diálogo de abono/retiro con monto y descripción.
class MovimientoMetaDialog extends StatefulWidget {
  const MovimientoMetaDialog({
    super.key,
    required this.meta,
    required this.modo,
  });

  final MetaAhorro meta;
  final ModoMovimientoMeta modo;

  static Future<MovimientoMetaValor?> show(
    BuildContext context, {
    required MetaAhorro meta,
    required ModoMovimientoMeta modo,
  }) {
    return showDialog<MovimientoMetaValor>(
      context: context,
      builder: (_) => MovimientoMetaDialog(meta: meta, modo: modo),
    );
  }

  @override
  State<MovimientoMetaDialog> createState() => _MovimientoMetaDialogState();
}

class _MovimientoMetaDialogState extends State<MovimientoMetaDialog> {
  late final TextEditingController _monto;
  late final TextEditingController _descripcion;
  String? _errorMonto;
  String? _errorDescripcion;

  bool get _esAbono => widget.modo == ModoMovimientoMeta.abono;

  @override
  void initState() {
    super.initState();
    _monto = TextEditingController();
    _descripcion = TextEditingController(
      text: _esAbono
          ? 'Abono a ${widget.meta.nombre}'
          : 'Retiro de ${widget.meta.nombre}',
    );
  }

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _confirmar() {
    final Decimal monto;
    try {
      monto = Money.parseUserInput(_monto.text);
    } on FormatException {
      setState(() => _errorMonto = 'Ingresa un monto válido.');
      return;
    }
    if (monto <= Decimal.zero) {
      setState(() => _errorMonto = 'El monto debe ser mayor a 0.');
      return;
    }
    if (!_esAbono && monto > widget.meta.montoActual) {
      setState(
        () => _errorMonto = 'No puedes retirar más de lo ahorrado '
            '(${Money.formatClp(widget.meta.montoActual)}).',
      );
      return;
    }
    final String descripcion = _descripcion.text.trim();
    if (descripcion.isEmpty) {
      setState(() => _errorDescripcion = 'Describe la operación.');
      return;
    }
    Navigator.of(context).pop(
      MovimientoMetaValor(monto: monto.round(scale: 2), descripcion: descripcion),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return NeoDialog(
      title: _esAbono
          ? 'Abonar a ${widget.meta.nombre}'
          : 'Retirar de ${widget.meta.nombre}',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        NeoButton(
          label: _esAbono ? 'Abonar' : 'Retirar',
          onPressed: _confirmar,
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Ahorrado: ${Money.formatClp(widget.meta.montoActual)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            NeoInput(
              controller: _monto,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              label: 'Monto',
              error: _errorMonto,
            ),
            const SizedBox(height: AppSpacing.md),
            NeoInput(
              controller: _descripcion,
              label: 'Descripción',
              error: _errorDescripcion,
            ),
          ],
        ),
      ),
    );
  }
}
