import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/analitica/presentation/screens/analitica_screen.dart';
import 'package:saveup_app/features/movimientos/data/dio_categorias_repository.dart';
import 'package:saveup_app/features/presupuesto/data/dio_plan_mensual_repository.dart';
import 'package:saveup_app/features/presupuesto/data/dio_presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_mensual.dart';

import '../presupuesto/plan_fixtures.dart';
import '../presupuesto/presupuesto_fixtures.dart';

void main() {
  Future<void> montar(
    WidgetTester tester, {
    required FakePlanMensualRepository plan,
    FakePresupuestoRepository? presupuesto,
    FakeCategoriasRepository? categorias,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planMensualRepositoryProvider.overrideWithValue(plan),
          presupuestoRepositoryProvider.overrideWithValue(
            presupuesto ?? FakePresupuestoRepository(),
          ),
          categoriasRepositoryProvider.overrideWithValue(
            categorias ?? FakeCategoriasRepository(),
          ),
        ],
        child: MaterialApp(
          theme: theme ?? SaveUpTheme.light(),
          home: const AnaliticaScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin movimientos muestra el estado vacío y cambia de mes', (
    WidgetTester tester,
  ) async {
    final FakePlanMensualRepository plan = FakePlanMensualRepository(
      plan: planDePrueba(ingresoReferencia: d('1000000')),
    );

    await montar(tester, plan: plan);

    expect(find.text('Sin movimientos'), findsOneWidget);
    expect(find.text('2026-11'), findsOneWidget);

    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();

    expect(plan.consultas, contains('2026-12'));
  });

  testWidgets('el tema oscuro monta sin excepciones', (
    WidgetTester tester,
  ) async {
    await montar(
      tester,
      plan: FakePlanMensualRepository(
        plan: planDePrueba(ingresoReferencia: d('1000000')),
      ),
      theme: SaveUpTheme.dark(),
    );

    expect(find.text('Sin movimientos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la falla del plan muestra reintento', (
    WidgetTester tester,
  ) async {    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planMensualRepositoryProvider.overrideWith(
            (Ref ref) => _PlanQueFalla(),
          ),
          presupuestoRepositoryProvider.overrideWithValue(
            FakePresupuestoRepository(),
          ),
          categoriasRepositoryProvider.overrideWithValue(
            FakeCategoriasRepository(),
          ),
        ],
        child: MaterialApp(
          theme: SaveUpTheme.light(),
          home: const AnaliticaScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsOneWidget);
  });
}

class _PlanQueFalla implements PlanMensualRepository {
  @override
  Future<PlanMensual> obtener(
    String mes, {
    bool incluirReferencias = false,
  }) async {
    throw const ServerFailure();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
