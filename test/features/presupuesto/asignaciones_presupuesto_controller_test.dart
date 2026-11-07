import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/metas/data/dio_metas_repository.dart';
import 'package:saveup_app/features/metas/domain/meta_ahorro.dart';
import 'package:saveup_app/features/presupuesto/data/dio_presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/asignacion_presupuesto.dart';
import 'package:saveup_app/features/presupuesto/presentation/controllers/asignaciones_presupuesto_controller.dart';

import '../metas/metas_fixtures.dart';
import 'presupuesto_fixtures.dart';

void main() {
  late FakePresupuestoRepository presupuesto;
  late FakeMetasRepository metas;
  late ProviderContainer container;

  void montar({
    List<AsignacionPresupuesto>? asignaciones,
    AppFailure? error,
    List<MetaAhorro>? listaMetas,
  }) {
    presupuesto = FakePresupuestoRepository(
      asignaciones: asignaciones,
      errorAsignaciones: error,
    );
    metas = FakeMetasRepository(
      metas: listaMetas ??
          <MetaAhorro>[
            metaDePrueba(id: 3, nombre: 'Viaje'),
            metaDePrueba(id: 4, nombre: 'Notebook', objetivo: '800000'),
          ],
    );
    container = ProviderContainer(
      overrides: [
        presupuestoRepositoryProvider.overrideWithValue(presupuesto),
        metasRepositoryProvider.overrideWithValue(metas),
      ],
    );
    addTearDown(container.dispose);
  }

  AsignacionesPresupuestoController controller() =>
      container.read(asignacionesPresupuestoProvider.notifier);

  AsignacionesPresupuestoState state() =>
      container.read(asignacionesPresupuestoProvider);

  test('carga asignaciones y metas existentes', () async {
    montar(
      asignaciones: <AsignacionPresupuesto>[
        AsignacionPresupuesto(
          metaId: 3,
          metaNombre: 'Viaje',
          porcentaje: Decimal.parse('60'),
        ),
        AsignacionPresupuesto(
          metaId: 4,
          metaNombre: 'Notebook',
          porcentaje: Decimal.parse('40'),
        ),
      ],
    );

    await controller().cargar();

    expect(state().cargadas, isTrue);
    expect(state().valores, hasLength(2));
    expect(state().total, Decimal.parse('100'));
    expect(state().valido, isTrue);
    expect(state().disponibles, isEmpty);
  });

  test('si el GET falla la sección queda no cargada', () async {
    montar(error: const ServerFailure());

    await controller().cargar();

    expect(state().cargadas, isFalse);
    expect(state().errorCarga, isA<ServerFailure>());
  });

  test('agregar reparte el 100 % en partes iguales', () async {
    montar(
      asignaciones: <AsignacionPresupuesto>[
        AsignacionPresupuesto(
          metaId: 3,
          metaNombre: 'Viaje',
          porcentaje: Decimal.parse('100'),
        ),
      ],
    );
    await controller().cargar();

    controller().agregar(4);

    expect(state().valores[3], Decimal.parse('50'));
    expect(state().valores[4], Decimal.parse('50'));
    expect(state().total, Decimal.parse('100'));
  });

  test('mover un porcentaje reajusta el resto sin romper la suma', () async {
    montar(
      asignaciones: <AsignacionPresupuesto>[
        AsignacionPresupuesto(
          metaId: 3,
          metaNombre: 'Viaje',
          porcentaje: Decimal.parse('60'),
        ),
        AsignacionPresupuesto(
          metaId: 4,
          metaNombre: 'Notebook',
          porcentaje: Decimal.parse('40'),
        ),
      ],
    );
    await controller().cargar();

    controller().setPorcentaje(3, Decimal.parse('70'));

    expect(state().valores[3], Decimal.parse('70'));
    expect(state().valores[4], Decimal.parse('30'));
    expect(state().total, Decimal.parse('100'));
  });

  test('quitar una meta redistribuye el porcentaje restante', () async {
    montar(
      asignaciones: <AsignacionPresupuesto>[
        AsignacionPresupuesto(
          metaId: 3,
          metaNombre: 'Viaje',
          porcentaje: Decimal.parse('60'),
        ),
        AsignacionPresupuesto(
          metaId: 4,
          metaNombre: 'Notebook',
          porcentaje: Decimal.parse('40'),
        ),
      ],
    );
    await controller().cargar();

    controller().quitar(3);

    expect(state().valores.containsKey(3), isFalse);
    expect(state().valores[4], Decimal.parse('100'));
  });

  test('limpiar deja el conjunto vacío para enviar []', () async {
    montar(
      asignaciones: <AsignacionPresupuesto>[
        AsignacionPresupuesto(
          metaId: 3,
          metaNombre: 'Viaje',
          porcentaje: Decimal.parse('100'),
        ),
      ],
    );
    await controller().cargar();

    controller().limpiar();

    expect(state().valores, isEmpty);
    expect(state().datos, isEmpty);
    expect(state().valido, isTrue);
  });
}
