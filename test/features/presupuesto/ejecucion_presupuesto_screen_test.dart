import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/presupuesto/data/dio_presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/ejecucion_presupuesto.dart';
import 'package:saveup_app/features/presupuesto/presentation/screens/ejecucion_presupuesto_screen.dart';

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
        home: const EjecucionPresupuestoScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra bloques, ingresos e historial', (
    WidgetTester tester,
  ) async {
    final FakePresupuestoRepository repo = FakePresupuestoRepository(
      historial: <HistorialPresupuesto>[
        historialDePrueba(anio: 2026, mes: 10),
        historialDePrueba(anio: 2026, mes: 9),
      ],
    );
    await montar(tester, repo);

    expect(find.text('Ingresos del mes'), findsOneWidget);
    expect(find.text(r'$1.000.000'), findsOneWidget);
    expect(find.text('Necesidades'), findsOneWidget);
    expect(find.text('Deseos'), findsOneWidget);
    expect(find.text('Ahorro'), findsOneWidget);
    expect(
      find.text(r'$400.000 de $500.000 (plan 50 %)'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Historial'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('oct 2026'), findsOneWidget);
    expect(find.text('sep 2026'), findsOneWidget);
  });

  testWidgets('el control de mes pide el mes anterior', (
    WidgetTester tester,
  ) async {
    final FakePresupuestoRepository repo = FakePresupuestoRepository();
    await montar(tester, repo);

    final int mesInicial = repo.monthSolicitado!;
    final int anioInicial = repo.yearSolicitado!;
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    final DateTime esperado = DateTime(anioInicial, mesInicial - 1);
    expect(repo.monthSolicitado, esperado.month);
    expect(repo.yearSolicitado, esperado.year);
  });

  testWidgets('muestra el error y permite reintentar', (
    WidgetTester tester,
  ) async {
    final FakePresupuestoRepository repo = FakePresupuestoRepository(
      errorEjecucion: const NetworkFailure(),
    );
    await montar(tester, repo);

    expect(
      find.textContaining('Sin conexión'),
      findsOneWidget,
    );

    repo.errorEjecucion = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresos del mes'), findsOneWidget);
  });
}
