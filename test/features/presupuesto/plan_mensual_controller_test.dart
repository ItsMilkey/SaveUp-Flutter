import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/presupuesto/data/dio_plan_mensual_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_mensual.dart';
import 'package:saveup_app/features/presupuesto/presentation/controllers/plan_mensual_controller.dart';

import 'plan_fixtures.dart';

PartidaSpec partida(
  int id,
  String nombre,
  String monto, {
  int categoriaId = 2,
  TipoPresupuesto tipo = TipoPresupuesto.necesidad,
  int? deudaId,
}) {
  return PartidaSpec(
    id: id,
    nombre: nombre,
    categoriaId: categoriaId,
    codigo: 'CAT_$categoriaId',
    tipo: tipo,
    monto: d(monto),
    deudaId: deudaId,
  );
}

void main() {
  late FakePlanMensualRepository repo;
  late ProviderContainer container;

  PlanMensual planBase({int extraPartidas = 0}) {
    return planDePrueba(
      ingresoReferencia: d('1000000'),
      partidas: <PartidaSpec>[
        PartidaSpec(
          id: 1,
          nombre: 'Arriendo',
          categoriaId: 4,
          codigo: 'VIVIENDA_SUMINISTROS',
          tipo: TipoPresupuesto.necesidad,
          monto: d('400000'),
        ),
        partida(2, 'Supermercado', '250000'),
        if (extraPartidas > 0)
          for (int i = 0; i < extraPartidas; i++)
            partida(3 + i, 'Extra $i', '1000'),
      ],
    );
  }

  void montar(PlanMensual plan) {
    repo = FakePlanMensualRepository(plan: plan);
    container = ProviderContainer(
      overrides: [
        planMensualRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
  }

  Future<void> cargar() async {
    await container.read(planMensualProvider.notifier).cargar('2026-11');
  }

  testWidgets('moverPartida recalcula local sin HTTP', (
    WidgetTester tester,
  ) async {
    montar(planBase());
    await cargar();

    final PlanMensualController controller = container.read(
      planMensualProvider.notifier,
    );
    controller.moverPartida(1, d('500000'));
    await tester.pump();

    final PlanMensualState estado = container.read(planMensualProvider);
    expect(repo.lotes, isEmpty);
    expect(estado.cambiosPendientes, <int, Decimal>{1: d('500000')});
    expect(
      estado.plan!.calculo.resumen.planificadoTotal.compareTo(d('750000')),
      0,
    );
    expect(
      estado.plan!.calculo.resumen.remanenteLibre!.compareTo(d('250000')),
      0,
    );
    expect(
      estado.plan!.partida(1)!.montoPlanificado.compareTo(d('500000')),
      0,
    );
    // El tope de otra partida usa el remanente ya recalculado.
    expect(controller.limiteSlider(2).compareTo(d('500000')), 0);
  });

  testWidgets('soltar envía un único PATCH con los cambios acumulados', (
    WidgetTester tester,
  ) async {
    montar(planBase());
    await cargar();
    final PlanMensualController controller = container.read(
      planMensualProvider.notifier,
    );

    controller.moverPartida(1, d('450000'));
    controller.moverPartida(2, d('300000'));
    await controller.soltar();
    await tester.pump();

    expect(repo.lotes, hasLength(1));
    expect(
      repo.lotes.single.map((CambioMonto c) => c.partidaId).toList()..sort(),
      <int>[1, 2],
    );
    final PlanMensualState estado = container.read(planMensualProvider);
    expect(estado.cambiosPendientes, isEmpty);
    expect(estado.enviandoLote, isFalse);
    expect(
      estado.plan!.partida(1)!.montoPlanificado.compareTo(d('450000')),
      0,
    );
  });

  testWidgets('un segundo ajuste durante el vuelo se envía en el siguiente lote',
      (WidgetTester tester) async {
    montar(planBase());
    await cargar();
    final PlanMensualController controller = container.read(
      planMensualProvider.notifier,
    );

    final Completer<PlanMensual> primerPendiente = Completer<PlanMensual>();
    repo.pendiente = primerPendiente;

    controller.moverPartida(1, d('450000'));
    final Future<void> primero = controller.soltar();
    await tester.pump();
    expect(repo.lotes, hasLength(1));

    // El slider no se bloquea: otro ajuste se acumula mientras vuela el PATCH.
    controller.moverPartida(2, d('300000'));
    final Future<void> segundo = controller.soltar();
    await tester.pump();
    expect(repo.lotes, hasLength(1));

    // Responde el servidor al primer lote; el segundo se envía solo.
    repo.pendiente = null;
    primerPendiente.complete(
      repo.aplicar(<CambioMonto>[
        CambioMonto(partidaId: 1, monto: d('450000')),
      ]),
    );
    await primero;
    await segundo;
    await tester.pump();
    await tester.pump();

    expect(repo.lotes, hasLength(2));
    expect(repo.lotes[1].single.partidaId, 2);
    expect(repo.lotes[1].single.monto.compareTo(d('300000')), 0);

    final PlanMensualState estado = container.read(planMensualProvider);
    expect(estado.cambiosPendientes, isEmpty);
    expect(
      estado.plan!.partida(1)!.montoPlanificado.compareTo(d('450000')),
      0,
    );
    expect(
      estado.plan!.partida(2)!.montoPlanificado.compareTo(d('300000')),
      0,
    );
  });

  testWidgets('partida vinculada a deuda: sin cambios ni envío', (
    WidgetTester tester,
  ) async {
    montar(
      planDePrueba(
        ingresoReferencia: d('1000000'),
        partidas: <PartidaSpec>[
          partida(20, 'Cuota crédito', '43500', deudaId: 77),
        ],
      ),
    );
    await cargar();
    final PlanMensualController controller = container.read(
      planMensualProvider.notifier,
    );

    controller.moverPartida(20, d('999999'));
    await controller.soltar();
    await tester.pump();

    expect(repo.lotes, isEmpty);
    final PlanMensualState estado = container.read(planMensualProvider);
    expect(estado.cambiosPendientes, isEmpty);
    expect(
      estado.plan!.partida(20)!.montoPlanificado.compareTo(d('43500')),
      0,
    );
  });

  testWidgets('error de PATCH conserva el estado local y permite reintentar', (
    WidgetTester tester,
  ) async {
    montar(planBase());
    await cargar();
    final PlanMensualController controller = container.read(
      planMensualProvider.notifier,
    );

    repo.error = const UnknownFailure(detail: 'sin red');
    controller.moverPartida(1, d('500000'));
    await controller.soltar();
    await tester.pump();

    PlanMensualState estado = container.read(planMensualProvider);
    expect(estado.errorLote, isNotNull);
    expect(estado.enviandoLote, isFalse);
    expect(estado.cambiosPendientes, <int, Decimal>{1: d('500000')});
    // La vista local no se pierde.
    expect(
      estado.plan!.partida(1)!.montoPlanificado.compareTo(d('500000')),
      0,
    );

    repo.error = null;
    await controller.reintentar();
    await tester.pump();

    estado = container.read(planMensualProvider);
    expect(estado.errorLote, isNull);
    expect(estado.cambiosPendientes, isEmpty);
    expect(repo.lotes, hasLength(2));
  });

  testWidgets('un lote nunca supera 100 cambios', (
    WidgetTester tester,
  ) async {
    montar(planBase(extraPartidas: 99));
    await cargar();
    final PlanMensualController controller = container.read(
      planMensualProvider.notifier,
    );

    for (int id = 1; id <= 101; id++) {
      controller.moverPartida(id, d('1200'));
    }
    await controller.soltar();
    await tester.pump();
    await tester.pump();

    expect(repo.lotes.first, hasLength(100));
    expect(repo.lotes[1], hasLength(1));
  });
}
