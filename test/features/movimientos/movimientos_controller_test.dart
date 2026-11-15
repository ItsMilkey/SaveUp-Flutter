import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/movimientos/data/dio_movimientos_repository.dart';
import 'package:saveup_app/features/movimientos/data/dio_saldos_repository.dart';
import 'package:saveup_app/features/movimientos/domain/movimiento.dart';
import 'package:saveup_app/features/movimientos/domain/movimiento_filtro.dart';
import 'package:saveup_app/features/movimientos/domain/movimiento_tipo.dart';
import 'package:saveup_app/features/movimientos/domain/movimientos_repository.dart';
import 'package:saveup_app/features/movimientos/domain/saldos_repository.dart';
import 'package:saveup_app/features/movimientos/presentation/movimientos_controller.dart';

class _PendingPage {
  _PendingPage(this.filtro, this.page);

  final MovimientoFiltro filtro;
  final int page;
  final Completer<PaginaMovimientos> completer = Completer<PaginaMovimientos>();
}

class _MovimientosFake implements MovimientosRepository {
  final List<_PendingPage> requests = <_PendingPage>[];

  @override
  Future<PaginaMovimientos> pagina({
    required MovimientoFiltro filtro,
    required int page,
    int size = 50,
  }) {
    final _PendingPage request = _PendingPage(filtro, page);
    requests.add(request);
    return request.completer.future;
  }

  @override
  Future<void> eliminar(int id) async {}

  @override
  Future<Movimiento> editar({
    required int id,
    Decimal? monto,
    String? descripcion,
    int? categoriaId,
    int? partidaId,
    bool desvincularPartida = false,
  }) => throw UnimplementedError();

  @override
  Future<void> registrar({
    required Decimal monto,
    required String descripcion,
    required MovimientoTipo tipo,
    int? categoriaId,
    int? partidaId,
  }) async {}
}

class _SaldosFake implements SaldosRepository {
  @override
  Future<Decimal> saldoActual() async => Decimal.zero;
}

PaginaMovimientos pagina(int id, {int currentPage = 0, int totalPages = 1}) {
  return PaginaMovimientos(
    content: <Movimiento>[
      Movimiento(
        id: id,
        monto: Decimal.fromInt(-100),
        descripcion: 'Movimiento $id',
        fecha: DateTime.utc(2026),
        tipo: MovimientoTipo.gastoGeneral,
      ),
    ],
    currentPage: currentPage,
    totalItems: totalPages,
    totalPages: totalPages,
  );
}

void main() {
  late _MovimientosFake movimientos;
  late ProviderContainer container;

  setUp(() {
    movimientos = _MovimientosFake();
    container = ProviderContainer(
      overrides: [
        movimientosRepositoryProvider.overrideWithValue(movimientos),
        saldosRepositoryProvider.overrideWithValue(_SaldosFake()),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'ignora resultado y error de cargas anteriores al último filtro',
    () async {
      final MovimientosController controller = container.read(
        movimientosProvider.notifier,
      );
      final Future<void> inicial = controller.inicializar();
      expect(movimientos.requests, hasLength(1));

      controller.setTipo(MovimientoTipo.gastoGeneral);
      expect(movimientos.requests, hasLength(2));
      expect(movimientos.requests.first.filtro.tipo, isNull);
      expect(
        movimientos.requests.last.filtro.tipo,
        MovimientoTipo.gastoGeneral,
      );

      movimientos.requests.last.completer.complete(pagina(2));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(movimientosProvider).items.single.id, 2);

      movimientos.requests.first.completer.completeError(
        const NetworkFailure(),
      );
      await inicial;
      expect(container.read(movimientosProvider).items.single.id, 2);
      expect(container.read(movimientosProvider).errorPagina, isNull);
      expect(
        container.read(movimientosProvider).filtro.tipo,
        MovimientoTipo.gastoGeneral,
      );
    },
  );

  test('refresh más reciente invalida una página pendiente', () async {
    final MovimientosController controller = container.read(
      movimientosProvider.notifier,
    );
    final Future<void> inicial = controller.inicializar();
    movimientos.requests[0].completer.complete(pagina(1, totalPages: 2));
    await inicial;

    final Future<void> cargarMas = controller.cargarMas();
    expect(movimientos.requests.last.page, 1);
    final Future<void> refrescar = controller.refrescar();
    expect(movimientos.requests.last.page, 0);

    movimientos.requests.last.completer.complete(pagina(3));
    await refrescar;
    movimientos.requests[1].completer.complete(
      pagina(2, currentPage: 1, totalPages: 2),
    );
    await cargarMas;

    expect(container.read(movimientosProvider).items.map((m) => m.id), <int>[
      3,
    ]);
    expect(container.read(movimientosProvider).page, 0);
  });
}
