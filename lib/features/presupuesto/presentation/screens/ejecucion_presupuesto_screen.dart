import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
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

    return NeoScaffold(
      appBar: NeoAppBar(
        title: 'Ejecución',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              NeoIconButton(
                icon: Icons.chevron_left,
                tooltip: 'Mes anterior',
                variant: NeoIconButtonVariant.ghost,
                onPressed: estado.cargando
                    ? null
                    : () => controller.cambiarMes(-1),
              ),
              Text(
                _etiquetaMes(estado.mes),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              NeoIconButton(
                icon: Icons.chevron_right,
                tooltip: 'Mes siguiente',
                variant: NeoIconButtonVariant.ghost,
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
      return const NeoLoading(rows: 3);
    }
    if (estado.error != null && estado.ejecucion == null) {
      return NeoErrorState(
        message: failureMessage(estado.error!),
        onRetry: controller.cargar,
      );
    }
    final EjecucionPresupuesto? ejecucion = estado.ejecucion;
    if (ejecucion == null) {
      return const NeoEmptyState(
        title: 'Sin datos',
        message: 'Sin datos de ejecución.',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: NeoErrorBand(message: failureMessage(estado.error!)),
            ),
          _Ingresos(ejecucion: ejecucion),
          const SizedBox(height: AppSpacing.sm),
          _BloqueGasto(
            titulo: 'Necesidades',
            color: Theme.of(context).extension<SaveUpColors>()!.info,
            presupuesto: ejecucion.presupuestoNecesidades,
            real: ejecucion.gastoNecesidades,
            porcentaje: ejecucion.porcentajeNecesidadesConfigurado,
          ),
          const SizedBox(height: AppSpacing.sm),
          _BloqueGasto(
            titulo: 'Deseos',
            color: AppColors.magenta,
            presupuesto: ejecucion.presupuestoDeseos,
            real: ejecucion.gastoDeseos,
            porcentaje: ejecucion.porcentajeDeseosConfigurado,
          ),
          const SizedBox(height: AppSpacing.sm),
          _BloqueAhorro(ejecucion: ejecucion),
          const SizedBox(height: AppSpacing.sm),
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
    final TextTheme textTheme = theme.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    return NeoSurface(
      density: AppDensity.section,
      color: AppColors.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NeoSectionHeader(title: 'Ingresos del mes'),
          Text(
            Money.formatClp(ejecucion.totalIngresos),
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Regla: ${ejecucion.porcentajeNecesidadesConfigurado} / '
            '${ejecucion.porcentajeDeseosConfigurado} / '
            '${ejecucion.porcentajeAhorroConfigurado}',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (ejecucion.automatizarAhorroEnMetas)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Automatización del ahorro en metas activa.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BloqueGasto extends StatelessWidget {
  const _BloqueGasto({
    required this.titulo,
    required this.color,
    required this.presupuesto,
    required this.real,
    required this.porcentaje,
  });

  final String titulo;
  final Color color;
  final Decimal presupuesto;
  final Decimal real;
  final Decimal porcentaje;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    final EstadoEjecucion estado = EstadoEjecucion.desde(real, presupuesto);
    return NeoSurface(
      density: AppDensity.section,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(titulo, style: textTheme.titleMedium),
              ),
              NeoBadge(
                label: estadoPlanLabel(estado),
                color: AppColors.paper,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          NeoProgress(
            value: _avance(real, presupuesto),
            color: AppColors.ink,
            trackColor: AppColors.paper,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${Money.formatClp(real)} de ${Money.formatClp(presupuesto)} '
            '(plan $porcentaje %)',
            style: textTheme.bodyMedium,
          ),
        ],
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
    final TextTheme textTheme = theme.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return NeoSurface(
      density: AppDensity.section,
      color: colors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NeoSectionHeader(title: 'Ahorro'),
          NeoProgress(
            value: _avance(
              ejecucion.ahorroRealizado,
              ejecucion.presupuestoAhorro,
            ),
            color: AppColors.ink,
            trackColor: AppColors.paper,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${Money.formatClp(ejecucion.ahorroRealizado)} de '
            '${Money.formatClp(ejecucion.presupuestoAhorro)} '
            '(plan ${ejecucion.porcentajeAhorroConfigurado} %)',
            style: textTheme.bodyMedium,
          ),
        ],
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

    return NeoSurface(
      density: AppDensity.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NeoSectionHeader(title: 'Historial'),
          if (ordenado.isEmpty)
            Text(
              'Sin historial en los últimos 6 meses.',
              style: theme.textTheme.bodySmall,
            )
          else
            for (final HistorialPresupuesto fila in ordenado)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
