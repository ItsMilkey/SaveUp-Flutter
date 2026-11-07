import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/presupuesto/data/dio_presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/presentation/screens/configuracion_regla_screen.dart';

import 'presupuesto_fixtures.dart';

Future<void> montar(
  WidgetTester tester,
  FakePresupuestoRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [presupuestoRepositoryProvider.overrideWithValue(repo)],
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
}
