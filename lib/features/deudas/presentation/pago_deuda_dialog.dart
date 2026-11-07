import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/money/money.dart';
import '../../movimientos/presentation/movimientos_controller.dart';
import '../domain/deuda.dart';
import '../domain/pago_deuda.dart';
import 'deudas_controller.dart';

/// Diálogo para registrar un pago (`CUOTA_CALCULADA` o monto libre).
class PagoDeudaDialog extends ConsumerStatefulWidget {
  const PagoDeudaDialog({super.key, required this.deuda});

  final Deuda deuda;

  static Future<bool?> show(BuildContext context, Deuda deuda) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PagoDeudaDialog(deuda: deuda),
    );
  }

  @override
  ConsumerState<PagoDeudaDialog> createState() => _PagoDeudaDialogState();
}

class _PagoDeudaDialogState extends ConsumerState<PagoDeudaDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _monto;
  late final TextEditingController _descripcion;
  ModoPago _modo = ModoPago.cuotaCalculada;
  bool _enviando = false;
  AppFailure? _error;

  @override
  void initState() {
    super.initState();
    final String cuota = widget.deuda.proximaCuotaNumero == null
        ? ''
        : 'Cuota ${widget.deuda.proximaCuotaNumero}';
    _descripcion = TextEditingController(
      text: cuota.isEmpty ? 'Pago de deuda' : 'Pago $cuota',
    );
    _monto = TextEditingController(
      text: widget.deuda.proximaCuotaMontoPendiente?.toString() ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(deudaAccionesProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Decimal pendiente =
        widget.deuda.proximaCuotaMontoPendiente ?? widget.deuda.montoRestante;

    return NeoDialog(
      title: 'Registrar pago',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
        ),
        NeoButton(
          label: 'Registrar pago',
          loading: _enviando,
          onPressed: _enviando ? null : _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Próxima cuota: ${Money.formatClp(pendiente)} '
                '· saldo capital ${Money.formatClp(widget.deuda.saldoCapital)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<ModoPago>(
                segments: const <ButtonSegment<ModoPago>>[
                  ButtonSegment<ModoPago>(
                    value: ModoPago.cuotaCalculada,
                    label: Text('Cuota'),
                  ),
                  ButtonSegment<ModoPago>(
                    value: ModoPago.montoPersonalizado,
                    label: Text('Otro monto'),
                  ),
                ],
                selected: <ModoPago>{_modo},
                onSelectionChanged: (Set<ModoPago> v) =>
                    setState(() => _modo = v.first),
              ),
              if (_modo == ModoPago.montoPersonalizado) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                NeoInput(
                  controller: _monto,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (String? value) {
                    final String text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Ingresa el monto.';
                    }
                    try {
                      final Decimal monto = Money.parseUserInput(text);
                      if (monto <= Decimal.zero) {
                        return 'Debe ser mayor que cero.';
                      }
                    } on FormatException {
                      return 'Monto inválido.';
                    }
                    return null;
                  },
                  label: 'Monto',
                  prefixIcon: Icons.attach_money,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _descripcion,
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                    ? 'Escribe una descripción.'
                    : null,
                label: 'Descripción',
                prefixIcon: Icons.notes,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: NeoErrorBand(message: failureMessage(_error!)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    final AppFailure? failure = await ref
        .read(deudaAccionesProvider.notifier)
        .pagar(
          widget.deuda.id,
          monto: _modo == ModoPago.montoPersonalizado
              ? Money.parseUserInput(_monto.text)
              : null,
          modo: _modo,
          descripcion: _descripcion.text.trim(),
        );
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
    // El backend ya creó el PAGO_DEUDA: refrescar movimientos/saldo.
    await ref.read(movimientosProvider.notifier).refrescar();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
