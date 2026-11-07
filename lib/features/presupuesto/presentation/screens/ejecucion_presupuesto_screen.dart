import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/money/money.dart';
import '../../../../core/time/business_month.dart';
import '../../domain/ejecucion_presupuesto.dart';
import '../../domain/plan_calculo.dart';
import '../controllers/ejecucion_presupuesto_controller.dart';
import '../plan_labels.dart';

/// Ejecución mensual de la regla 50/30/20 y su historial reciente.
class EjecucionPresupuestoScreen extends ConsumerStatefulWidget {
  const EjecucionPresupuestoScreen({super.key});

  @override
  ConsumerState<EjecucionPresupuestoScreen> createState() =>
      _EjecucionPresupuestoScreenState();
}

class _EjecucionPresupuestoScreenState
    extends ConsumerState<EjecucionPresupuestoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(ejecucionPresupuestoProvider.notifier).cargar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final EjecucionPresupuestoState estado = ref.watch(
      ejecucionPresupuestoProvider,
    );
    final EjecucionPresupuestoController controller = ref.read(
      ejecucionPresupuestoProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejecución'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Mes anterior',
                onPressed: estado.cargando
                    ? null
                    : () => controller.cambiarMes(-1),
              ),
              Text(
                _etiquetaMes(estado.mes),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Mes siguiente',
                onPressed: estado.cargando
                    ? null
                    : () => controller.cambiarMes(1),
              ),
            ],
          ),
        ),
      ),
      body: _cuerpo(estado, controller),
    );
  }

  Widget _cuerpo(
    EjecucionPresupuestoState estado,
    EjecucionPresupuestoController controller,
  ) {
    if (estado.cargando && estado.ejecucion == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (estado.error != null && estado.ejecucion == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(failureMessage(estado.error!)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: controller.cargar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    final EjecucionPresupuesto? ejecucion = estado.ejecucion;
    if (ejecucion == null) {
      return const Center(child: Text('Sin datos de ejecución.'));
    }

    return RefreshIndicator(
      onRefresh: controller.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                failureMessage(estado.error!),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          _Ingresos(ejecucion: ejecucion),
          const SizedBox(height: 8),
          _BloqueGasto(
            titulo: 'Necesidades',
            presupuesto: ejecucion.presupuestoNecesidades,
            real: ejecucion.gastoNecesidades,
            porcentaje: ejecucion.porcentajeNecesidadesConfigurado,
          ),
          const SizedBox(height: 8),
          _BloqueGasto(
            titulo: 'Deseos',
            presupuesto: ejecucion.presupuestoDeseos,
            real: ejecucion.gastoDeseos,
            porcentaje: ejecucion.porcentajeDeseosConfigurado,
          ),
          const SizedBox(height: 8),
          _BloqueAhorro(ejecucion: ejecucion),
          const SizedBox(height: 8),
          _Historial(historial: estado.historial),
        ],
      ),
    );
  }
}

class _Ingresos extends StatelessWidget {
  const _Ingresos({required this.ejecucion});

  final EjecucionPresupuesto ejecucion;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Ingresos del mes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              Money.formatClp(ejecucion.totalIngresos),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Regla: ${ejecucion.porcentajeNecesidadesConfigurado} / '
              '${ejecucion.porcentajeDeseosConfigurado} / '
              '${ejecucion.porcentajeAhorroConfigurado}',
              style: theme.textTheme.bodySmall,
            ),
            if (ejecucion.automatizarAhorroEnMetas)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Automatización del ahorro en metas activa.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BloqueGasto extends StatelessWidget {
  const _BloqueGasto({
    required this.titulo,
    required this.presupuesto,
    required this.real,
    required this.porcentaje,
  });

  final String titulo;
  final Decimal presupuesto;
  final Decimal real;
  final Decimal porcentaje;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EstadoEjecucion estado = EstadoEjecucion.desde(real, presupuesto);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(titulo, style: theme.textTheme.titleMedium),
                ),
                Chip(
                  label: Text(estadoPlanLabel(estado)),
                  labelStyle: TextStyle(
                    color: estadoPlanColor(context, estado),
                    fontSize: 11,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _avance(real, presupuesto),
                minHeight: 8,
                color: estadoPlanColor(context, estado),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${Money.formatClp(real)} de ${Money.formatClp(presupuesto)} '
              '(plan $porcentaje %)',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _BloqueAhorro extends StatelessWidget {
  const _BloqueAhorro({required this.ejecucion});

  final EjecucionPresupuesto ejecucion;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Ahorro', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _avance(
                  ejecucion.ahorroRealizado,
                  ejecucion.presupuestoAhorro,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${Money.formatClp(ejecucion.ahorroRealizado)} de '
              '${Money.formatClp(ejecucion.presupuestoAhorro)} '
              '(plan ${ejecucion.porcentajeAhorroConfigurado} %)',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Historial extends StatelessWidget {
  const _Historial({required this.historial});

  final List<HistorialPresupuesto> historial;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<HistorialPresupuesto> ordenado =
        <HistorialPresupuesto>[...historial]
          ..sort((HistorialPresupuesto a, HistorialPresupuesto b) {
            final int porAnio = b.anio.compareTo(a.anio);
            return porAnio != 0 ? porAnio : b.mes.compareTo(a.mes);
          });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Historial', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (ordenado.isEmpty)
              Text(
                'Sin historial en los últimos 6 meses.',
                style: theme.textTheme.bodySmall,
              )
            else
              for (final HistorialPresupuesto fila in ordenado)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 76,
                        child: Text(
                          _etiquetaCorto(fila.anio, fila.mes),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'N ${Money.formatClp(fila.ejecucion.gastoNecesidades)}'
                          ' · D ${Money.formatClp(fila.ejecucion.gastoDeseos)}'
                          ' · A ${Money.formatClp(fila.ejecucion.ahorroRealizado)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Avance visual (0–1). El `double` solo existe aquí, en la barra.
double _avance(Decimal real, Decimal planificado) {
  if (planificado <= Decimal.zero) {
    return real > Decimal.zero ? 1 : 0;
  }
  final double valor = (real / planificado)
      .toDecimal(scaleOnInfinitePrecision: 4)
      .toDouble();
  return valor.clamp(0.0, 1.0);
}

String _etiquetaMes(BusinessMonth mes) => _etiquetaCorto(mes.year, mes.month);

String _etiquetaCorto(int anio, int mes) {
  const List<String> nombres = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final String nombre = mes >= 1 && mes <= 12 ? nombres[mes - 1] : '$mes';
  return '$nombre $anio';
}
