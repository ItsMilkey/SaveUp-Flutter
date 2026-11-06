import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../domain/deuda.dart';
import '../domain/deudas_repository.dart';
import 'deuda_labels.dart';
import 'deudas_controller.dart';

/// Alta y edición de deuda (mismo `DeudaCreacionDTO`).
///
/// En edición se bloquea si la deuda no es editable (pagos registrados); la
/// ruta se abre solo cuando la lista/detalle lo permite, y el backend vuelve a
/// validar con 409.
class DeudaFormScreen extends ConsumerStatefulWidget {
  const DeudaFormScreen({super.key, this.deuda});

  final Deuda? deuda;

  bool get esEdicion => deuda != null;

  @override
  ConsumerState<DeudaFormScreen> createState() => _DeudaFormScreenState();
}

class _DeudaFormScreenState extends ConsumerState<DeudaFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _descripcion = TextEditingController();
  final TextEditingController _montoCapital = TextEditingController();
  final TextEditingController _cuotas = TextEditingController();
  final TextEditingController _tasa = TextEditingController();
  final TextEditingController _valorCuota = TextEditingController();
  final TextEditingController _gastos = TextEditingController();
  final TextEditingController _costoAdicional = TextEditingController();
  final TextEditingController _cuotasPrevias = TextEditingController(text: '0');

  TipoDeuda _tipo = TipoDeuda.otro;
  ModalidadCalculo _modalidad = ModalidadCalculo.sinInteres;
  bool _porFechas = false;
  bool _tasaAnual = false;
  CalendarDate? _fechaPrimera;
  CalendarDate? _fechaUltima;

  @override
  void initState() {
    super.initState();
    final Deuda? deuda = widget.deuda;
    if (deuda != null) {
      _nombre.text = deuda.nombre;
      _descripcion.text = deuda.descripcion ?? '';
      _montoCapital.text = deuda.montoCapital.toString();
      _tipo = deuda.tipo;
      _modalidad = deuda.modalidad;
      _cuotasPrevias.text = '${deuda.cuotasPagadasPrevias}';
      _fechaPrimera = deuda.fechaPrimeraCuota;
      _fechaUltima = deuda.fechaUltimaCuota;
      _porFechas = deuda.fechaPrimeraCuota != null &&
          deuda.fechaUltimaCuota != null;
      if (!_porFechas) {
        _cuotas.text = '${deuda.cantidadCuotas}';
      }
      if (deuda.modalidad == ModalidadCalculo.tasaConocida) {
        if (deuda.tasaMensual > Decimal.zero) {
          _tasaAnual = false;
          _tasa.text = deuda.tasaMensual.toString();
        } else if (deuda.tasaAnualEfectiva > Decimal.zero) {
          _tasaAnual = true;
          _tasa.text = deuda.tasaAnualEfectiva.toString();
        }
      }
      if (deuda.modalidad == ModalidadCalculo.cuotaConocida &&
          deuda.valorCuota != null) {
        _valorCuota.text = deuda.valorCuota!.toString();
      }
      if (deuda.gastosIniciales > Decimal.zero) {
        _gastos.text = deuda.gastosIniciales.toString();
      }
      if (deuda.costoAdicionalPorCuota > Decimal.zero) {
        _costoAdicional.text = deuda.costoAdicionalPorCuota.toString();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(deudaFormProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _nombre,
      _descripcion,
      _montoCapital,
      _cuotas,
      _tasa,
      _valorCuota,
      _gastos,
      _costoAdicional,
      _cuotasPrevias,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DeudaFormUiState ui = ref.watch(deudaFormProvider);
    final bool enviando = ui is DeudaFormSubmitting;

    ref.listen<DeudaFormUiState>(deudaFormProvider, (
      _,
      DeudaFormUiState next,
    ) {
      if (next is DeudaFormSuccess) {
        Navigator.of(context).pop(true);
      }
    });

    String? errorFor(String campo) => switch (ui) {
      DeudaFormFieldErrors(:final Map<String, String> errors) => errors[campo],
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar deuda' : 'Nueva deuda'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              if (ui is DeudaFormError)
                _error(context, ui.message)
              else if (ui is DeudaFormFieldErrors && ui.global != null)
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
              TextFormField(
                controller: _descripcion,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TipoDeuda>(
                initialValue: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: <DropdownMenuItem<TipoDeuda>>[
                  for (final TipoDeuda tipo in TipoDeuda.values)
                    DropdownMenuItem<TipoDeuda>(
                      value: tipo,
                      child: Text(tipoDeudaLabel(tipo)),
                    ),
                ],
                onChanged: (TipoDeuda? tipo) =>
                    setState(() => _tipo = tipo ?? TipoDeuda.otro),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ModalidadCalculo>(
                initialValue: _modalidad,
                decoration: const InputDecoration(
                  labelText: 'Modalidad',
                  prefixIcon: Icon(Icons.calculate_outlined),
                ),
                items: <DropdownMenuItem<ModalidadCalculo>>[
                  for (final ModalidadCalculo m in ModalidadCalculo.values)
                    DropdownMenuItem<ModalidadCalculo>(
                      value: m,
                      child: Text(modalidadLabel(m)),
                    ),
                ],
                onChanged: (ModalidadCalculo? m) => setState(() {
                  _modalidad = m ?? ModalidadCalculo.sinInteres;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoCapital,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateMoney,
                decoration: InputDecoration(
                  labelText: 'Capital',
                  prefixIcon: const Icon(Icons.attach_money),
                  hintText: '500.000',
                  errorText: errorFor('condiciones.montoCapital'),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(value: false, label: Text('Por cuotas')),
                  ButtonSegment<bool>(value: true, label: Text('Por fechas')),
                ],
                selected: <bool>{_porFechas},
                onSelectionChanged: (Set<bool> v) =>
                    setState(() => _porFechas = v.first),
              ),
              const SizedBox(height: 8),
              if (!_porFechas)
                TextFormField(
                  controller: _cuotas,
                  keyboardType: TextInputType.number,
                  validator: (String? v) {
                    final int? n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) {
                      return 'Ingresa el número de cuotas.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Cantidad de cuotas',
                    prefixIcon: const Icon(Icons.tag),
                    errorText: errorFor('condiciones.cantidadCuotas'),
                  ),
                )
              else ...<Widget>[
                _SelectorFecha(
                  label: 'Primera cuota',
                  fecha: _fechaPrimera,
                  onElegir: (CalendarDate f) =>
                      setState(() => _fechaPrimera = f),
                ),
                const SizedBox(height: 8),
                _SelectorFecha(
                  label: 'Última cuota',
                  fecha: _fechaUltima,
                  onElegir: (CalendarDate f) =>
                      setState(() => _fechaUltima = f),
                ),
              ],
              if (_modalidad == ModalidadCalculo.tasaConocida) ...<Widget>[
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(value: false, label: Text('Tasa mensual')),
                    ButtonSegment<bool>(value: true, label: Text('Tasa anual')),
                  ],
                  selected: <bool>{_tasaAnual},
                  onSelectionChanged: (Set<bool> v) =>
                      setState(() => _tasaAnual = v.first),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tasa,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateMoney,
                  decoration: InputDecoration(
                    labelText: _tasaAnual
                        ? 'Tasa anual efectiva (%)'
                        : 'Tasa mensual (%)',
                    helperText: 'En porcentaje: 1,5 = 1,5 %',
                    prefixIcon: const Icon(Icons.percent),
                    errorText: errorFor(
                      _tasaAnual
                          ? 'condiciones.tasaAnualEfectiva'
                          : 'condiciones.tasaMensual',
                    ),
                  ),
                ),
              ],
              if (_modalidad == ModalidadCalculo.cuotaConocida) ...<Widget>[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorCuota,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateMoney,
                  decoration: InputDecoration(
                    labelText: 'Valor de la cuota',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    errorText: errorFor('condiciones.valorCuota'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _gastos,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateMoneyOptional,
                decoration: InputDecoration(
                  labelText: 'Gastos iniciales (opcional)',
                  errorText: errorFor('condiciones.gastosIniciales'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costoAdicional,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateMoneyOptional,
                decoration: InputDecoration(
                  labelText: 'Costo adicional por cuota (opcional)',
                  errorText: errorFor('condiciones.costoAdicionalPorCuota'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cuotasPrevias,
                keyboardType: TextInputType.number,
                validator: (String? v) {
                  final int n = int.tryParse(v?.trim() ?? '0') ?? 0;
                  if (n < 0) {
                    return 'Debe ser mayor o igual a cero.';
                  }
                  if (_porFechas) {
                    return null;
                  }
                  final int? total = int.tryParse(_cuotas.text.trim());
                  if (total != null && n >= total) {
                    return 'Debe ser menor que la cantidad de cuotas.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Cuotas pagadas previas',
                  prefixIcon: const Icon(Icons.history),
                  helperText: 'No crean movimientos ni afectan el saldo.',
                  errorText: errorFor('cuotasPagadasPrevias'),
                ),
              ),
              const SizedBox(height: 20),
              _acciones(enviando),
            ],
          ),
        ),
      ),
    );
  }

  Widget _acciones(bool enviando) {
    if (enviando) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LinearProgressIndicator(),
          SizedBox(height: 8),
          Text('Guardando…'),
        ],
      );
    }
    return FilledButton(
      onPressed: _submit,
      child: Text(widget.esEdicion ? 'Guardar cambios' : 'Crear deuda'),
    );
  }

  Widget _error(BuildContext context, String message) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );

  String? _validateMoney(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresa un monto.';
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
  }

  String? _validateMoneyOptional(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return _validateMoney(value);
  }

  Decimal? _parseOpcional(TextEditingController controller) {
    final String text = controller.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return Money.parseUserInput(text);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_porFechas && (_fechaPrimera == null || _fechaUltima == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elige la fecha de la primera y de la última cuota.'),
        ),
      );
      return;
    }

    final CondicionesCredito condiciones = CondicionesCredito(
      modalidad: _modalidad,
      montoCapital: Money.parseUserInput(_montoCapital.text),
      cantidadCuotas: _porFechas ? null : int.tryParse(_cuotas.text.trim()),
      fechaPrimeraCuota: _porFechas ? _fechaPrimera : null,
      fechaUltimaCuota: _porFechas ? _fechaUltima : null,
      tasaMensual: _modalidad == ModalidadCalculo.tasaConocida && !_tasaAnual
          ? Money.parseUserInput(_tasa.text)
          : null,
      tasaAnualEfectiva:
          _modalidad == ModalidadCalculo.tasaConocida && _tasaAnual
          ? Money.parseUserInput(_tasa.text)
          : null,
      valorCuota: _modalidad == ModalidadCalculo.cuotaConocida
          ? Money.parseUserInput(_valorCuota.text)
          : null,
      gastosIniciales: _parseOpcional(_gastos),
      costoAdicionalPorCuota: _parseOpcional(_costoAdicional),
    );

    await ref
        .read(deudaFormProvider.notifier)
        .submit(
          deuda: DeudaCreacion(
            nombre: _nombre.text.trim(),
            descripcion: _descripcion.text.trim().isEmpty
                ? null
                : _descripcion.text.trim(),
            tipo: _tipo,
            cuotasPagadasPrevias:
                int.tryParse(_cuotasPrevias.text.trim()) ?? 0,
            condiciones: condiciones,
          ),
          id: widget.deuda?.id,
        );
  }
}

class _SelectorFecha extends StatelessWidget {
  const _SelectorFecha({
    required this.label,
    required this.fecha,
    required this.onElegir,
  });

  final String label;
  final CalendarDate? fecha;
  final ValueChanged<CalendarDate> onElegir;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.event, size: 18),
      label: Text(fecha == null ? label : '$label: $fecha'),
      onPressed: () async {
        final DateTime ahora = DateTime.now();
        final DateTime? elegida = await showDatePicker(
          context: context,
          initialDate:
              fecha == null
                  ? ahora
                  : DateTime(fecha!.year, fecha!.month, fecha!.day),
          firstDate: DateTime(2000),
          lastDate: DateTime(ahora.year + 30),
        );
        if (elegida != null) {
          onElegir(CalendarDate(elegida.year, elegida.month, elegida.day));
        }
      },
    );
  }
}
