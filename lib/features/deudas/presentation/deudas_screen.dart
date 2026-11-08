import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/money/money.dart';
import '../domain/deuda.dart';
import 'deuda_labels.dart';
import 'deudas_controller.dart';

/// Listado de deudas con progreso y segmentación activas/historial.
class DeudasScreen extends ConsumerStatefulWidget {
  const DeudasScreen({super.key});

  @override
  ConsumerState<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends ConsumerState<DeudasScreen> {
  bool _verActivas = true;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Deuda>> deudas = ref.watch(deudasProvider);

    return NeoScaffold(
      appBar: NeoAppBar(
        title: 'Deudas',
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: NeoIconButton(
              icon: Icons.calculate_outlined,
              tooltip: 'Simular crédito',
              variant: NeoIconButtonVariant.secondary,
              onPressed: () => context.push<void>(AppRoutes.simulador),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(value: true, label: Text('Activas')),
                ButtonSegment<bool>(value: false, label: Text('Historial')),
              ],
              selected: <bool>{_verActivas},
              onSelectionChanged: (Set<bool> seleccion) =>
                  setState(() => _verActivas = seleccion.first),
            ),
          ),
          Expanded(
            child: deudas.when(
              loading: () => const NeoLoading(rows: 3),
              error: (Object error, StackTrace stack) => NeoErrorState(
                message: error is AppFailure
                    ? failureMessage(error)
                    : 'No se pudieron cargar las deudas.',
                onRetry: () => ref.read(deudasProvider.notifier).refrescar(),
              ),
              data: (List<Deuda> lista) => _lista(lista),
            ),
          ),
        ],
      ),
      floatingActionButton: NeoButton(
        label: 'Nueva deuda',
        icon: Icons.add,
        onPressed: _abrirAlta,
      ),
    );
  }

  Widget _lista(List<Deuda> lista) {
    final List<Deuda> visibles = lista
        .where((Deuda d) => _verActivas ? d.estado.activa : !d.estado.activa)
        .toList(growable: false);

    if (visibles.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(deudasProvider.notifier).refrescar(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            _EmptyDeudas(
              message: _verActivas
                  ? 'No tienes deudas activas.'
                  : 'No hay deudas pagadas ni canceladas.',
              onRegistrar: _verActivas ? _abrirAlta : null,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(deudasProvider.notifier).refrescar(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        itemCount: visibles.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final Deuda deuda = visibles[index];
          return _DeudaCard(
            deuda: deuda,
            onTap: () => context.push<void>(AppRoutes.deudaDetalle(deuda.id)),
          );
        },
      ),
    );
  }

  Future<void> _abrirAlta() async {
    final bool? creada = await context.push<bool>(AppRoutes.nuevaDeuda);
    if (creada ?? false) {
      await ref.read(deudasProvider.notifier).refrescar();
    }
  }
}

/// Marcador para reconocer un `AppFailure` sin exponer el import en la lista.
abstract interface class AppFailureLike {
  Object get failure;
}

class _DeudaCard extends StatelessWidget {
  const _DeudaCard({required this.deuda, required this.onTap});

  final Deuda deuda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    final Color fondo = switch (deuda.estado) {
      EstadoDeuda.pendiente => AppColors.yellow,
      EstadoDeuda.pagada => AppColors.green,
      EstadoDeuda.cancelada => AppColors.lavender,
    };
    final String proxima = deuda.proximaCuotaNumero == null
        ? 'Sin cuotas pendientes'
        : 'Próxima cuota ${deuda.proximaCuotaNumero} · '
              '${Money.formatClp(deuda.proximaCuotaMontoPendiente ?? deuda.montoRestante)}'
              '${deuda.proximaFechaVencimiento == null ? '' : ' · vence ${deuda.proximaFechaVencimiento}'}';

    return NeoSurface(
      density: AppDensity.section,
      color: fondo,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  deuda.nombre,
                  style: textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              NeoBadge(
                label: estadoDeudaLabel(deuda.estado),
                color: AppColors.paper,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${tipoDeudaLabel(deuda.tipo)} · ${modalidadLabel(deuda.modalidad)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          NeoProgress(value: deuda.progreso, color: AppColors.ink, trackColor: AppColors.paper),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('${deuda.cuotasPagadas} de ${deuda.cantidadCuotas} cuotas'),
              Text(
                'Pendiente: ${Money.formatClp(deuda.montoRestante)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(proxima, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyDeudas extends StatelessWidget {
  const _EmptyDeudas({required this.message, this.onRegistrar});

  final String message;
  final VoidCallback? onRegistrar;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: AppRadii.smAll,
                  border: Border.all(
                    color: colors.border,
                    width: AppBorders.regular,
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(message, style: textTheme.titleSmall),
              ),
            ],
          ),
          if (onRegistrar != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            NeoButton(
              label: 'Registrar mi primera deuda',
              variant: NeoButtonVariant.secondary,
              expanded: true,
              onPressed: onRegistrar,
            ),
          ],
        ],
      ),
    );
  }
}
