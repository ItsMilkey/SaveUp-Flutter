import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_input_formatter.dart';
import '../../../core/time/business_month.dart';
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
  final TextEditingController _cuotaFija = TextEditingController();
  final TextEditingController _cantidadCuotasBasicas = TextEditingController();
  final TextEditingController _tasa = TextEditingController();
  final TextEditingController _valorCuota = TextEditingController();
  final TextEditingController _gastos = TextEditingController();
  final TextEditingController _costoAdicional = TextEditingController();
  final TextEditingController _cuotasPrevias = TextEditingController(text: '0');

  TipoDeuda _tipo = TipoDeuda.otro;
  ModalidadCalculo _modalidad = ModalidadCalculo.sinInteres;
  bool _porFechas = false;
  bool _tasaAnual = false;
  bool _crearPartida = false;
  bool _modoBasico = true;
  bool _successHandled = false;
  CalendarDate? _fechaCuotaFija;
  CalendarDate? _fechaPrimera;
  CalendarDate? _fechaUltima;

  @override
  void initState() {
    super.initState();
    final Deuda? deuda = widget.deuda;
    if (deuda != null) {
      _modoBasico = false;
      _nombre.text = deuda.nombre;
      _descripcion.text = deuda.descripcion ?? '';
      _montoCapital.text = MoneyInputFormatter.format(deuda.montoCapital);
      _tipo = deuda.tipo;
      _modalidad = deuda.modalidad;
      _cuotasPrevias.text = '${deuda.cuotasPagadasPrevias}';
      _fechaPrimera = deuda.fechaPrimeraCuota;
      _fechaUltima = deuda.fechaUltimaCuota;
      _porFechas =
          deuda.fechaPrimeraCuota != null && deuda.fechaUltimaCuota != null;
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
        _valorCuota.text = MoneyInputFormatter.format(deuda.valorCuota!);
      }
      if (deuda.gastosIniciales > Decimal.zero) {
        _gastos.text = MoneyInputFormatter.format(deuda.gastosIniciales);
      }
      if (deuda.costoAdicionalPorCuota > Decimal.zero) {
        _costoAdicional.text = MoneyInputFormatter.format(
          deuda.costoAdicionalPorCuota,
        );
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
      _cuotaFija,
      _cantidadCuotasBasicas,
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
    final String mesPlan = BusinessMonth.fromInstant(DateTime.now()).toString();
    final bool hayCalendario = _hayCalendario;

    ref.listen<DeudaFormUiState>(deudaFormProvider, (_, DeudaFormUiState next) {
      if (next is DeudaFormSuccess && !_successHandled) {
        _successHandled = true;
        if (!widget.esEdicion && _modoBasico) {
          unawaited(_completarAltaBasica(next));
        } else {
          _cerrarConAviso(next);
        }
      }
    });

    String? errorFor(String campo) => switch (ui) {
      DeudaFormFieldErrors(:final Map<String, String> errors) => errors[campo],
      _ => null,
    };

    return NeoScaffold(
      appBar: NeoAppBar(
        title: widget.esEdicion ? 'Editar deuda' : 'Nueva deuda',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              if (ui is DeudaFormError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: NeoErrorBand(message: ui.message),
                )
              else if (ui is DeudaFormFieldErrors && ui.global != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: NeoErrorBand(message: ui.global!),
                ),
              NeoInput(
                controller: _nombre,
                textInputAction: TextInputAction.next,
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? 'Ponle un nombre.' : null,
                label: 'Nombre',
                prefixIcon: Icons.label_outline,
                error: errorFor('nombre'),
              ),
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _descripcion,
                label: 'Descripción (opcional)',
                prefixIcon: Icons.notes,
              ),
              const SizedBox(height: AppSpacing.md),
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
              if (!widget.esEdicion) ...<Widget>[
                SegmentedButton<bool>(
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(value: true, label: Text('Básico')),
                    ButtonSegment<bool>(value: false, label: Text('Avanzado')),
                  ],
                  selected: <bool>{_modoBasico},
                  onSelectionChanged: enviando
                      ? null
                      : (Set<bool> value) => setState(() {
                          // Los controladores de ambos formularios y sus fechas se
                          // conservan al alternar; no se descartan valores escritos.
                          _modoBasico = value.single;
                        }),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_modoBasico) ...<Widget>[
                NeoCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(Icons.info_outline),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Cuota fija sin interés adicional. Usa este modo '
                          'cuando el monto de cada cuota sea fijo y no haya '
                          'costos separados.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                NeoInput(
                  controller: _cuotaFija,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateMoney,
                  label: 'Monto de cada cuota',
                  hint: '15.000',
                  prefixIcon: Icons.payments_outlined,
                  inputFormatters: moneyInputFormatters,
                  error: errorFor('cuotaFija.valorCuota'),
                ),
                const SizedBox(height: AppSpacing.md),
                NeoInput(
                  controller: _cantidadCuotasBasicas,
                  keyboardType: TextInputType.number,
                  validator: _validateBasicCount,
                  label: 'Cantidad de cuotas',
                  prefixIcon: Icons.tag,
                  error: errorFor('cuotaFija.cantidadCuotas'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SelectorFecha(
                  label: 'Primera cuota (opcional)',
                  fecha: _fechaCuotaFija,
                  onElegir: (CalendarDate fecha) =>
                      setState(() => _fechaCuotaFija = fecha),
                ),
                if (_fechaCuotaFija != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _fechaCuotaFija = null;
                      }),
                      icon: const Icon(Icons.close),
                      label: const Text('Quitar fecha'),
                    ),
                  ),
                if (errorFor('cuotaFija.fechaPrimeraCuota') != null)
                  Text(
                    errorFor('cuotaFija.fechaPrimeraCuota')!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ] else ...<Widget>[
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
                const SizedBox(height: AppSpacing.md),
                NeoInput(
                  controller: _montoCapital,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateMoney,
                  label: 'Capital',
                  hint: '500.000',
                  prefixIcon: Icons.attach_money,
                  inputFormatters: moneyInputFormatters,
                  error: errorFor('condiciones.montoCapital'),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<bool>(
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Por cuotas'),
                    ),
                    ButtonSegment<bool>(value: true, label: Text('Por fechas')),
                  ],
                  selected: <bool>{_porFechas},
                  onSelectionChanged: (Set<bool> v) =>
                      setState(() => _porFechas = v.first),
                ),
                const SizedBox(height: 8),
                if (!_porFechas)
                  NeoInput(
                    controller: _cuotas,
                    keyboardType: TextInputType.number,
                    validator: (String? v) {
                      final int? n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0) {
                        return 'Ingresa el número de cuotas.';
                      }
                      return null;
                    },
                    label: 'Cantidad de cuotas',
                    prefixIcon: Icons.tag,
                    error: errorFor('condiciones.cantidadCuotas'),
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
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Tasa mensual'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Tasa anual'),
                      ),
                    ],
                    selected: <bool>{_tasaAnual},
                    onSelectionChanged: (Set<bool> v) =>
                        setState(() => _tasaAnual = v.first),
                  ),
                  const SizedBox(height: 8),
                  NeoInput(
                    controller: _tasa,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateMoney,
                    label: _tasaAnual
                        ? 'Tasa anual efectiva (%)'
                        : 'Tasa mensual (%)',
                    helper: 'En porcentaje: 1,5 = 1,5 %',
                    prefixIcon: Icons.percent,
                    error: errorFor(
                      _tasaAnual
                          ? 'condiciones.tasaAnualEfectiva'
                          : 'condiciones.tasaMensual',
                    ),
                  ),
                ],
                if (_modalidad == ModalidadCalculo.cuotaConocida) ...<Widget>[
                  const SizedBox(height: 12),
                  NeoInput(
                    controller: _valorCuota,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateMoney,
                    label: 'Valor de la cuota',
                    prefixIcon: Icons.payments_outlined,
                    inputFormatters: moneyInputFormatters,
                    error: errorFor('condiciones.valorCuota'),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                NeoInput(
                  controller: _gastos,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateMoneyOptional,
                  label: 'Gastos iniciales (opcional)',
                  inputFormatters: moneyInputFormatters,
                  error: errorFor('condiciones.gastosIniciales'),
                ),
                const SizedBox(height: AppSpacing.md),
                NeoInput(
                  controller: _costoAdicional,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateMoneyOptional,
                  label: 'Costo adicional por cuota (opcional)',
                  inputFormatters: moneyInputFormatters,
                  error: errorFor('condiciones.costoAdicionalPorCuota'),
                ),
                const SizedBox(height: AppSpacing.md),
                NeoInput(
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
                  label: 'Cuotas pagadas previas',
                  helper: 'No crean movimientos ni afectan el saldo.',
                  prefixIcon: Icons.history,
                  error: errorFor('cuotasPagadasPrevias'),
                ),
              ],
              if (!widget.esEdicion && hayCalendario) ...[
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  value: _crearPartida,
                  onChanged: (bool value) =>
                      setState(() => _crearPartida = value),
                  contentPadding: EdgeInsets.zero,
                  title: Text('Crear partida en el plan de $mesPlan'),
                  subtitle: Text(
                    'Asocia esta deuda al plan del mes con el monto de la cuota.',
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              _acciones(enviando),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hayCalendario => _modoBasico
      ? _fechaCuotaFija != null
      : _porFechas && _fechaPrimera != null && _fechaUltima != null;

  void _cerrarConAviso(DeudaFormSuccess success) {
    final String? aviso = success.avisoPartida;
    if (aviso != null) {
      NeoSnackbar.show(context, aviso, tone: NeoSnackbarTone.warning);
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _completarAltaBasica(DeudaFormSuccess success) async {
    final Deuda deuda = success.deuda;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Deuda creada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Monto de cada cuota: ${deuda.valorCuota == null ? 'No informado' : Money.formatClp(deuda.valorCuota!)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Total informado por el servidor: ${Money.formatClp(deuda.montoTotal)}',
            ),
            const SizedBox(height: 8),
            Text('Plazo: ${deuda.cantidadCuotas} cuotas'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (mounted) {
      _cerrarConAviso(success);
    }
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
    return NeoButton(
      label: widget.esEdicion ? 'Guardar cambios' : 'Crear deuda',
      expanded: true,
      onPressed: _submit,
    );
  }

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

  String? _validateBasicCount(String? value) {
    final int? count = int.tryParse(value?.trim() ?? '');
    if (count == null) {
      return 'Ingresa la cantidad de cuotas.';
    }
    if (count < 1 || count > 360) {
      return 'La cantidad debe estar entre 1 y 360.';
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
    if (!_modoBasico &&
        _porFechas &&
        (_fechaPrimera == null || _fechaUltima == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elige la fecha de la primera y de la última cuota.'),
        ),
      );
      return;
    }

    final DeudaCreacion creacion;
    if (_modoBasico) {
      creacion = DeudaCreacion(
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim().isEmpty
            ? null
            : _descripcion.text.trim(),
        tipo: _tipo,
        cuotaFija: CuotaFija(
          valorCuota: Money.parseUserInput(_cuotaFija.text),
          cantidadCuotas: int.parse(_cantidadCuotasBasicas.text.trim()),
          fechaPrimeraCuota: _fechaCuotaFija,
        ),
      );
    } else {
      creacion = DeudaCreacion(
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim().isEmpty
            ? null
            : _descripcion.text.trim(),
        tipo: _tipo,
        cuotasPagadasPrevias: int.tryParse(_cuotasPrevias.text.trim()) ?? 0,
        condiciones: CondicionesCredito(
          modalidad: _modalidad,
          montoCapital: Money.parseUserInput(_montoCapital.text),
          cantidadCuotas: _porFechas ? null : int.tryParse(_cuotas.text.trim()),
          fechaPrimeraCuota: _porFechas ? _fechaPrimera : null,
          fechaUltimaCuota: _porFechas ? _fechaUltima : null,
          tasaMensual:
              _modalidad == ModalidadCalculo.tasaConocida && !_tasaAnual
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
        ),
      );
    }

    await ref
        .read(deudaFormProvider.notifier)
        .submit(
          deuda: creacion,
          id: widget.deuda?.id,
          crearPartida: _crearPartida && _hayCalendario,
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
          initialDate: fecha == null
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
