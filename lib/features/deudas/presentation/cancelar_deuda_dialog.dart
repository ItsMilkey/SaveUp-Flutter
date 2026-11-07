import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/money/money.dart';
import '../domain/deuda.dart';
import 'deudas_controller.dart';

/// Confirmación defensiva de cancelación (`PATCH /deudas/{id}/cancelar`).
class CancelarDeudaDialog extends ConsumerStatefulWidget {
  const CancelarDeudaDialog({super.key, required this.deuda});

  final Deuda deuda;

  static Future<bool?> show(BuildContext context, Deuda deuda) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CancelarDeudaDialog(deuda: deuda),
    );
  }

  @override
  ConsumerState<CancelarDeudaDialog> createState() =>
      _CancelarDeudaDialogState();
}

class _CancelarDeudaDialogState extends ConsumerState<CancelarDeudaDialog> {
  bool _enviando = false;
  AppFailure? _error;

  @override
  Widget build(BuildContext context) {
    return NeoDialog(
      title: '¿Cancelar la deuda?',
      actions: <Widget>[
        NeoButton(
          label: 'Volver',
          variant: NeoButtonVariant.secondary,
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
        ),
        NeoButton(
          label: 'Cancelar deuda',
          variant: NeoButtonVariant.danger,
          loading: _enviando,
          onPressed: _enviando ? null : _cancelar,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '«${widget.deuda.nombre}» quedará marcada como cancelada. '
            'No se borran los pagos ni los movimientos asociados '
            '(pendiente: ${Money.formatClp(widget.deuda.montoRestante)}).',
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: NeoErrorBand(message: failureMessage(_error!)),
            ),
        ],
      ),
    );
  }

  Future<void> _cancelar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    final AppFailure? failure = await ref
        .read(deudaAccionesProvider.notifier)
        .cancelar(widget.deuda.id);
    if (!mounted) {
      return;
    }
    if (failure != null) {
      setState(() {
        _enviando = false;
        _error = failure;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }
}
