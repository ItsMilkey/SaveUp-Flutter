import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../app/routes.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/time_zones.dart';
import '../../presupuesto/domain/plan_mensual.dart';
import '../domain/deuda.dart';
import '../domain/pago_deuda.dart';
import 'asociar_partida_deuda_dialog.dart';
import 'cancelar_deuda_dialog.dart';
import 'deuda_labels.dart';
import 'deuda_partida_controller.dart';
import 'deudas_controller.dart';
import 'pago_deuda_dialog.dart';

/// Detalle de una deuda: ficha, cronograma y (fase 2) pagos/cancelación.
class DeudaDetalleScreen extends ConsumerWidget {
  const DeudaDetalleScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Deuda> detalle = ref.watch(deudaDetalleProvider(id));
    final AsyncValue<List<CuotaAmortizacion>> cronograma = ref.watch(
      amortizacionProvider(id),
    );
    final Deuda? deuda = detalle.value;

    return NeoScaffold(
      appBar: NeoAppBar(
        title: 'Deuda',
        actions: <Widget>[
          if (deuda?.editable ?? false)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: NeoIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Editar deuda',
                variant: NeoIconButtonVariant.secondary,
                onPressed: () => _abrirEdicion(context, ref, deuda!),
              ),
            ),
        ],
      ),
      bottomNavigationBar: deuda?.estado == EstadoDeuda.pendiente
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: NeoButton(
                        label: 'Registrar pago',
                        icon: Icons.payments_outlined,
                        expanded: true,
                        onPressed: () => _pagar(context, ref, deuda!),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _cancelar(context, ref, deuda!),
                      child: const Text('Cancelar deuda'),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: detalle.when(
        loading: () => const NeoLoading(rows: 4),
        error: (Object error, StackTrace stack) => NeoErrorState(
          message: error is AppFailure
              ? failureMessage(error)
              : 'No se pudo cargar la deuda.',
          onRetry: () {
            ref.invalidate(deudaDetalleProvider(id));
            ref.invalidate(amortizacionProvider(id));
          },
        ),
        data: (Deuda deuda) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl * 2,
          ),
          children: <Widget>[
            _Ficha(deuda: deuda),
            const SizedBox(height: AppSpacing.lg),
            const NeoSectionHeader(title: 'Cronograma de cuotas'),
            cronograma.when(
              loading: () => const NeoLoading(message: '', rows: 2),
              error: (Object error, StackTrace stack) => Row(
                children: <Widget>[
                  const Expanded(
                    child: Text('No se pudo cargar el cronograma.'),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(amortizacionProvider(id)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
              data: (List<CuotaAmortizacion> cuotas) =>
                  _Cronograma(cuotas: cuotas),
            ),
            const SizedBox(height: AppSpacing.lg),
            _HistorialPagosSection(deudaId: id),
          ],
        ),
      ),
    );
  }

  Future<void> _pagar(
    BuildContext context,
    WidgetRef ref,
    Deuda deuda,
  ) async {
    final bool? pagado = await PagoDeudaDialog.show(context, deuda);
    if (pagado ?? false) {
      _refrescar(ref, deuda.id);
      if (context.mounted) {
        NeoSnackbar.show(
          context,
          'Pago registrado.',
          tone: NeoSnackbarTone.success,
        );
      }
    }
  }

  Future<void> _cancelar(
    BuildContext context,
    WidgetRef ref,
    Deuda deuda,
  ) async {
    final bool? cancelada = await CancelarDeudaDialog.show(context, deuda);
    if (cancelada ?? false) {
      _refrescar(ref, deuda.id);
      if (context.mounted) {
        NeoSnackbar.show(
          context,
          'Deuda cancelada.',
          tone: NeoSnackbarTone.warning,
        );
      }
    }
  }

  void _refrescar(WidgetRef ref, int deudaId) {
    ref.invalidate(deudaDetalleProvider(deudaId));
    ref.invalidate(amortizacionProvider(deudaId));
    ref.invalidate(deudasProvider);
    ref.read(pagosDeudaProvider.notifier).cargar(deudaId, forzar: true);
  }

  Future<void> _abrirEdicion(
    BuildContext context,
    WidgetRef ref,
    Deuda deuda,
  ) async {
    final bool? actualizada = await context.push<bool>(
      AppRoutes.editarDeuda(deuda.id),
      extra: deuda,
    );
    if (actualizada ?? false) {
      ref.invalidate(deudaDetalleProvider(deuda.id));
      ref.invalidate(amortizacionProvider(deuda.id));
      ref.invalidate(deudasProvider);
    }
  }
}

class _Ficha extends ConsumerWidget {
  const _Ficha({required this.deuda});

  final Deuda deuda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    Widget fila(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(label, style: textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: textTheme.bodyMedium),
          ),
        ],
      ),
    );

    return NeoSurface(
      density: AppDensity.section,
      color: fondo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(deuda.nombre, style: textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              NeoBadge(
                label: estadoDeudaLabel(deuda.estado),
                color: AppColors.paper,
                compact: true,
              ),
              _AsociacionPartida(deuda: deuda),
            ],
          ),
          if (deuda.estado == EstadoDeuda.pendiente &&
              deuda.fechaPrimeraCuota == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Para asociarla al plan, la deuda necesita cuotas con fecha.',
                style: textTheme.bodySmall,
              ),
            ),
          if (deuda.descripcion != null && deuda.descripcion!.isNotEmpty)
            Text(deuda.descripcion!, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${tipoDeudaLabel(deuda.tipo)} · ${modalidadLabel(deuda.modalidad)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          NeoProgress(value: deuda.progreso, color: AppColors.ink, trackColor: AppColors.paper),
          const SizedBox(height: AppSpacing.xs),
          Text('${deuda.cuotasPagadas} de ${deuda.cantidadCuotas} cuotas pagadas'),
          const SizedBox(height: AppSpacing.md),
            fila('Capital', Money.formatClp(deuda.montoCapital)),
            fila(
              'Cuota',
              deuda.valorCuota == null
                  ? '—'
                  : Money.formatClp(deuda.valorCuota!),
            ),
            fila('Tasa mensual', '${deuda.tasaMensual} %'),
            fila('Tasa anual efectiva', '${deuda.tasaAnualEfectiva} %'),
            fila('CAE', '${deuda.cargaAnualEquivalente} %'),
            fila('Gastos iniciales', Money.formatClp(deuda.gastosIniciales)),
            fila(
              'Costo adicional por cuota',
              Money.formatClp(deuda.costoAdicionalPorCuota),
            ),
            fila('Costo total del crédito', Money.formatClp(deuda.costoTotalCredito)),
            fila('Monto total', Money.formatClp(deuda.montoTotal)),
            fila('Pagado', Money.formatClp(deuda.montoPagado)),
            fila('Pendiente', Money.formatClp(deuda.montoRestante)),
            fila('Total por pagar', Money.formatClp(deuda.totalPorPagar)),
            fila('Saldo capital', Money.formatClp(deuda.saldoCapital)),
            fila('Intereses pagados', Money.formatClp(deuda.interesesPagados)),
            if (deuda.proximaCuotaNumero != null)
              fila(
                'Próxima cuota',
                '${deuda.proximaCuotaNumero} · '
                    '${Money.formatClp(deuda.proximaCuotaMontoPendiente ?? deuda.montoRestante)}'
                    '${deuda.proximaFechaVencimiento == null ? '' : ' · vence ${deuda.proximaFechaVencimiento}'}',
              ),
            if (deuda.fechaPrimeraCuota != null)
              fila('Primera cuota', '${deuda.fechaPrimeraCuota}'),
            if (deuda.fechaUltimaCuota != null)
              fila('Última cuota', '${deuda.fechaUltimaCuota}'),
            if (deuda.cuotasPagadasPrevias > 0)
              fila('Cuotas previas', '${deuda.cuotasPagadasPrevias}'),
            if (!deuda.editable && deuda.estado == EstadoDeuda.pendiente)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Edición bloqueada: la deuda ya tiene pagos registrados.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      );
  }
}

/// Estado de la partida del plan asociada a esta deuda (mes en curso).
class _AsociacionPartida extends ConsumerWidget {
  const _AsociacionPartida({required this.deuda});

  final Deuda deuda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PartidaPlan?> asociacion = ref.watch(
      partidaDeDeudaProvider(deuda.id),
    );
    return asociacion.when(
      loading: () => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (Object error, StackTrace stack) => TextButton(
        onPressed: () => ref.invalidate(partidaDeDeudaProvider(deuda.id)),
        child: const Text('Verificar plan'),
      ),
      data: (PartidaPlan? partida) {
        if (partida != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const NeoBadge(
                label: 'En el plan',
                icon: Icons.check,
                color: AppColors.green,
                compact: true,
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: () => context.go(AppRoutes.plan),
                child: const Text('Ver plan'),
              ),
            ],
          );
        }
        if (deuda.estado != EstadoDeuda.pendiente) {
          return const SizedBox.shrink();
        }
        final bool sinFechas = deuda.fechaPrimeraCuota == null;
        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (sinFechas)
              NeoButton(
                label: 'Agregar fechas',
                icon: Icons.event_available,
                variant: NeoButtonVariant.secondary,
                onPressed: () => _elegirFecha(context, ref),
              )
            else ...<Widget>[
              NeoButton(
                label: 'Asociar al plan',
                icon: Icons.playlist_add,
                variant: NeoButtonVariant.secondary,
                onPressed: () => _asociar(context, ref),
              ),
              TextButton(
                onPressed: () => _elegirFecha(context, ref),
                child: const Text('Cambiar fechas'),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _asociar(BuildContext context, WidgetRef ref) async {
    final bool? creada = await AsociarPartidaDeudaDialog.show(
      context,
      deuda: deuda,
    );
    if ((creada ?? false) && context.mounted) {
      NeoSnackbar.show(
        context,
        'Partida asociada al plan.',
        tone: NeoSnackbarTone.success,
      );
    }
  }

  /// Elige la fecha de la primera cuota y la guarda sin tocar las condiciones.
  Future<void> _elegirFecha(BuildContext context, WidgetRef ref) async {
    final DateTime hoy = DateTime.now();
    final CalendarDate? actual = deuda.fechaPrimeraCuota;
    final int dia = hoy.day > 28 ? 28 : hoy.day;
    final DateTime inicial = actual == null
        // Sugerencia: la próxima cuota impaga cae en el mes actual.
        ? DateTime(hoy.year, hoy.month - deuda.cuotasPagadas, dia)
        : DateTime(actual.year, actual.month, actual.day);
    final DateTime? elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(hoy.year + 5, 12, 31),
      helpText: 'Fecha de la primera cuota',
    );
    if (elegida == null || !context.mounted) {
      return;
    }
    final AppFailure? failure = await ref
        .read(deudaAccionesProvider.notifier)
        .actualizarFechaPrimeraCuota(
          deuda.id,
          CalendarDate(elegida.year, elegida.month, elegida.day),
        );
    if (!context.mounted) {
      return;
    }
    if (failure != null) {
      NeoSnackbar.show(
        context,
        failureMessage(failure),
        tone: NeoSnackbarTone.danger,
      );
      return;
    }
    NeoSnackbar.show(
      context,
      'Fechas actualizadas.',
      tone: NeoSnackbarTone.success,
    );
  }
}

class _Cronograma extends StatelessWidget {
  const _Cronograma({required this.cuotas});
  final List<CuotaAmortizacion> cuotas;

  @override
  Widget build(BuildContext context) {
    if (cuotas.isEmpty) {
      return const Text('Esta deuda no tiene cronograma calculado.');
    }
    final ThemeData theme = Theme.of(context);
    return NeoSurface(
      density: AppDensity.table,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: <Widget>[
          for (final CuotaAmortizacion cuota in cuotas)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${cuota.numero}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          cuota.fechaVencimiento == null
                              ? 'Cuota ${cuota.numero}'
                              : '${cuota.fechaVencimiento}',
                        ),
                        Text(
                          'Capital ${Money.formatClp(cuota.capital)} · '
                          'Interés ${Money.formatClp(cuota.interes)}'
                          '${cuota.previa ? ' · previa' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(Money.formatClp(cuota.cuota)),
                      Text(
                        estadoCuotaLabel(cuota.estado),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: switch (cuota.estado) {
                            EstadoCuota.pagada => theme.colorScheme.primary,
                            EstadoCuota.parcial => theme.colorScheme.tertiary,
                            _ => theme.colorScheme.onSurfaceVariant,
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Historial paginado de pagos (`GET /deudas/{id}/pagos`).
class _HistorialPagosSection extends ConsumerStatefulWidget {
  const _HistorialPagosSection({required this.deudaId});

  final int deudaId;

  @override
  ConsumerState<_HistorialPagosSection> createState() =>
      _HistorialPagosSectionState();
}

class _HistorialPagosSectionState
    extends ConsumerState<_HistorialPagosSection> {
  static final DateFormat _fecha = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pagosDeudaProvider.notifier).cargar(widget.deudaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final PagosDeudaState estado = ref.watch(pagosDeudaProvider);
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const NeoSectionHeader(title: 'Historial de pagos'),
        if (estado.cargando && estado.items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator.adaptive(),
            ),
          )
        else if (estado.error != null && estado.items.isEmpty)
          Row(
            children: <Widget>[
              const Expanded(child: Text('No se pudo cargar el historial.')),
              TextButton(
                onPressed: () => ref
                    .read(pagosDeudaProvider.notifier)
                    .cargar(widget.deudaId, forzar: true),
                child: const Text('Reintentar'),
              ),
            ],
          )
        else if (estado.items.isEmpty)
          const Text('Todavía no hay pagos registrados.')
        else
          NeoSurface(
            density: AppDensity.table,
            child: Column(
              children: <Widget>[
                for (final PagoDeuda pago in estado.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(pago.descripcion),
                              Text(
                                '${_fechaLocal(pago.fecha)} · '
                                'Capital ${Money.formatClp(pago.capital)} · '
                                'Interés ${Money.formatClp(pago.interes)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Money.formatClp(pago.monto),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (estado.hayMas)
                  TextButton(
                    onPressed: estado.cargandoMas
                        ? null
                        : ref.read(pagosDeudaProvider.notifier).cargarMas,
                    child: estado.cargandoMas
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Cargar más (${estado.items.length} de '
                            '${estado.totalItems})',
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _fechaLocal(DateTime instant) {
    final tz.TZDateTime local = tz.TZDateTime.from(instant, businessTimeZone);
    return _fecha.format(local);
  }
}