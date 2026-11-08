import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/money/money.dart';
import '../../domain/plan_mensual.dart';
import '../controllers/plan_mensual_controller.dart';
import '../plan_labels.dart';

/// Slider de monto de una partida del plan.
///
/// - `onChange`: recalcula localmente vía [PlanMensualController.moverPartida],
///   sin HTTP.
/// - `onChangeEnd`: [PlanMensualController.soltar] envía el lote atómico.
/// - Partidas vinculadas a una deuda (`deudaId`): sin control, con badge de
///   cuota y la nota de que el monto lo define la deuda.
class PartidaMontoSlider extends ConsumerWidget {
  const PartidaMontoSlider({
    super.key,
    required this.partidaId,
    this.onEditar,
    this.onEliminar,
    this.color,
  });

  final int partidaId;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  /// Fondo de color del grupo; `null` = papel.
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlanMensualState estado = ref.watch(planMensualProvider);
    final PlanMensual? plan = estado.plan;
    if (plan == null) {
      return const SizedBox.shrink();
    }
    final PartidaPlan? partida = plan.partida(partidaId);
    if (partida == null) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = color == null
        ? theme.textTheme
        : theme.textTheme.apply(
            bodyColor: AppColors.ink,
            displayColor: AppColors.ink,
          );

    final Widget encabezado = Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(partida.nombre, style: textTheme.titleSmall),
              const SizedBox(height: 2),
              NeoBadge(
                label: estadoPlanLabel(partida.estado),
                color: color == null ? AppColors.yellow : AppColors.paper,
                compact: true,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              Money.formatClp(partida.montoPlanificado),
              style: textTheme.titleSmall,
            ),
            Text(
              'Real ${Money.formatClp(partida.real)}',
              style: textTheme.bodySmall,
            ),
          ],
        ),
        if (onEditar != null || onEliminar != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (onEditar != null)
                NeoIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Editar partida',
                  variant: NeoIconButtonVariant.ghost,
                  onPressed: onEditar,
                ),
              if (onEliminar != null)
                NeoIconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Eliminar partida',
                  variant: NeoIconButtonVariant.ghost,
                  onPressed: onEliminar,
                ),
            ],
          ),
      ],
    );

    if (partida.vinculadaADeuda) {
      return NeoSurface(
        density: AppDensity.list,
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            encabezado,
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                const Icon(Icons.link, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'El monto lo define la cuota de la deuda.',
                    style: textTheme.bodySmall,
                  ),
                ),
                if (partida.estadoCuota != null)
                  NeoBadge(
                    label: estadoCuotaPlanLabel(partida.estadoCuota),
                    compact: true,
                  ),
              ],
            ),
            if (partida.vinculoDesactualizado)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'El vínculo ya no calcula; se muestra el último monto.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final Decimal limite = ref
        .read(planMensualProvider.notifier)
        .limiteSlider(partidaId);
    final double actual = partida.montoPlanificado.toDouble();
    // El Slider trabaja en double solo para la posición visual; el monto viaja
    // como Decimal redondeado a peso.
    double maximo = limite.toDouble();
    if (maximo <= actual) {
      maximo = actual + 1000;
    }

    return NeoSurface(
      density: AppDensity.list,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          encabezado,
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color == null ? AppColors.yellow : AppColors.ink,
              thumbColor: color == null ? AppColors.yellow : AppColors.ink,
              inactiveTrackColor: color == null ? null : AppColors.paper,
            ),
            child: Slider(
              value: actual.clamp(0, maximo),
              max: maximo,
              onChanged: (double value) => ref
                  .read(planMensualProvider.notifier)
                  .moverPartida(
                    partidaId,
                    Decimal.parse(value.round().toString()),
                  ),
              onChangeEnd: (_) =>
                  ref.read(planMensualProvider.notifier).soltar(),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Diferencia ${Money.formatClp(partida.diferencia)}',
                  style: textTheme.bodySmall,
                ),
              ),
              if (partida.porcentajeUsado != null)
                Text(
                  '${partida.porcentajeUsado} % usado',
                  style: textTheme.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
