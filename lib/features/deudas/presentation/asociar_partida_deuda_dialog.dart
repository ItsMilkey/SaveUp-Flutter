import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/time/business_month.dart';
import '../domain/deuda.dart';
import 'deudas_controller.dart';

/// Crea la partida del plan del mes en curso vinculada a una deuda ya creada.
///
/// El nombre viene precargado con el de la deuda; el monto y la categoría los
/// deriva el backend desde la cuota (la app no los envía).
class AsociarPartidaDeudaDialog extends ConsumerStatefulWidget {
  const AsociarPartidaDeudaDialog({super.key, required this.deuda});

  final Deuda deuda;

  static Future<bool?> show(BuildContext context, {required Deuda deuda}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AsociarPartidaDeudaDialog(deuda: deuda),
    );
  }

  @override
  ConsumerState<AsociarPartidaDeudaDialog> createState() =>
      _AsociarPartidaDeudaDialogState();
}

class _AsociarPartidaDeudaDialogState
    extends ConsumerState<AsociarPartidaDeudaDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  bool _enviando = false;
  AppFailure? _error;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.deuda.nombre);
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String mes = BusinessMonth.fromInstant(DateTime.now()).toString();
    return NeoDialog(
      title: 'Asociar al plan',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
        ),
        NeoButton(
          label: 'Crear partida',
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
                'Se creará una partida en el plan de $mes con el monto de la '
                'cuota de esta deuda (categoría Pago de Deudas).',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _nombre,
                autofocus: true,
                validator: (String? value) {
                  final String text = value?.trim() ?? '';
                  if (text.isEmpty || text.length > 80) {
                    return 'Entre 1 y 80 caracteres.';
                  }
                  return null;
                },
                label: 'Nombre de la partida',
                prefixIcon: Icons.label_outline,
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
        .asociarPartida(widget.deuda.id, nombre: _nombre.text.trim());
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
