import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../domain/plan_mensual.dart';
import '../controllers/plan_mensual_controller.dart';

/// Registra un gasto imputado a una partida del plan.
///
/// Es el camino de "Pagar" de la lista de partidas: crea un `GASTO_GENERAL`
/// con `partidaId` (`POST /movimientos`) y el backend se encarga de la
/// categoría y de sumarlo al `real` de la partida. El monto viene precargado
/// con lo que falta para cubrir el plan, pero se puede editar para registrar
/// pagos parciales (por ejemplo, varias visitas al supermercado).
class PartidaPagoDialog extends ConsumerStatefulWidget {
  const PartidaPagoDialog({super.key, required this.partida});

  final PartidaPlan partida;

  static Future<bool?> show(
    BuildContext context, {
    required PartidaPlan partida,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PartidaPagoDialog(partida: partida),
    );
  }

  @override
  ConsumerState<PartidaPagoDialog> createState() => _PartidaPagoDialogState();
}

class _PartidaPagoDialogState extends ConsumerState<PartidaPagoDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _monto;
  late final TextEditingController _descripcion;
  bool _enviando = false;
  AppFailure? _error;

  @override
  void initState() {
    super.initState();
    _monto = TextEditingController(text: _montoInicial(widget.partida));
    _descripcion = TextEditingController(text: widget.partida.nombre);
  }

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PartidaPlan partida = widget.partida;
    return NeoDialog(
      title: 'Pagar ${partida.nombre}',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
        ),
        NeoButton(
          label: 'Pagar',
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
                'Usado ${Money.formatClp(partida.real)} de '
                '${Money.formatClp(partida.montoPlanificado)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _monto,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (String? value) {
                  final String text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Ingresa el monto.';
                  }
                  try {
                    if (Money.parseUserInput(text) <= Decimal.zero) {
                      return 'Debe ser mayor que cero.';
                    }
                  } on FormatException {
                    return 'Monto inválido.';
                  }
                  return null;
                },
                label: 'Monto',
                prefixIcon: Icons.attach_money,
                inputFormatters: moneyInputFormatters,
              ),
              const SizedBox(height: AppSpacing.sm),
              NeoInput(
                controller: _descripcion,
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                    ? 'Escribe una descripción.'
                    : null,
                label: 'Descripción',
                prefixIcon: Icons.notes,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Se registrará un gasto en Movimientos, imputado a esta '
                'partida.',
                style: theme.textTheme.bodySmall,
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
        .read(planMensualProvider.notifier)
        .registrarGastoPartida(
          partidaId: widget.partida.id,
          monto: Money.parseUserInput(_monto.text),
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
    Navigator.of(context).pop(true);
  }

  /// Lo que falta para cubrir el plan; si ya está cubierto, el plan completo.
  static String _montoInicial(PartidaPlan partida) {
    final Decimal restante = partida.montoPlanificado - partida.real;
    final Decimal inicial = restante > Decimal.zero
        ? restante
        : partida.montoPlanificado;
    if (inicial <= Decimal.zero) {
      return '';
    }
    return MoneyInputFormatter.format(inicial);
  }
}
