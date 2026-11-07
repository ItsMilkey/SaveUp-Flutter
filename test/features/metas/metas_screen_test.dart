import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/features/metas/data/dio_metas_repository.dart';
import 'package:saveup_app/features/metas/domain/meta_ahorro.dart';
import 'package:saveup_app/features/metas/presentation/screens/metas_screen.dart';
import 'package:saveup_app/features/movimientos/presentation/movimientos_controller.dart';

import 'metas_fixtures.dart';

Future<void> montar(
  WidgetTester tester,
  FakeMetasRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        metasRepositoryProvider.overrideWithValue(repo),
        movimientosProvider.overrideWith(FakeMovimientosController.new),
      ],
      child: MaterialApp(
        theme: SaveUpTheme.light(),
        home: const MetasScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista metas con progreso, fecha y acciones', (
    WidgetTester tester,
  ) async {
    await montar(tester, FakeMetasRepository());

    expect(find.text('Viaje a Japón'), findsOneWidget);
    expect(
      find.text(r'$250.000 de $1.500.000 (16.67 %)'),
      findsOneWidget,
    );
    expect(find.text('Fecha límite: 2027-06-30'), findsOneWidget);
    expect(find.text('Abonar'), findsOneWidget);
    expect(find.text('Retirar'), findsOneWidget);
  });

  testWidgets('abonar envía monto/descripción y refresca la tarjeta', (
    WidgetTester tester,
  ) async {
    final FakeMetasRepository repo = FakeMetasRepository();
    await montar(tester, repo);

    await tester.tap(find.text('Abonar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '50000');
    await tester.tap(find.widgetWithText(FilledButton, 'Abonar'));
    await tester.pumpAndSettle();

    expect(repo.abonoId, 3);
    expect(repo.abonoMonto!.toString(), '50000');
    expect(repo.abonoDescripcion, 'Abono a Viaje a Japón');
    expect(find.text('Abono registrado.'), findsOneWidget);
    expect(
      find.text(r'$300.000 de $1.500.000 (20 %)'),
      findsOneWidget,
    );
  });

  testWidgets('retirar más de lo ahorrado se bloquea en el diálogo', (
    WidgetTester tester,
  ) async {
    final FakeMetasRepository repo = FakeMetasRepository();
    await montar(tester, repo);

    await tester.tap(find.text('Retirar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '999999');
    await tester.tap(find.widgetWithText(FilledButton, 'Retirar'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No puedes retirar más de lo ahorrado'),
      findsOneWidget,
    );
    expect(repo.retiroMonto, isNull);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });

  testWidgets('estado vacío invita a crear la primera meta', (
    WidgetTester tester,
  ) async {
    await montar(
      tester,
      FakeMetasRepository(metas: <MetaAhorro>[]),
    );

    expect(find.text('Aún no tienes metas de ahorro.'), findsOneWidget);
    expect(find.text('Crear mi primera meta'), findsOneWidget);
  });

  testWidgets('la meta base no ofrece eliminar', (WidgetTester tester) async {
    await montar(
      tester,
      FakeMetasRepository(metas: <MetaAhorro>[metaPorDefecto()]),
    );

    expect(find.text('Meta base'), findsOneWidget);
    expect(find.text(r'Ahorrado: $50.000'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsNothing);
  });
}
