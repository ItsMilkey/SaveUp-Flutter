import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/money/money.dart';
import '../../domain/meta_ahorro.dart';
import '../controllers/metas_controller.dart';
import '../widgets/movimiento_meta_dialog.dart';

/// Listado de metas de ahorro con progreso y acciones.
class MetasScreen extends ConsumerWidget {
  const MetasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MetaAhorro>> metas = ref.watch(metasProvider);
    final bool accionesEnCurso = ref.watch(metaAccionesProvider).isLoading;

    return NeoScaffold(
      appBar: const NeoAppBar(title: 'Metas de ahorro'),
      body: metas.when(
        loading: () => const NeoLoading(rows: 3),
        error: (Object error, StackTrace stack) => NeoErrorState(
          message: error is AppFailure
              ? failureMessage(error)
              : 'No se pudieron cargar las metas.',
          onRetry: () => ref.invalidate(metasProvider),
        ),
        data: (List<MetaAhorro> lista) => _lista(
          context,
          ref,
          lista,
          accionesEnCurso: accionesEnCurso,
        ),
      ),
      floatingActionButton: NeoButton(
        onPressed: () => _abrirFormulario(context),
        icon: Icons.add,
        label: 'Nueva meta',
      ),
    );
  }

  Widget _lista(
    BuildContext context,
    WidgetRef ref,
    List<MetaAhorro> lista, {
    required bool accionesEnCurso,
  }) {
    if (lista.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          const SizedBox(height: AppSpacing.xxxl),
          NeoSurface(
            density: AppDensity.section,
            child: Column(
              children: <Widget>[
                const Text(
                  'Aún no tienes metas de ahorro.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                NeoButton(
                  label: 'Crear mi primera meta',
                  onPressed: () => _abrirFormulario(context),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final List<Color> chartPalette = Theme.of(context)
        .extension<SaveUpColors>()!
        .chartPalette;
    return RefreshIndicator(
      onRefresh: () => ref.read(metasProvider.notifier).refrescar(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl * 2,
        ),
        children: <Widget>[
          for (int i = 0; i < lista.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _MetaCard(
                meta: lista[i],
                color: chartPalette[i % chartPalette.length],
                onAbonar: accionesEnCurso
                    || lista[i].compartida
                    ? null
                    : () => _abonar(context, ref, lista[i]),
                onRetirar: accionesEnCurso
                    || lista[i].compartida
                    ? null
                    : () => _retirar(context, ref, lista[i]),
                onEditar: lista[i].compartida
                    ? null
                    : () => _abrirFormulario(context, meta: lista[i]),
                onEliminar: lista[i].esPorDefecto ||
                        lista[i].compartida ||
                        accionesEnCurso
                    ? null
                    : () => _eliminar(context, ref, lista[i]),
                onGestionar: lista[i].compartida
                    ? () => context.push<void>(AppRoutes.colaboraciones)
                    : null,
                accionesEnCurso: accionesEnCurso,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _abrirFormulario(
    BuildContext context, {
    MetaAhorro? meta,
  }) async {
    await context.push<bool>(
      meta == null ? AppRoutes.nuevaMeta : AppRoutes.editarMeta(meta.id),
      extra: meta,
    );
  }

  Future<void> _abonar(
    BuildContext context,
    WidgetRef ref,
    MetaAhorro meta,
  ) async {
    final MovimientoMetaValor? valor = await MovimientoMetaDialog.show(
      context,
      meta: meta,
      modo: ModoMovimientoMeta.abono,
    );
    if (valor == null || !context.mounted) {
      return;
    }
    if (ref.read(metaAccionesProvider).isLoading) {
      return;
    }
    final AppFailure? failure = await ref
        .read(metaAccionesProvider.notifier)
        .abonar(meta.id, monto: valor.monto, descripcion: valor.descripcion);
    if (!context.mounted) {
      return;
    }
    _avisar(
      context,
      failure == null ? 'Abono registrado.' : failureMessage(failure),
      tone: failure == null ? NeoSnackbarTone.success : NeoSnackbarTone.danger,
    );
  }

  Future<void> _retirar(
    BuildContext context,
    WidgetRef ref,
    MetaAhorro meta,
  ) async {
    final MovimientoMetaValor? valor = await MovimientoMetaDialog.show(
      context,
      meta: meta,
      modo: ModoMovimientoMeta.retiro,
    );
    if (valor == null || !context.mounted) {
      return;
    }
    if (ref.read(metaAccionesProvider).isLoading) {
      return;
    }
    final AppFailure? failure = await ref
        .read(metaAccionesProvider.notifier)
        .retirar(meta.id, monto: valor.monto, descripcion: valor.descripcion);
    if (!context.mounted) {
      return;
    }
    _avisar(
      context,
      failure == null ? 'Retiro registrado.' : failureMessage(failure),
      tone: failure == null ? NeoSnackbarTone.success : NeoSnackbarTone.danger,
    );
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    MetaAhorro meta,
  ) async {
    final bool? confirmado = await NeoConfirmDialog.show(
      context,
      title: '¿Eliminar meta?',
      message: meta.montoActual > Decimal.zero
          ? '«${meta.nombre}» se eliminará y sus '
                '${Money.formatClp(meta.montoActual)} volverán al saldo '
                'disponible.'
          : '«${meta.nombre}» se eliminará.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (confirmado != true || !context.mounted) {
      return;
    }
    if (ref.read(metaAccionesProvider).isLoading) {
      return;
    }
    final AppFailure? failure = await ref
        .read(metaAccionesProvider.notifier)
        .eliminar(meta.id);
    if (!context.mounted) {
      return;
    }
    _avisar(
      context,
      failure == null ? 'Meta eliminada.' : failureMessage(failure),
      tone: failure == null ? NeoSnackbarTone.success : NeoSnackbarTone.danger,
    );
  }

  void _avisar(
    BuildContext context,
    String mensaje, {
    NeoSnackbarTone tone = NeoSnackbarTone.neutral,
  }) {
    NeoSnackbar.show(context, mensaje, tone: tone);
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.meta,
    required this.color,
    required this.onAbonar,
    required this.onRetirar,
    required this.onEditar,
    required this.onEliminar,
    required this.onGestionar,
    required this.accionesEnCurso,
  });

  final MetaAhorro meta;
  final Color color;
  final VoidCallback? onAbonar;
  final VoidCallback? onRetirar;
  final VoidCallback? onEditar;
  final bool accionesEnCurso;
  final VoidCallback? onGestionar;

  /// `null` en la meta por defecto (no se puede eliminar).
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final TextTheme textTheme = theme.textTheme.apply(
      bodyColor: colors.onAccentSurface,
      displayColor: colors.onAccentSurface,
    );
    final Decimal? objetivo = meta.montoObjetivo;

    return NeoSurface(
      density: AppDensity.section,
      color: color,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(meta.nombre, style: textTheme.titleMedium)),
              if (meta.esPorDefecto)
                NeoBadge(
                  label: 'Meta base',
                  color: colors.surface,
                  textColor: colors.ink,
                  compact: true,
                ),
              if (meta.compartida)
                const NeoBadge(
                  label: 'Compartida',
                  color: AppColors.lavender,
                  compact: true,
                ),
              if (onEditar != null || onEliminar != null)
                PopupMenuButton<_AccionMeta>(
                tooltip: 'Opciones',
                enabled: onEditar != null || onEliminar != null,
                onSelected: (_AccionMeta accion) {
                  switch (accion) {
                    case _AccionMeta.editar:
                      onEditar?.call();
                    case _AccionMeta.eliminar:
                      onEliminar?.call();
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<_AccionMeta>>[
                      if (onEditar != null)
                        const PopupMenuItem<_AccionMeta>(
                          value: _AccionMeta.editar,
                          child: Text('Editar'),
                        ),
                      if (onEliminar != null)
                        PopupMenuItem<_AccionMeta>(
                          value: _AccionMeta.eliminar,
                          enabled: !accionesEnCurso,
                          child: Text('Eliminar'),
                        ),
                    ],
              ),
            ],
          ),
          if (objetivo != null) ...<Widget>[
            NeoProgress(
              value: _progreso(meta.montoActual, objetivo),
              color: colors.onAccentSurface,
              // La pista vive sobre un acento, no sobre el surface del tema:
              // se deriva del foreground para leerse en los tres temas.
              trackColor: colors.onAccentSurface.withValues(alpha: 0.18),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${Money.formatClp(meta.montoActual)} de '
              '${Money.formatClp(objetivo)} '
              '(${_porcentaje(meta.montoActual, objetivo)} %)',
              style: textTheme.bodyMedium,
            ),
          ] else
            Text(
              'Ahorrado: ${Money.formatClp(meta.montoActual)}',
              style: textTheme.bodyMedium,
            ),
          if (meta.fechaLimite != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Fecha límite: ${meta.fechaLimite}',
                style: textTheme.bodySmall,
              ),
            ),
          if (meta.compartida) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Aportes, gastos y cambios se gestionan en Colaboraciones.',
              style: textTheme.bodySmall,
            ),
            NeoButton(
              label: 'Gestionar colaboración',
              icon: Icons.people_alt_outlined,
              variant: NeoButtonVariant.secondary,
              onPressed: onGestionar,
            ),
          ],
          Row(
            children: <Widget>[
              NeoButton(
                label: 'Abonar',
                icon: Icons.add,
                variant: NeoButtonVariant.ghost,
                onPressed: onAbonar,
              ),
              NeoButton(
                label: 'Retirar',
                icon: Icons.remove,
                variant: NeoButtonVariant.ghost,
                onPressed: meta.montoActual > Decimal.zero ? onRetirar : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AccionMeta { editar, eliminar }

/// Avance visual (0–1). El `double` solo existe en la barra.
double _progreso(Decimal actual, Decimal objetivo) {
  if (objetivo <= Decimal.zero) {
    return 0;
  }
  final double valor = (actual / objetivo)
      .toDecimal(scaleOnInfinitePrecision: 4)
      .toDouble();
  return valor.clamp(0.0, 1.0);
}

String _porcentaje(Decimal actual, Decimal objetivo) {
  if (objetivo <= Decimal.zero) {
    return '0';
  }
  return (actual * Decimal.fromInt(100) / objetivo)
      .toDecimal(scaleOnInfinitePrecision: 6)
      .round(scale: 2)
      .toString();
}
