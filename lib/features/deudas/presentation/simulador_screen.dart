import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../domain/deuda.dart';
import '../domain/simulacion.dart';
import 'deuda_labels.dart';
import 'deudas_controller.dart';

/// Simulador de crédito (`POST /simulaciones/credito`, no persiste nada).
class SimuladorScreen extends ConsumerStatefulWidget {
  const SimuladorScreen({super.key});

  @override
  ConsumerState<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends ConsumerState<SimuladorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _capital = TextEditingController();
  final TextEditingController _cuotas = TextEditingController(text: '12');
  final TextEditingController _tasa = TextEditingController();
  final TextEditingController _valorCuota = TextEditingController();
  final TextEditingController _gastos = TextEditingController();
  final TextEditingController _costoAdicional = TextEditingController();
  final TextEditingController _ingreso = TextEditingController();
  final TextEditingController _alternativas = TextEditingController();

  ModalidadCalculo _modalidad = ModalidadCalculo.tasaConocida;
  bool _porFechas = false;
  bool _tasaAnual = false;
  bool _incluirTabla = true;
  CalendarDate? _fechaPrimera;
  CalendarDate? _fechaUltima;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(simulacionProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _capital,
      _cuotas,
      _tasa,
      _valorCuota,
      _gastos,
      _costoAdicional,
      _ingreso,
      _alternativas,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SimulacionUiState ui = ref.watch(simulacionProvider);
    final bool enviando = ui is SimulacionSubmitting;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Simulador de crédito')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Calcula cuánto te costaría un crédito antes de tomarlo. '
              'No se guarda nada.',
              style: theme.textTheme.bodySmall,
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
              onChanged: (ModalidadCalculo? m) => setState(
                () => _modalidad = m ?? ModalidadCalculo.tasaConocida,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _capital,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _moneyRequerido,
              decoration: const InputDecoration(
                labelText: 'Capital',
                prefixIcon: Icon(Icons.attach_money),
                hintText: '500.000',
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
                  return (n == null || n <= 0) ? 'Ingresa las cuotas.' : null;
                },
                decoration: const InputDecoration(
                  labelText: 'Cantidad de cuotas',
                  prefixIcon: Icon(Icons.tag),
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
                validator: _moneyRequerido,
                decoration: InputDecoration(
                  labelText: _tasaAnual
                      ? 'Tasa anual efectiva (%)'
                      : 'Tasa mensual (%)',
                  helperText: 'En porcentaje: 1,5 = 1,5 %',
                  prefixIcon: const Icon(Icons.percent),
                ),
              ),
            ],
            if (_modalidad == ModalidadCalculo.cuotaConocida) ...<Widget>[
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorCuota,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _moneyRequerido,
                decoration: const InputDecoration(
                  labelText: 'Valor de la cuota',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _gastos,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _moneyOpcional,
              decoration: const InputDecoration(
                labelText: 'Gastos iniciales (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costoAdicional,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _moneyOpcional,
              decoration: const InputDecoration(
                labelText: 'Costo adicional por cuota (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ingreso,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _moneyOpcional,
              decoration: const InputDecoration(
                labelText: 'Ingreso mensual (opcional)',
                helperText: 'Para el resumen educativo',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _alternativas,
              decoration: const InputDecoration(
                labelText: 'Plazos alternativos (opcional)',
                helperText: 'Máximo 5, separados por coma: 12, 24, 36',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Incluir tabla de amortización'),
              value: _incluirTabla,
              onChanged: (bool v) => setState(() => _incluirTabla = v),
            ),
            const SizedBox(height: 8),
            if (enviando)
              const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  LinearProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Calculando…'),
                ],
              )
            else
              FilledButton(
                onPressed: _simular,
                child: const Text('Simular'),
              ),
            if (ui is SimulacionError) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                ui.message,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (ui is SimulacionSuccess) ...<Widget>[
              const SizedBox(height: 16),
              _Resultado(resultado: ui.resultado),
            ],
          ],
        ),
      ),
    );
  }

  String? _moneyRequerido(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Requerido.';
    }
    try {
      if (Money.parseUserInput(text) <= Decimal.zero) {
        return 'Debe ser mayor que cero.';
      }
    } on FormatException {
      return 'Monto inválido.';
    }
    return null;
  }

  String? _moneyOpcional(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return _moneyRequerido(value);
  }

  Decimal? _opcional(TextEditingController c) {
    final String text = c.text.trim();
    return text.isEmpty ? null : Money.parseUserInput(text);
  }

  List<int> _plazos() {
    return _alternativas.text
        .split(',')
        .map((String s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList(growable: false);
  }

  Future<void> _simular() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_porFechas && (_fechaPrimera == null || _fechaUltima == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige ambas fechas.')),
      );
      return;
    }
    final SimulacionRequest request = SimulacionRequest(
      modalidad: _modalidad,
      montoCapital: Money.parseUserInput(_capital.text),
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
      gastosIniciales: _opcional(_gastos),
      costoAdicionalPorCuota: _opcional(_costoAdicional),
      ingresoMensual: _opcional(_ingreso),
      cantidadCuotasAlternativas: _plazos(),
      incluirTabla: _incluirTabla,
    );
    await ref.read(simulacionProvider.notifier).simular(request);
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({required this.resultado});

  final SimulacionResultado resultado;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    Widget fila(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          SizedBox(width: 170, child: Text(label, style: theme.textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Resultado', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                fila('Cuota', Money.formatClp(resultado.valorCuota)),
                fila('Monto total', Money.formatClp(resultado.montoTotal)),
                fila(
                  'Costo total del crédito',
                  Money.formatClp(resultado.costoTotalCredito),
                ),
                fila(
                  'Intereses y costos',
                  Money.formatClp(resultado.interesesYCostos),
                ),
                fila('CAE', '${resultado.cargaAnualEquivalente} %'),
                fila('Tasa mensual', '${resultado.tasaMensual} %'),
                fila('Tasa anual efectiva', '${resultado.tasaAnualEfectiva} %'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Resumen educativo', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                fila(
                  'Costo por cada \$100',
                  Money.formatClp(resultado.resumen.costoPorCada100),
                ),
                fila(
                  '% sobre el capital',
                  '${resultado.resumen.porcentajeSobreCapital} %',
                ),
                fila(
                  '% intereses y costos',
                  '${resultado.resumen.porcentajeInteresesYCostos} %',
                ),
                if (resultado.resumen.porcentajeIngresoComprometido != null)
                  fila(
                    '% del ingreso comprometido',
                    '${resultado.resumen.porcentajeIngresoComprometido} %',
                  ),
              ],
            ),
          ),
        ),
        if (resultado.comparacion.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Comparación de plazos',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final ComparacionPlazo c in resultado.comparacion)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Text('${c.cantidadCuotas} cuotas')),
                          Text(
                            '${Money.formatClp(c.valorCuota)} · '
                            'total ${Money.formatClp(c.costoTotalCredito)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (resultado.tabla.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Tabla de amortización',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final CuotaAmortizacion c in resultado.tabla)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 32,
                            child: Text('${c.numero}'),
                          ),
                          Expanded(
                            child: Text(
                              c.fechaVencimiento == null
                                  ? 'Cuota ${c.numero}'
                                  : '${c.fechaVencimiento}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(Money.formatClp(c.cuota)),
                              Text(
                                'Capital ${Money.formatClp(c.capital)} · '
                                'Interés ${Money.formatClp(c.interes)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (resultado.advertencias.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Ten en cuenta', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (final String a in resultado.advertencias)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• $a', style: theme.textTheme.bodySmall),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
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
