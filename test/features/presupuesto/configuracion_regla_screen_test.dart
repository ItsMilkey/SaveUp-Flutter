import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/metas/data/dio_metas_repository.dart';
import 'package:saveup_app/features/metas/domain/meta_ahorro.dart';
import 'package:saveup_app/features/presupuesto/data/dio_presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/asignacion_presupuesto.dart';
import 'package:saveup_app/features/presupuesto/presentation/screens/configuracion_regla_screen.dart';

import '../metas/metas_fixtures.dart';
import 'presupuesto_fixtures.dart';

Future<void> montar(
  WidgetTester tester,
  FakePresupuestoRepository repo, {
  FakeMetasRepository? metas,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presupuestoRepositoryProvider.overrideWithValue(repo),
        metasRepositoryProvider.overrideWithValue(
          metas ?? FakeMetasRepository(),
        ),
      ],
      child: MaterialApp(
        theme: SaveUpTheme.light(),
        home: const ConfiguracionReglaScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra la regla, aplica la sugerencia y guarda', (
    WidgetTester tester,
  ) async {
    final FakePresupuestoRepository repo = FakePresupuestoRepository(
      config: configuracion(),
      sugerencia: sugerenciaDePrueba(propuesta: porcentajes(necesidades: '55', deseos: '25'),
      ),
    );
    await montar(tester, repo);

    expect(find.text('Regla mensual'), findsOneWidget);
    expect(find.textContaining('Suma:'), findsOneWidget);
    expect(find.textContaining('Sugerencia para ti'), findsOneWidget);

    await tester.tap(find.text('Aplicar sugerencia'));
    await tester.pumpAndSettle();
    expect(find.text('55 %'), findsOneWidget);
    expect(find.text('25 %'), findsOneWidget);

    // Mover necesidades: la suma sigue exacta y se guarda balanceada.
    await tester.scrollUntilVisible(
      find.byType(Slider).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Slider).first, const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Suma: 100'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Guardar regla'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar regla'));
    await tester.pumpAndSettle();

    expect(repo.guardados, isNotNull);
    expect(repo.guardados!.sumaValida, isTrue);
    expect(find.text('Regla guardada.'), findsOneWidget);
  });

  testWidgets('el porcentaje se puede editar con precisión', (
    WidgetTester tester,
  ) async {
    final FakePresupuestoRepository repo = FakePresupuestoRepository(
      config: configuracion(),
    );
    await montar(tester, repo);

    await tester.tap(find.text('50 %'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Necesidades'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Porcentaje'),
      '60,25',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('60.25 %'), findsOneWidget);
    expect(find.textContaining('Suma: 100'), findsOneWidget);
    expect(find.text('Editar Necesidades'), findsNothing);
  });

  testWidgets('los iconos de información explican los switches', (
    WidgetTester tester,
  ) async {
    final FakePresupuestoRepository repo = FakePresupuestoRepository(
      config: configuracion(),
    );
    await montar(tester, repo);

    await tester.scrollUntilVisible(
      find.text('Presupuesto activo'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip('Información sobre Presupuesto activo'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('interruptor maestro'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byTooltip('Información sobre Automatizar ahorro en metas'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('porcentaje de Ahorro'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
  });

  testWidgets('sin historial suficiente explica que no hay sugerencia', (
    WidgetTester tester,
  ) async {
    final FakePresupuestoRepository repo = FakePresupuestoRepository(
      config: configuracion(),
      sugerencia: sugerenciaDePrueba(motivo: 'DATOS_INSUFICIENTES'),
    );
    await montar(tester, repo);

    expect(find.textContaining('suficientes meses'), findsOneWidget);
    expect(find.text('Aplicar sugerencia'), findsNothing);
  });

  testWidgets('muestra el detail cuando el backend rechaza la regla', (
    WidgetTester tester,
  ) async {
    final FakePresupuestoRepository repo = FakePresupuestoRepository(
      config: configuracion(),
      errorGuardar: const BadRequestFailure(
        codigo: 'DATOS_INVALIDOS',
        detail: 'Los porcentajes deben sumar 100.00.',
      ),
    );
    await montar(tester, repo);

    await tester.scrollUntilVisible(
      find.text('Guardar regla'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar regla'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Los porcentajes deben sumar 100.00.'),
      findsOneWidget,
    );
  });

  testWidgets('carga y guarda la distribución del ahorro', (
    WidgetTester tester,
  ) async {
    final FakeMetasRepository metas = FakeMetasRepository(
      metas: <MetaAhorro>[
        metaDePrueba(id: 3, nombre: 'Viaje'),
        metaDePrueba(id: 4, nombre: 'Notebook', objetivo: '800000'),
      ],
    );
    final FakePresupuestoRepository repo = FakePresupuestoRepository(
      config: configuracion(),
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
    await montar(tester, repo, metas: metas);

    await tester.scrollUntilVisible(
      find.text('Distribución del ahorro'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Distribución del ahorro'), findsOneWidget);
    expect(find.text('60.00 %'), findsOneWidget);
    expect(find.text('40.00 %'), findsOneWidget);
    expect(find.textContaining('Total: 100.00'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Guardar regla'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar regla'));
    await tester.pumpAndSettle();

    expect(repo.asignacionesGuardadas, isNotNull);
    expect(repo.asignacionesGuardadas, hasLength(2));
    expect(
      repo.asignacionesGuardadas!
          .map((AsignacionPresupuestoDatos a) => a.porcentaje)
          .fold(Decimal.zero, (Decimal a, Decimal b) => a + b),
      Decimal.parse('100'),
    );
  });

  testWidgets('agrega una meta y limpia la distribución', (
    WidgetTester tester,
  ) async {
    final FakeMetasRepository metas = FakeMetasRepository(
      metas: <MetaAhorro>[metaDePrueba(id: 3, nombre: 'Viaje')],
    );
    final FakePresupuestoRepository repo = FakePresupuestoRepository(
      config: configuracion(),
    );
    await montar(tester, repo, metas: metas);

    await tester.scrollUntilVisible(
      find.text('Distribución del ahorro'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Sin distribución: el ahorro queda en la meta base.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Agregar meta'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Agregar meta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Viaje'));
    await tester.pumpAndSettle();

    expect(find.text('100.00 %'), findsOneWidget);
    expect(find.textContaining('Total: 100.00'), findsOneWidget);

    await tester.tap(find.text('Limpiar distribución'));
    await tester.pumpAndSettle();
    expect(
      find.text('Sin distribución: el ahorro queda en la meta base.'),
      findsOneWidget,
    );
  });
}
