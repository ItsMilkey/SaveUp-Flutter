import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../domain/regla_presupuestaria.dart';
import '../controllers/regla_presupuestaria_controller.dart';

/// Configuración de la regla 50/30/20 (necesidades/deseos/ahorro).
class ConfiguracionReglaScreen extends ConsumerStatefulWidget {
  const ConfiguracionReglaScreen({super.key});

  @override
  ConsumerState<ConfiguracionReglaScreen> createState() =>
      _ConfiguracionReglaScreenState();
}

class _ConfiguracionReglaScreenState
    extends ConsumerState<ConfiguracionReglaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(reglaPresupuestariaProvider.notifier).cargar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ReglaPresupuestariaState estado = ref.watch(
      reglaPresupuestariaProvider,
    );
    final ReglaPresupuestariaController controller = ref.read(
      reglaPresupuestariaProvider.notifier,
    );
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Ejecución e historial',
            onPressed: () => context.push(AppRoutes.presupuestoEjecucion),
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Límites y tipos',
            onPressed: () => context.push(AppRoutes.presupuestoCategorias),
          ),
        ],
      ),
      body: estado.cargando
          ? const Center(child: CircularProgressIndicator.adaptive())
          : estado.errorCarga != null && estado.config == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(failureMessage(estado.errorCarga!)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: controller.cargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: <Widget>[
                _Sugerencia(estado: estado, onAplicar: controller.aplicarSugerencia),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Regla mensual', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Los tres porcentajes deben sumar 100.00.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        _SliderRegla(
                          label: 'Necesidades',
                          valor: estado.necesidades,
                          onChanged: controller.setNecesidades,
                        ),
                        _SliderRegla(
                          label: 'Deseos',
                          valor: estado.deseos,
                          onChanged: controller.setDeseos,
                        ),
                        _SliderRegla(
                          label: 'Ahorro',
                          valor: estado.ahorro,
                          onChanged: controller.setAhorro,
                        ),
                        const Divider(),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Suma: ${estado.suma} %',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: estado.sumaValida
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.error,
                                ),
                              ),
                            ),
                            if (!estado.sumaValida)
                              Text(
                                'Debe ser 100.00',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                        if (estado.mensajeValidacion != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              estado.mensajeValidacion!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: <Widget>[
                      SwitchListTile(
                        title: const Text('Presupuesto activo'),
                        value: estado.activo,
                        onChanged: controller.setActivo,
                      ),
                      SwitchListTile(
                        title: const Text('Automatizar ahorro en metas'),
                        subtitle: const Text(
                          'La ejecución automática de abonos llega con F7.',
                        ),
                        value: estado.automatizarAhorroEnMetas,
                        onChanged: controller.setAutomatizarAhorroEnMetas,
                      ),
                    ],
                  ),
                ),
                if (estado.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      failureMessage(estado.error!),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                if (estado.guardado)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Regla guardada.',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                const SizedBox(height: 16),
                if (estado.guardando)
                  const LinearProgressIndicator()
                else
                  FilledButton(
                    onPressed: estado.sumaValida ? controller.guardar : null,
                    child: const Text('Guardar regla'),
                  ),
              ],
            ),
    );
  }
}

class _Sugerencia extends StatelessWidget {
  const _Sugerencia({required this.estado, required this.onAplicar});

  final ReglaPresupuestariaState estado;
  final VoidCallback onAplicar;

  @override
  Widget build(BuildContext context) {
    final SugerenciaRegla? sugerencia = estado.sugerencia;
    final ThemeData theme = Theme.of(context);
    final PorcentajesRegla? propuesta = sugerencia?.sugerencia;

    if (propuesta == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Sugerencia', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                sugerencia?.motivo == 'DATOS_INSUFICIENTES'
                    ? 'Aún no hay suficientes meses de historial para sugerir '
                          'una regla. Puedes configurarla manualmente.'
                    : 'No hay una sugerencia disponible; configura tu regla '
                          'manualmente.',
                style: theme.textTheme.bodySmall,
              ),
              if (sugerencia != null &&
                  sugerencia.mesesAnalizados.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  'Meses analizados: ${sugerencia.mesesAnalizados.join(', ')}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Sugerencia para ti', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '${propuesta.necesidades} / ${propuesta.deseos} / '
              '${propuesta.ahorro} · meses: '
              '${sugerencia!.mesesAnalizados.join(', ')}',
              style: theme.textTheme.bodyMedium,
            ),
            if (sugerencia.gastoSuperaIngreso)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tu gasto de necesidades y deseos supera tus ingresos; la '
                  'sugerencia se escaló para sumar 100.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAplicar,
                child: const Text('Aplicar sugerencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRegla extends StatelessWidget {
  const _SliderRegla({
    required this.label,
    required this.valor,
    required this.onChanged,
  });

  final String label;
  final Decimal valor;
  final ValueChanged<Decimal> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text('$valor %', style: theme.textTheme.titleSmall),
          ],
        ),
        Slider(
          value: valor.toDouble().clamp(0, 100),
          max: 100,
          divisions: 200,
          label: '$valor %',
          onChanged: (double value) => onChanged(
            Decimal.parse(value.toStringAsFixed(2)),
          ),
        ),
      ],
    );
  }
}
