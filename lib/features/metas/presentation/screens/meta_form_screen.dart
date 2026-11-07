import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/money/money.dart';
import '../../../../core/time/calendar_date.dart';
import '../../domain/meta_ahorro.dart';
import '../controllers/meta_form_controller.dart';

/// Alta y edición de una meta de ahorro (mismo `MetaAhorroCreacionDTO`).
class MetaFormScreen extends ConsumerStatefulWidget {
  const MetaFormScreen({super.key, this.meta});

  final MetaAhorro? meta;

  bool get esEdicion => meta != null;

  @override
  ConsumerState<MetaFormScreen> createState() => _MetaFormScreenState();
}

class _MetaFormScreenState extends ConsumerState<MetaFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _montoObjetivo = TextEditingController();

  CalendarDate? _fechaLimite;
  bool _esPorDefecto = false;
  String? _errorFecha;

  @override
  void initState() {
    super.initState();
    final MetaAhorro? meta = widget.meta;
    if (meta != null) {
      _nombre.text = meta.nombre;
      _montoObjetivo.text = meta.montoObjetivo?.toString() ?? '';
      _fechaLimite = meta.fechaLimite;
      _esPorDefecto = meta.esPorDefecto;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(metaFormProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _montoObjetivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MetaFormUiState ui = ref.watch(metaFormProvider);
    final bool enviando = ui is MetaFormSubmitting;
    final ThemeData theme = Theme.of(context);

    ref.listen<MetaFormUiState>(metaFormProvider, (
      _,
      MetaFormUiState next,
    ) {
      if (next is MetaFormSuccess) {
        Navigator.of(context).pop(true);
      }
    });

    String? errorFor(String campo) => switch (ui) {
      MetaFormFieldErrors(:final Map<String, String> errors) => errors[campo],
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar meta' : 'Nueva meta'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              if (ui is MetaFormError)
                _error(context, ui.message)
              else if (ui is MetaFormFieldErrors && ui.global != null)
                _error(context, ui.global!),
              TextFormField(
                controller: _nombre,
                textInputAction: TextInputAction.next,
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? 'Ponle un nombre.' : null,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: const Icon(Icons.label_outline),
                  errorText: errorFor('nombre'),
                ),
              ),
              const SizedBox(height: 12),
              if (_esPorDefecto)
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'La meta base no tiene objetivo ni fecha: solo puedes '
                      'cambiar su nombre.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                )
              else ...<Widget>[
                TextFormField(
                  controller: _montoObjetivo,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validarMonto,
                  decoration: InputDecoration(
                    labelText: 'Monto objetivo',
                    prefixText: r'$ ',
                    prefixIcon: const Icon(Icons.flag_outlined),
                    errorText: errorFor('montoObjetivo'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(
                    _fechaLimite == null
                        ? 'Fecha límite (opcional)'
                        : 'Fecha límite: $_fechaLimite',
                  ),
                  onPressed: _elegirFecha,
                ),
                if (_fechaLimite != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() {
                        _fechaLimite = null;
                        _errorFecha = null;
                      }),
                      child: const Text('Quitar fecha'),
                    ),
                  ),
                if (_errorFecha != null)
                  Text(
                    _errorFecha!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                if (errorFor('fechaLimite') != null)
                  Text(
                    errorFor('fechaLimite')!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
              ],
              const SizedBox(height: 24),
              if (enviando)
                const LinearProgressIndicator()
              else
                FilledButton(
                  onPressed: _guardar,
                  child: const Text('Guardar meta'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validarMonto(String? value) {
    if (_esPorDefecto) {
      return null;
    }
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el monto objetivo.';
    }
    try {
      final Decimal monto = Money.parseUserInput(value);
      if (monto <= Decimal.zero) {
        return 'El monto debe ser mayor a 0.';
      }
    } on FormatException {
      return 'Ingresa un monto válido.';
    }
    return null;
  }

  Future<void> _elegirFecha() async {
    final DateTime manana = DateTime.now().add(const Duration(days: 1));
    final DateTime minimo = DateTime(manana.year, manana.month, manana.day);
    DateTime inicial = minimo;
    final CalendarDate? actual = _fechaLimite;
    if (actual != null) {
      final DateTime existente = DateTime(actual.year, actual.month, actual.day);
      if (existente.isAfter(minimo)) {
        inicial = existente;
      }
    }
    final DateTime? elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: minimo,
      lastDate: DateTime(minimo.year + 30),
    );
    if (elegida != null) {
      setState(() {
        _fechaLimite = CalendarDate(
          elegida.year,
          elegida.month,
          elegida.day,
        );
        _errorFecha = null;
      });
    }
  }

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final CalendarDate? fecha = _fechaLimite;
    if (!_esPorDefecto && fecha != null && !_esFutura(fecha)) {
      setState(() => _errorFecha = 'La fecha límite debe ser futura.');
      return;
    }
    final Decimal? monto = _esPorDefecto
        ? null
        : Money.parseUserInput(_montoObjetivo.text);
    ref
        .read(metaFormProvider.notifier)
        .submit(
          datos: MetaAhorroDatos(
            nombre: _nombre.text.trim(),
            montoObjetivo: monto,
            fechaLimite: _esPorDefecto ? null : fecha,
          ),
          id: widget.meta?.id,
        );
  }

  bool _esFutura(CalendarDate fecha) {
    final DateTime ahora = DateTime.now();
    final CalendarDate hoy = CalendarDate(ahora.year, ahora.month, ahora.day);
    return fecha.compareTo(hoy) > 0;
  }

  Widget _error(BuildContext context, String mensaje) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        mensaje,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
