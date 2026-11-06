import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/features/presupuesto/data/dio_plan_mensual_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_mensual.dart';
import 'package:saveup_app/features/presupuesto/presentation/controllers/plan_mensual_controller.dart';
import 'package:saveup_app/features/presupuesto/presentation/widgets/partida_monto_slider.dart';

import 'plan_fixtures.dart';

void main() {
  testWidgets('el drag recalcula en el frame y el PATCH sale solo al soltar', (
    WidgetTester tester,
  ) async {
    final PlanMensual plan = planDePrueba(
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
      ],
    );
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: plan,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [planMensualRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(planMensualProvider.notifier).cargar('2026-11');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                const PartidaMontoSlider(partidaId: 1),
                Consumer(
                  builder: (BuildContext context, WidgetRef ref, _) {
                    final PlanMensualState estado = ref.watch(
                      planMensualProvider,
                    );
                    return Text(
                      'total ${estado.plan!.calculo.resumen.planificadoTotal}',
                      key: const ValueKey<String>('total'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    String total() => tester
        .widget<Text>(find.byKey(const ValueKey<String>('total')))
        .data!;
    final String totalInicial = total();
    expect(find.byType(Slider), findsOneWidget);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(Slider)),
    );
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();

    // Recalculó en el mismo frame y todavía no hay HTTP.
    expect(total(), isNot(totalInicial));
    expect(repo.lotes, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(repo.lotes, hasLength(1));
    expect(repo.lotes.single.single.partidaId, 1);
    expect(repo.lotes.single.single.monto, isNot(d('400000')));
  });

  testWidgets('partida vinculada a deuda no ofrece slider', (
    WidgetTester tester,
  ) async {
    final PlanMensual plan = planDePrueba(
      ingresoReferencia: d('1000000'),
      partidas: <PartidaSpec>[
        PartidaSpec(
          id: 20,
          nombre: 'Cuota crédito',
          categoriaId: 9,
          codigo: 'DEUDAS',
          tipo: TipoPresupuesto.necesidad,
          monto: d('43500'),
          deudaId: 77,
        ),
      ],
    );
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: plan,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [planMensualRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(planMensualProvider.notifier).cargar('2026-11');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PartidaMontoSlider(partidaId: 20),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Slider), findsNothing);
    expect(
      find.text('El monto lo define la cuota de la deuda.'),
      findsOneWidget,
    );
    expect(find.textContaining('Cuota pendiente'), findsOneWidget);
  });
}
