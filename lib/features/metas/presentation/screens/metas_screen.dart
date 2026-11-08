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
        data: (List<MetaAhorro> lista) => _lista(context, ref, lista),
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
    List<MetaAhorro> lista,
  ) {
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
                color: _coloresMeta[i % _coloresMeta.length],
                onAbonar: () => _abonar(context, ref, lista[i]),
                onRetirar: () => _retirar(context, ref, lista[i]),
                onEditar: () => _abrirFormulario(context, meta: lista[i]),
                onEliminar: lista[i].esPorDefecto
                    ? null
                    : () => _eliminar(context, ref, lista[i]),
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
    final AppFailure? failure = await ref
        .read(metaAccionesProvider.notifier)
        .abonar(meta.id, monto: valor.monto, descripcion: valor.descripcion);
    if (!context.mounted) {
      return;
    }
    _avisar(
      context,
      failure == null
          ? 'Abono registrado.'
          : failureMessage(failure),
      tone: failure == null
          ? NeoSnackbarTone.success
          : NeoSnackbarTone.danger,
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
    final AppFailure? failure = await ref
        .read(metaAccionesProvider.notifier)
        .retirar(meta.id, monto: valor.monto, descripcion: valor.descripcion);
    if (!context.mounted) {
      return;
    }
    _avisar(
      context,
      failure == null
          ? 'Retiro registrado.'
          : failureMessage(failure),
      tone: failure == null
          ? NeoSnackbarTone.success
          : NeoSnackbarTone.danger,
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
    final AppFailure? failure = await ref
        .read(metaAccionesProvider.notifier)
        .eliminar(meta.id);
    if (!context.mounted) {
      return;
    }
    _avisar(
      context,
      failure == null ? 'Meta eliminada.' : failureMessage(failure),
      tone: failure == null
          ? NeoSnackbarTone.success
          : NeoSnackbarTone.danger,
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
  });

  final MetaAhorro meta;
  final Color color;
  final VoidCallback onAbonar;
  final VoidCallback onRetirar;
  final VoidCallback onEditar;

  /// `null` en la meta por defecto (no se puede eliminar).
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
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
              Expanded(
                child: Text(
                  meta.nombre,
                  style: textTheme.titleMedium,
                ),
              ),
              if (meta.esPorDefecto)
                NeoBadge(
                  label: 'Meta base',
                  color: AppColors.paper,
                  compact: true,
                ),
              PopupMenuButton<_AccionMeta>(
                tooltip: 'Opciones',
                onSelected: (_AccionMeta accion) {
                  switch (accion) {
                    case _AccionMeta.editar:
                      onEditar();
                    case _AccionMeta.eliminar:
                      onEliminar?.call();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<_AccionMeta>>[
                  const PopupMenuItem<_AccionMeta>(
                    value: _AccionMeta.editar,
                    child: Text('Editar'),
                  ),
                  if (onEliminar != null)
                    const PopupMenuItem<_AccionMeta>(
                      value: _AccionMeta.eliminar,
                      child: Text('Eliminar'),
                    ),
                ],
              ),
            ],
          ),
          if (objetivo != null) ...<Widget>[
            NeoProgress(
              value: _progreso(meta.montoActual, objetivo),
              color: AppColors.ink,
              trackColor: AppColors.paper,
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
const List<Color> _coloresMeta = <Color>[
  AppColors.yellow,
  AppColors.cyan,
  AppColors.lavender,
  AppColors.green,
  AppColors.magenta,
  AppColors.orange,
];

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
