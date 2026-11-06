import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../app/config.dart';
import '../../../app/routes.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/time_zones.dart';
import '../../account/presentation/eliminar_cuenta_dialog.dart';
import '../../auth/presentation/auth_controllers.dart';
import '../domain/movimiento.dart';
import '../domain/movimiento_filtro.dart';
import '../domain/movimiento_tipo.dart';
import 'movimientos_controller.dart';

/// Nombre visible del tipo de movimiento (filtros y filas).
String tipoMovimientoLabel(MovimientoTipo tipo) => switch (tipo) {
  MovimientoTipo.ingresoGeneral => 'Ingreso',
  MovimientoTipo.gastoGeneral => 'Gasto',
  MovimientoTipo.pagoDeuda => 'Pago de deuda',
  MovimientoTipo.abonoMeta => 'Abono a meta',
  MovimientoTipo.retiroMeta => 'Retiro de meta',
};

/// Home real (primer slice de F3): saldo, filtros y movimientos paginados.
class MovimientosScreen extends ConsumerStatefulWidget {
  const MovimientosScreen({super.key});

  @override
  ConsumerState<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends ConsumerState<MovimientosScreen> {
  static final DateFormat _fechaVisible = DateFormat('dd-MM-yyyy');

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(movimientosProvider.notifier).inicializar();
      }
    });
    _scroll.addListener(_alAcercarseAlFinal);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_alAcercarseAlFinal)
      ..dispose();
    super.dispose();
  }

  void _alAcercarseAlFinal() {
    if (!_scroll.hasClients) {
      return;
    }
    final double restante =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (restante < 400) {
      ref.read(movimientosProvider.notifier).cargarMas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MovimientosState estado = ref.watch(movimientosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: <Widget>[
          _CuentaMenu(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authSessionProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(movimientosProvider.notifier).refrescar(),
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            _TarjetaSaldo(estado: estado),
            const SizedBox(height: 16),
            _Filtros(estado: estado),
            const SizedBox(height: 8),
            ..._contenido(context, estado),
          ],
        ),
      ),
    );
  }

  List<Widget> _contenido(BuildContext context, MovimientosState estado) {
    if (estado.cargandoPagina) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ];
    }
    if (estado.errorPagina != null) {
      return <Widget>[
        _ErrorConReintento(
          mensaje: failureMessage(estado.errorPagina!),
          onReintentar: () => ref
              .read(movimientosProvider.notifier)
              .refrescar(),
        ),
      ];
    }
    if (estado.vacio) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: <Widget>[
              const Text('No hay movimientos para estos filtros.'),
              if (estado.filtrosActivos) ...<Widget>[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref
                      .read(movimientosProvider.notifier)
                      .limpiarFiltros(),
                  child: const Text('Quitar filtros'),
                ),
              ],
            ],
          ),
        ),
      ];
    }
    return <Widget>[
      for (final Movimiento movimiento in estado.items)
        _MovimientoTile(movimiento: movimiento),
      if (estado.cargandoMas)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator.adaptive()),
        )
      else if (!estado.hayMas && estado.items.isNotEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text('No hay más movimientos.')),
        ),
    ];
  }

  /// Formato local (America/Santiago) de la fecha del movimiento.
  static String fechaLocal(DateTime instant) {
    final tz.TZDateTime local = tz.TZDateTime.from(
      instant,
      businessTimeZone,
    );
    return _fechaVisible.format(local);
  }
}

class _TarjetaSaldo extends ConsumerWidget {
  const _TarjetaSaldo({required this.estado});

  final MovimientosState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Saldo disponible', style: text.titleSmall),
            const SizedBox(height: 8),
            if (estado.saldoError != null)
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      failureMessage(estado.saldoError!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(movimientosProvider.notifier)
                        .refrescar(),
                    child: const Text('Reintentar'),
                  ),
                ],
              )
            else if (estado.cargandoSaldo || estado.saldo == null)
              const SizedBox(
                height: 32,
                child: Center(
                  child: LinearProgressIndicator(),
                ),
              )
            else
              Text(
                Money.formatClp(estado.saldo!),
                style: text.headlineMedium?.copyWith(
                  color: estado.saldo! < Decimal.zero
                      ? Theme.of(context).colorScheme.error
                      : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Filtros extends ConsumerWidget {
  const _Filtros({required this.estado});

  final MovimientosState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MovimientosController controller = ref.read(
      movimientosProvider.notifier,
    );
    final MovimientoFiltro filtro = estado.filtro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            OutlinedButton.icon(
              icon: const Icon(Icons.event, size: 18),
              label: Text(
                filtro.desde == null ? 'Desde' : 'Desde ${filtro.desde}',
              ),
              onPressed: () => _elegirFecha(context, controller, esDesde: true),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_available, size: 18),
              label: Text(
                filtro.hasta == null ? 'Hasta' : 'Hasta ${filtro.hasta}',
              ),
              onPressed: () =>
                  _elegirFecha(context, controller, esDesde: false),
            ),
            DropdownButton<MovimientoTipo>(
              value: filtro.tipo,
              hint: const Text('Todos los tipos'),
              underline: const SizedBox.shrink(),
              items: <DropdownMenuItem<MovimientoTipo>>[
                for (final MovimientoTipo tipo in MovimientoTipo.todos)
                  DropdownMenuItem<MovimientoTipo>(
                    value: tipo,
                    child: Text(tipoMovimientoLabel(tipo)),
                  ),
              ],
              onChanged: controller.setTipo,
            ),
            if (estado.filtrosActivos)
              TextButton(
                onPressed: controller.limpiarFiltros,
                child: const Text('Limpiar'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          estado.inicializado
              ? '${estado.totalItems} movimiento(s)'
              : 'Cargando movimientos…',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _elegirFecha(
    BuildContext context,
    MovimientosController controller, {
    required bool esDesde,
  }) async {
    final DateTime inicial = DateTime.now();
    final DateTime? elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(inicial.year + 1, 12, 31),
      helpText: esDesde ? 'Fecha desde' : 'Fecha hasta',
    );
    if (elegida == null) {
      return;
    }
    final CalendarDate fecha = CalendarDate(
      elegida.year,
      elegida.month,
      elegida.day,
    );
    if (esDesde) {
      controller.setDesde(fecha);
    } else {
      controller.setHasta(fecha);
    }
  }
}

class _MovimientoTile extends StatelessWidget {
  const _MovimientoTile({required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context) {
    final bool negativo = movimiento.monto < Decimal.zero;
    final String categoria =
        movimiento.categoria?.nombre ?? tipoMovimientoLabel(movimiento.tipo);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(movimiento.descripcion),
      subtitle: Text(
        '${_MovimientosScreenState.fechaLocal(movimiento.fecha)} · $categoria',
      ),
      trailing: Text(
        Money.formatClp(movimiento.monto),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: negativo
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ErrorConReintento extends StatelessWidget {
  const _ErrorConReintento({
    required this.mensaje,
    required this.onReintentar,
  });

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: <Widget>[
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Menú con las entradas de cuenta que vivían en el home provisorio (F2).
class _CuentaMenu extends StatelessWidget {
  const _CuentaMenu();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle_outlined),
      tooltip: 'Cuenta',
      onSelected: (String opcion) {
        switch (opcion) {
          case 'cambiar':
            GoRouter.of(context).push(AppRoutes.cambiarContrasena);
          case 'eliminar':
            EliminarCuentaDialog.show(context);
          case 'legales':
            GoRouter.of(context).push(AppRoutes.legales);
        }
      },
      itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'cambiar',
          child: Text('Cambiar contraseña'),
        ),
        PopupMenuItem<String>(
          value: 'eliminar',
          child: Text('Eliminar cuenta'),
        ),
        PopupMenuItem<String>(
          value: 'legales',
          child: Text('Términos y privacidad'),
        ),
      ],
    );
  }
}
