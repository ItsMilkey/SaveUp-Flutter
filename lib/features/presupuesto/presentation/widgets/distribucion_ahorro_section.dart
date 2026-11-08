import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../metas/domain/meta_ahorro.dart';
import '../controllers/asignaciones_presupuesto_controller.dart';

/// Sección «Distribución del ahorro» dentro de la configuración de la regla.
///
/// Si el `GET` de asignaciones falla, no se muestra: guardar la regla omite
/// `asignaciones` para no borrar lo que no se pudo leer.
class DistribucionAhorroSection extends ConsumerWidget {
  const DistribucionAhorroSection({
    super.key,
    required this.automatizarAhorroEnMetas,
  });

  final bool automatizarAhorroEnMetas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsignacionesPresupuestoState estado = ref.watch(
      asignacionesPresupuestoProvider,
    );
    if (!estado.cargadas) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final AsignacionesPresupuestoController controller = ref.read(
      asignacionesPresupuestoProvider.notifier,
    );
    final List<int> ids = estado.valores.keys.toList()
      ..sort(
        (int a, int b) =>
            estado.nombreDe(a).compareTo(estado.nombreDe(b)),
      );

    return NeoSurface(
      density: AppDensity.section,
      color: colors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NeoSectionHeader(title: 'Distribución del ahorro'),
          if (estado.cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: LinearProgressIndicator(),
            )
          else if (estado.valores.isEmpty) ...<Widget>[
            Text(
              'Sin distribución: el ahorro queda en la meta base.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (estado.metas.isEmpty)
              Text(
                'No tienes metas de ahorro para asignar.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.7),
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: NeoButton(
                  icon: Icons.add,
                  label: 'Agregar meta',
                  variant: NeoButtonVariant.secondary,
                  onPressed: () =>
                      _agregar(context, ref, estado.disponibles),
                ),
              ),
          ] else ...<Widget>[
            for (final int id in ids) ...<Widget>[
              _FilaAsignacion(
                nombre: estado.nombreDe(id),
                porcentaje: estado.valores[id]!,
                cantidad: ids.length,
                onChanged: (Decimal valor) =>
                    controller.setPorcentaje(id, valor),
                onQuitar: () => controller.quitar(id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Total: ${estado.total.toStringAsFixed(2)} % / 100.00 %',
                    style: AppTypography.text(
                      size: 13,
                      weight: FontWeight.w700,
                      color: estado.valido ? AppColors.ink : AppColors.danger,
                    ),
                  ),
                ),
                Text(
                  '${ids.length} meta(s)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                if (estado.disponibles.isNotEmpty)
                  NeoButton(
                    icon: Icons.add,
                    label: 'Agregar meta',
                    variant: NeoButtonVariant.secondary,
                    onPressed: () =>
                        _agregar(context, ref, estado.disponibles),
                  ),
                NeoButton(
                  label: 'Limpiar distribución',
                  variant: NeoButtonVariant.ghost,
                  onPressed: controller.limpiar,
                ),
              ],
            ),
          ],
          if (estado.mensajeValidacion != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            NeoErrorBand(message: estado.mensajeValidacion!),
          ],
          if (!automatizarAhorroEnMetas) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'La distribución se guarda, pero los abonos automáticos están '
              'apagados: se ejecutará cuando actives «Automatizar ahorro en '
              'metas».',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _agregar(
    BuildContext context,
    WidgetRef ref,
    List<MetaAhorro> disponibles,
  ) {
    return NeoMoreMenu.show(
      context,
      title: 'Agregar meta',
      options: <NeoMoreOption>[
        for (final MetaAhorro meta in disponibles)
          NeoMoreOption(
            label: meta.nombre,
            icon: Icons.savings_outlined,
            onTap: () =>
                ref.read(asignacionesPresupuestoProvider.notifier).agregar(
                  meta.id,
                ),
          ),
      ],
    );
  }
}

class _FilaAsignacion extends StatelessWidget {
  const _FilaAsignacion({
    required this.nombre,
    required this.porcentaje,
    required this.cantidad,
    required this.onChanged,
    required this.onQuitar,
  });

  final String nombre;
  final Decimal porcentaje;
  final int cantidad;
  final ValueChanged<Decimal> onChanged;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool unica = cantidad == 1;
    final double maximo = unica ? 100 : 100 - (cantidad - 1);
    final double actual = porcentaje.toDouble().clamp(1, maximo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                nombre,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              '${porcentaje.toStringAsFixed(2)} %',
              style: AppTypography.text(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            NeoIconButton(
              icon: Icons.delete_outline,
              tooltip: 'Quitar asignación',
              variant: NeoIconButtonVariant.ghost,
              onPressed: onQuitar,
            ),
          ],
        ),
        if (!unica)
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.ink,
              thumbColor: AppColors.ink,
              inactiveTrackColor: AppColors.paper,
            ),
            child: Slider(
              value: actual,
              min: 1,
              max: maximo,
              divisions: (maximo - 1).round(),
              label: '${porcentaje.toStringAsFixed(2)} %',
              onChanged: (double valor) =>
                  onChanged(Decimal.parse(valor.toStringAsFixed(2))),
            ),
          ),
      ],
    );
  }
}
