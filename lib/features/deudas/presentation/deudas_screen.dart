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

    return Scaffold(
      appBar: AppBar(title: const Text('Deudas')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
              loading: () => const Center(
                child: CircularProgressIndicator.adaptive(),
              ),
              error: (Object error, StackTrace stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      error is AppFailure
                          ? failureMessage(error)
                          : 'No se pudieron cargar las deudas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () =>
                          ref.read(deudasProvider.notifier).refrescar(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (List<Deuda> lista) => _lista(lista),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirAlta,
        icon: const Icon(Icons.add),
        label: const Text('Nueva deuda'),
      ),
    );
  }

  Widget _lista(List<Deuda> lista) {
    final List<Deuda> visibles = lista
        .where((Deuda d) => _verActivas ? d.estado.activa : !d.estado.activa)
        .toList(growable: false);

    if (visibles.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 48),
          Text(
            _verActivas
                ? 'No tienes deudas activas.'
                : 'No hay deudas pagadas ni canceladas.',
            textAlign: TextAlign.center,
          ),
          if (_verActivas) ...<Widget>[
            const SizedBox(height: 12),
            Center(
              child: FilledButton(
                onPressed: _abrirAlta,
                child: const Text('Registrar mi primera deuda'),
              ),
            ),
          ],
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(deudasProvider.notifier).refrescar(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: visibles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String proxima = deuda.proximaCuotaNumero == null
        ? 'Sin cuotas pendientes'
        : 'Próxima cuota ${deuda.proximaCuotaNumero} · '
              '${Money.formatClp(deuda.proximaCuotaMontoPendiente ?? deuda.montoRestante)}'
              '${deuda.proximaFechaVencimiento == null ? '' : ' · vence ${deuda.proximaFechaVencimiento}'}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      deuda.nombre,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(
                    label: Text(estadoDeudaLabel(deuda.estado)),
                    labelStyle: TextStyle(
                      color: estadoDeudaColor(context, deuda.estado),
                      fontSize: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: estadoDeudaColor(context, deuda.estado),
                    ),
                  ),
                ],
              ),
              Text(
                '${tipoDeudaLabel(deuda.tipo)} · ${modalidadLabel(deuda.modalidad)}',
                style: Theme.of(context).textTheme.bodySmall,
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('${deuda.cuotasPagadas} de ${deuda.cantidadCuotas} cuotas'),
                  Text(
                    'Pendiente: ${Money.formatClp(deuda.montoRestante)}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: scheme.error),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(proxima, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
