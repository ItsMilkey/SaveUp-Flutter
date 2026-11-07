import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Metas de ahorro')),
      body: metas.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (Object error, StackTrace stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                error is AppFailure
                    ? failureMessage(error)
                    : 'No se pudieron cargar las metas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.invalidate(metasProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (List<MetaAhorro> lista) => _lista(context, ref, lista),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva meta'),
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
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 48),
          const Text(
            'Aún no tienes metas de ahorro.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton(
              onPressed: () => _abrirFormulario(context),
              child: const Text('Crear mi primera meta'),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(metasProvider.notifier).refrescar(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: <Widget>[
          for (final MetaAhorro meta in lista)
            _MetaCard(
              meta: meta,
              onAbonar: () => _abonar(context, ref, meta),
              onRetirar: () => _retirar(context, ref, meta),
              onEditar: () => _abrirFormulario(context, meta: meta),
              onEliminar: meta.esPorDefecto
                  ? null
                  : () => _eliminar(context, ref, meta),
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
    );
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    MetaAhorro meta,
  ) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('¿Eliminar meta?'),
        content: Text(
          meta.montoActual > Decimal.zero
              ? '«${meta.nombre}» se eliminará y sus '
                    '${Money.formatClp(meta.montoActual)} volverán al saldo '
                    'disponible.'
              : '«${meta.nombre}» se eliminará.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
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
    );
  }

  void _avisar(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.meta,
    required this.onAbonar,
    required this.onRetirar,
    required this.onEditar,
    required this.onEliminar,
  });

  final MetaAhorro meta;
  final VoidCallback onAbonar;
  final VoidCallback onRetirar;
  final VoidCallback onEditar;

  /// `null` en la meta por defecto (no se puede eliminar).
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Decimal? objetivo = meta.montoObjetivo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    meta.nombre,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (meta.esPorDefecto)
                  Chip(
                    label: const Text('Meta base'),
                    labelStyle: theme.textTheme.labelSmall,
                    visualDensity: VisualDensity.compact,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progreso(meta.montoActual, objetivo),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${Money.formatClp(meta.montoActual)} de '
                '${Money.formatClp(objetivo)} '
                '(${_porcentaje(meta.montoActual, objetivo)} %)',
                style: theme.textTheme.bodyMedium,
              ),
            ] else
              Text(
                'Ahorrado: ${Money.formatClp(meta.montoActual)}',
                style: theme.textTheme.bodyMedium,
              ),
            if (meta.fechaLimite != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Fecha límite: ${meta.fechaLimite}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: onAbonar,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Abonar'),
                ),
                TextButton.icon(
                  onPressed: meta.montoActual > Decimal.zero ? onRetirar : null,
                  icon: const Icon(Icons.remove, size: 18),
                  label: const Text('Retirar'),
                ),
              ],
            ),
          ],
        ),
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
