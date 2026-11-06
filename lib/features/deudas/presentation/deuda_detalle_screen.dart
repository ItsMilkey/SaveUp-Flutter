import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/money/money.dart';
import '../domain/deuda.dart';
import 'deuda_labels.dart';
import 'deudas_controller.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deuda'),
        actions: <Widget>[
          if (detalle.value?.editable ?? false)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar deuda',
              onPressed: () => _abrirEdicion(context, ref, detalle.value!),
            ),
        ],
      ),
      body: detalle.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (Object error, StackTrace stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                error is AppFailure
                    ? failureMessage(error)
                    : 'No se pudo cargar la deuda.',
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(deudaDetalleProvider(id));
                  ref.invalidate(amortizacionProvider(id));
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (Deuda deuda) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: <Widget>[
            _Ficha(deuda: deuda),
            const SizedBox(height: 16),
            Text(
              'Cronograma de cuotas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            cronograma.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
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
          ],
        ),
      ),
    );
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

class _Ficha extends StatelessWidget {
  const _Ficha({required this.deuda});

  final Deuda deuda;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    Widget fila(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 150, child: Text(label, style: theme.textTheme.bodySmall)),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(deuda.nombre, style: theme.textTheme.titleLarge),
                ),
                Chip(
                  label: Text(estadoDeudaLabel(deuda.estado)),
                  labelStyle: TextStyle(
                    color: estadoDeudaColor(context, deuda.estado),
                    fontSize: 12,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (deuda.descripcion != null && deuda.descripcion!.isNotEmpty)
              Text(deuda.descripcion!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              '${tipoDeudaLabel(deuda.tipo)} · ${modalidadLabel(deuda.modalidad)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: deuda.progreso,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text('${deuda.cuotasPagadas} de ${deuda.cantidadCuotas} cuotas pagadas'),
            const SizedBox(height: 12),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: <Widget>[
            for (final CuotaAmortizacion cuota in cuotas)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
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
      ),
    );
  }
}
