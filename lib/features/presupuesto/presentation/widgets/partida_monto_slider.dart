import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/money/money.dart';
import '../../../../core/time/business_month.dart';
import '../../domain/plan_mensual.dart';
import '../controllers/plan_mensual_controller.dart';
import '../plan_labels.dart';
import 'partida_pago_dialog.dart';

/// Slider de monto de una partida del plan.
///
/// - `onChange`: recalcula localmente vía [PlanMensualController.moverPartida],
///   sin HTTP.
/// - `onChangeEnd`: [PlanMensualController.soltar] envía el lote atómico.
/// - Partidas vinculadas a una deuda (`deudaId`): sin control, con badge de
///   cuota y la nota de que el monto lo define la deuda.
/// - Partidas generales del mes actual: botón **Pagar** que registra un
///   `GASTO_GENERAL` imputado a la partida. Al cubrir el plan, el slider se
///   congela, la tarjeta cambia a verde y el botón pasa a **Pagado**.
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
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final bool esDeuda = partida.vinculadaADeuda;
    final bool mesActual =
        plan.mes == BusinessMonth.fromInstant(DateTime.now()).toString();
    final bool tieneUso = partida.real > Decimal.zero;
    final bool pagada =
        !esDeuda &&
        tieneUso &&
        (partida.montoPlanificado <= Decimal.zero ||
            partida.real >= partida.montoPlanificado);

    // Pagado: la tarjeta pasa a verde (el texto sigue en tinta).
    final Color? fondo = pagada ? AppColors.green : color;
    final TextTheme textTheme = fondo == null
        ? theme.textTheme
        : theme.textTheme.apply(
            bodyColor: AppColors.ink,
            displayColor: AppColors.ink,
          );

    final Widget usado = Text(
      'Usado ${Money.formatClp(partida.real)} de '
      '${Money.formatClp(partida.montoPlanificado)}',
      style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
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
                label: pagada ? 'Pagado' : estadoPlanLabel(partida.estado),
                color: pagada
                    ? AppColors.paper
                    : (fondo == null ? AppColors.yellow : AppColors.paper),
                compact: true,
              ),
            ],
          ),
        ),
        Text(
          Money.formatClp(partida.montoPlanificado),
          style: textTheme.titleSmall,
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

    if (esDeuda) {
      return NeoSurface(
        density: AppDensity.list,
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            encabezado,
            const SizedBox(height: AppSpacing.xs),
            usado,
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                const Icon(Icons.link, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    partida.deudaNombre == null
                        ? 'Deuda vinculada'
                        : 'Deuda: ${partida.deudaNombre}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (partida.estadoCuota != null)
                  NeoBadge(
                    label: estadoCuotaPlanLabel(partida.estadoCuota),
                    compact: true,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'El monto lo define la cuota de la deuda.',
              style: textTheme.bodySmall,
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
      color: fondo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          encabezado,
          const SizedBox(height: AppSpacing.xs),
          usado,
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: fondo == null
                  ? AppColors.yellow
                  : AppColors.ink,
              thumbColor: fondo == null ? AppColors.yellow : AppColors.ink,
              inactiveTrackColor: fondo == null ? null : AppColors.paper,
            ),
            child: Slider(
              value: actual.clamp(0, maximo),
              max: maximo,
              onChanged: pagada
                  ? null
                  : (double value) => ref
                        .read(planMensualProvider.notifier)
                        .moverPartida(
                          partidaId,
                          Decimal.parse(value.round().toString()),
                        ),
              onChangeEnd: pagada
                  ? null
                  : (_) => ref.read(planMensualProvider.notifier).soltar(),
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
          const SizedBox(height: AppSpacing.sm),
          if (mesActual)
            pagada
                ? _CartelPagado(textTheme: textTheme, colors: colors)
                : NeoButton(
                    label: 'Pagar',
                    icon: Icons.payments_outlined,
                    expanded: true,
                    onPressed: () => _pagar(context, ref),
                  )
          else
            Text(
              'Solo puedes registrar pagos del mes en curso.',
              style: textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
        ],
      ),
    );
  }

  Future<void> _pagar(BuildContext context, WidgetRef ref) async {
    final PlanMensual? plan = ref.read(planMensualProvider).plan;
    final PartidaPlan? partida = plan?.partida(partidaId);
    if (partida == null) {
      return;
    }
    final bool? registrado = await PartidaPagoDialog.show(
      context,
      partida: partida,
    );
    if ((registrado ?? false) && context.mounted) {
      NeoSnackbar.show(
        context,
        'Gasto registrado en Movimientos.',
        tone: NeoSnackbarTone.success,
      );
    }
  }
}

/// Reemplaza al botón cuando la partida ya cubrió su plan.
class _CartelPagado extends StatelessWidget {
  const _CartelPagado({required this.textTheme, required this.colors});

  final TextTheme textTheme;
  final SaveUpColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadii.pillAll,
        border: Border.all(
          color: colors.border,
          width: AppBorders.regular,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppColors.ink,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Pagado',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
