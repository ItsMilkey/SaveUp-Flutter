import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/metas/data/dio_metas_repository.dart';
import 'package:saveup_app/features/metas/presentation/controllers/metas_controller.dart';
import 'package:saveup_app/features/movimientos/presentation/movimientos_controller.dart';

import 'metas_fixtures.dart';

void main() {
  late FakeMetasRepository repo;
  late FakeMovimientosController movimientos;
  late ProviderContainer container;

  void montar(FakeMetasRepository fake) {
    repo = fake;
    movimientos = FakeMovimientosController();
    container = ProviderContainer(
      overrides: [
        metasRepositoryProvider.overrideWithValue(repo),
        movimientosProvider.overrideWith(() => movimientos),
      ],
    );
    addTearDown(container.dispose);
  }

  test('carga las metas del usuario', () async {
    montar(FakeMetasRepository());
    final List<dynamic> lista = await container.read(metasProvider.future);
    expect(lista, hasLength(1));
    expect(lista.single.nombre, 'Viaje a Japón');
    expect(repo.llamadasListar, 1);
  });

  test('refrescar vuelve a consultar', () async {
    montar(FakeMetasRepository());
    await container.read(metasProvider.future);
    await container.read(metasProvider.notifier).refrescar();
    expect(repo.llamadasListar, 2);
  });

  test('abonar registra el movimiento y recarga la lista', () async {
    montar(FakeMetasRepository());
    await container.read(metasProvider.future);
    final int antes = repo.llamadasListar;

    final AppFailure? failure = await container
        .read(metaAccionesProvider.notifier)
        .abonar(3, monto: Decimal.fromInt(50000), descripcion: 'Abono');

    expect(failure, isNull);
    expect(repo.abonoId, 3);
    expect(repo.abonoMonto, Decimal.fromInt(50000));
    expect(repo.abonoDescripcion, 'Abono');
    expect(movimientos.refrescos, 1);

    final List<dynamic> lista = await container.read(metasProvider.future);
    expect(lista.single.montoActual.toString(), '300000');
    expect(repo.llamadasListar, greaterThan(antes));
  });

  test('retirar expone el detail del 409 y no cambia la lista', () async {
    montar(
      FakeMetasRepository(
        errorRetiro: const ConflictFailure(
          codigo: 'CONFLICTO_REGLA_NEGOCIO',
          detail: 'El monto a retirar no puede ser mayor al total ahorrado.',
        ),
      ),
    );
    await container.read(metasProvider.future);

    final AppFailure? failure = await container
        .read(metaAccionesProvider.notifier)
        .retirar(3, monto: Decimal.fromInt(999999), descripcion: 'Retiro');

    expect(failure, isA<ConflictFailure>());
    expect(
      (failure! as ConflictFailure).detail,
      'El monto a retirar no puede ser mayor al total ahorrado.',
    );
    expect(movimientos.refrescos, 0);
    final List<dynamic> lista = await container.read(metasProvider.future);
    expect(lista.single.montoActual.toString(), '250000');
  });

  test('eliminar quita la meta y recarga', () async {
    montar(FakeMetasRepository());
    await container.read(metasProvider.future);

    final AppFailure? failure = await container
        .read(metaAccionesProvider.notifier)
        .eliminar(3);

    expect(failure, isNull);
    expect(repo.eliminadoId, 3);
    expect(movimientos.refrescos, 1);
    final List<dynamic> lista = await container.read(metasProvider.future);
    expect(lista, isEmpty);
  });

  test('ignora abonos, retiros y eliminaciones duplicados en curso', () async {
    for (final String accion in <String>['abonar', 'retirar', 'eliminar']) {
      final Completer<void> pendiente = Completer<void>();
      final FakeMetasRepository fake = FakeMetasRepository()
        ..accionPendiente = pendiente.future;
      montar(fake);

      final MetaAccionesController acciones =
          container.read(metaAccionesProvider.notifier);
      final Future<AppFailure?> primera = switch (accion) {
        'abonar' => acciones.abonar(
          3,
          monto: Decimal.fromInt(1000),
          descripcion: 'Abono',
        ),
        'retirar' => acciones.retirar(
          3,
          monto: Decimal.fromInt(1000),
          descripcion: 'Retiro',
        ),
        _ => acciones.eliminar(3),
      };
      final Future<AppFailure?> segunda = switch (accion) {
        'abonar' => acciones.abonar(
          3,
          monto: Decimal.fromInt(1000),
          descripcion: 'Abono',
        ),
        'retirar' => acciones.retirar(
          3,
          monto: Decimal.fromInt(1000),
          descripcion: 'Retiro',
        ),
        _ => acciones.eliminar(3),
      };

      expect(await segunda, isNull);
      expect(fake.llamadasAbonar, accion == 'abonar' ? 1 : 0);
      expect(fake.llamadasRetirar, accion == 'retirar' ? 1 : 0);
      expect(fake.llamadasEliminar, accion == 'eliminar' ? 1 : 0);

      pendiente.complete();
      expect(await primera, isNull);
    }
  });

  test('un error al listar queda en el AsyncValue', () async {
    montar(
      FakeMetasRepository(errorListar: const NetworkFailure()),
    );
    final sub = container.listen(metasProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(metasProvider).error, isA<NetworkFailure>());
    sub.close();
  });
}
