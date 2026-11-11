import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/core/time/business_month.dart';
import 'package:saveup_app/features/movimientos/data/dio_movimientos_repository.dart';
import 'package:saveup_app/features/movimientos/domain/movimiento.dart';
import 'package:saveup_app/features/movimientos/domain/movimiento_filtro.dart';
import 'package:saveup_app/features/movimientos/domain/movimiento_tipo.dart';
import 'package:saveup_app/features/movimientos/domain/movimientos_repository.dart';
import 'package:saveup_app/features/presupuesto/data/dio_plan_mensual_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_mensual.dart';
import 'package:saveup_app/features/presupuesto/presentation/controllers/plan_mensual_controller.dart';
import 'package:saveup_app/features/presupuesto/presentation/widgets/partida_monto_slider.dart';

import 'plan_fixtures.dart';

class FakeMovimientosRepository implements MovimientosRepository {
  final List<
    ({
      int? partidaId,
      Decimal monto,
      String descripcion,
      MovimientoTipo tipo,
    })
  >
  registros =
      <
        ({
          int? partidaId,
          Decimal monto,
          String descripcion,
          MovimientoTipo tipo,
        })
      >[];

  @override
  Future<void> registrar({
    required Decimal monto,
    required String descripcion,
    required MovimientoTipo tipo,
    int? categoriaId,
    int? partidaId,
  }) async {
    registros.add((
      partidaId: partidaId,
      monto: monto,
      descripcion: descripcion,
      tipo: tipo,
    ));
  }

  @override
  Future<PaginaMovimientos> pagina({
    required MovimientoFiltro filtro,
    required int page,
    int size = 50,
  }) async {
    return const PaginaMovimientos(
      content: <Movimiento>[],
      currentPage: 0,
      totalItems: 0,
      totalPages: 0,
    );
  }

  @override
  Future<Movimiento> editar({
    required int id,
    Decimal? monto,
    String? descripcion,
    int? categoriaId,
    int? partidaId,
    bool desvincularPartida = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> eliminar(int id) async {}
}

String mesActual() => BusinessMonth.fromInstant(DateTime.now()).toString();

PlanMensual planConReal(PlanMensual base, int partidaId, Decimal real) {
  return PlanMensual(
    mes: base.mes,
    existe: base.existe,
    ingresoReferencia: base.ingresoReferencia,
    calculo: base.calculo,
    partidas: <PartidaPlan>[
      for (final PartidaPlan partida in base.partidas)
        if (partida.id == partidaId)
          partida.copyWith(
            real: real,
            diferencia: partida.montoPlanificado - real,
            estado: EstadoEjecucion.desde(real, partida.montoPlanificado),
          )
        else
          partida,
    ],
    grupos: base.grupos,
    avisos: base.avisos,
  );
}

PlanMensual planNetflix({String? mes}) {
  return planDePrueba(
    mes: mes ?? mesActual(),
    ingresoReferencia: d('100000'),
    partidas: <PartidaSpec>[
      PartidaSpec(
        id: 1,
        nombre: 'Netflix',
        categoriaId: 8,
        codigo: 'SUSCRIPCIONES_DIGITAL',
        tipo: TipoPresupuesto.deseo,
        monto: d('7200'),
      ),
    ],
  );
}

Future<void> montar(
  WidgetTester tester, {
  required PlanMensual plan,
  required FakePlanMensualRepository repo,
  FakeMovimientosRepository? movimientos,
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      planMensualRepositoryProvider.overrideWithValue(repo),
      if (movimientos != null)
        movimientosRepositoryProvider.overrideWithValue(movimientos),
    ],
  );
  addTearDown(container.dispose);
  await container.read(planMensualProvider.notifier).cargar(plan.mes);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: SaveUpTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: PartidaMontoSlider(partidaId: 1),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

String montoDelDialogo(WidgetTester tester) {
  return tester
      .widget<TextFormField>(find.widgetWithText(TextFormField, 'Monto'))
      .controller!
      .text;
}

void main() {
  testWidgets('Pagar registra el gasto con partidaId y recarga el plan', (
    WidgetTester tester,
  ) async {
    final PlanMensual plan = planNetflix();
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: plan,
    );
    final FakeMovimientosRepository movimientos = FakeMovimientosRepository();
    await montar(
      tester,
      plan: plan,
      repo: repo,
      movimientos: movimientos,
    );

    expect(find.text('Pagar'), findsOneWidget);
    await tester.tap(find.text('Pagar'));
    await tester.pumpAndSettle();

    expect(find.text('Pagar Netflix'), findsOneWidget);
    expect(montoDelDialogo(tester), '7.200');

    await tester.tap(
      find.descendant(
        of: find.byType(NeoDialog),
        matching: find.text('Pagar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(movimientos.registros, hasLength(1));
    final ({
      int? partidaId,
      Decimal monto,
      String descripcion,
      MovimientoTipo tipo,
    })
    registro = movimientos.registros.single;
    expect(registro.partidaId, 1);
    expect(registro.monto, d('7200'));
    expect(registro.descripcion, 'Netflix');
    expect(registro.tipo, MovimientoTipo.gastoGeneral);
    // Carga inicial + recarga tras el POST.
    expect(repo.consultas, hasLength(2));
  });

  testWidgets('una partida cubierta muestra Pagado y congela el slider', (
    WidgetTester tester,
  ) async {
    final PlanMensual plan = planConReal(planNetflix(), 1, d('7200'));
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: plan,
    );
    await montar(tester, plan: plan, repo: repo);

    expect(find.text('Pagado'), findsNWidgets(2)); // badge + cartel
    expect(find.widgetWithText(NeoButton, 'Pagar'), findsNothing);
    expect(find.text(r'Usado $7.200 de $7.200'), findsOneWidget);
    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
  });

  testWidgets('un pago parcial mantiene Pagar y muestra lo usado', (
    WidgetTester tester,
  ) async {
    final PlanMensual plan = planConReal(planNetflix(), 1, d('3000'));
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: plan,
    );
    await montar(tester, plan: plan, repo: repo);

    expect(find.text(r'Usado $3.000 de $7.200'), findsOneWidget);
    expect(find.widgetWithText(NeoButton, 'Pagar'), findsOneWidget);
    expect(find.text('Pagado'), findsNothing);
    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNotNull);
  });

  testWidgets('en otro mes no se ofrece pagar', (WidgetTester tester) async {
    final BusinessMonth actual = BusinessMonth.fromInstant(DateTime.now());
    final BusinessMonth anterior = BusinessMonth(
      actual.month == 1 ? actual.year - 1 : actual.year,
      actual.month == 1 ? 12 : actual.month - 1,
    );
    final PlanMensual plan = planNetflix(mes: anterior.toString());
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: plan,
    );
    await montar(tester, plan: plan, repo: repo);

    expect(find.text('Pagar'), findsNothing);
    expect(
      find.text('Solo puedes registrar pagos del mes en curso.'),
      findsOneWidget,
    );
    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNotNull);
  });
}
