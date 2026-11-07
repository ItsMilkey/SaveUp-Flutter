import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/design_system/design_system.dart';
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

    return NeoScaffold(
      appBar: NeoAppBar(
        title: 'Presupuesto',
        actions: <Widget>[
          NeoIconButton(
            icon: Icons.bar_chart_outlined,
            tooltip: 'Ejecución e historial',
            variant: NeoIconButtonVariant.ghost,
            onPressed: () => context.push(AppRoutes.presupuestoEjecucion),
          ),
          NeoIconButton(
            icon: Icons.category_outlined,
            tooltip: 'Límites y tipos',
            variant: NeoIconButtonVariant.ghost,
            onPressed: () => context.push(AppRoutes.presupuestoCategorias),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: estado.cargando
          ? const NeoLoading(rows: 3)
          : estado.errorCarga != null && estado.config == null
          ? NeoErrorState(
              message: failureMessage(estado.errorCarga!),
              onRetry: controller.cargar,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl * 2,
              ),
              children: <Widget>[
                _Sugerencia(estado: estado, onAplicar: controller.aplicarSugerencia),
                const SizedBox(height: AppSpacing.md),
                NeoSurface(
                  density: AppDensity.section,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const NeoSectionHeader(title: 'Regla mensual'),
                      Text(
                        'Los tres porcentajes deben sumar 100.00.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
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
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
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
                const SizedBox(height: AppSpacing.sm),
                NeoSurface(
                  density: AppDensity.list,
                  child: Material(
                    type: MaterialType.transparency,
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
                ),
                if (estado.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: NeoErrorBand(
                      message: failureMessage(estado.error!),
                    ),
                  ),
                if (estado.guardado)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: NeoSurface(
                      density: AppDensity.table,
                      color: theme.extension<SaveUpColors>()!.success,
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: AppColors.ink,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Regla guardada.',
                            style: AppTypography.text(
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (estado.guardando)
                  const LinearProgressIndicator()
                else
                  NeoButton(
                    label: 'Guardar regla',
                    expanded: true,
                    onPressed: estado.sumaValida ? controller.guardar : null,
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
      return NeoSurface(
        density: AppDensity.section,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const NeoSectionHeader(title: 'Sugerencia'),
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
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Meses analizados: ${sugerencia.mesesAnalizados.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      );
    }

    return NeoSurface(
      density: AppDensity.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NeoSectionHeader(title: 'Sugerencia para ti'),
          Text(
            '${propuesta.necesidades} / ${propuesta.deseos} / '
            '${propuesta.ahorro} · meses: '
            '${sugerencia!.mesesAnalizados.join(', ')}',
            style: theme.textTheme.bodyMedium,
          ),
          if (sugerencia.gastoSuperaIngreso)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
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
