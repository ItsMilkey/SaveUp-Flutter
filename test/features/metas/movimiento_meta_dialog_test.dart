import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/features/metas/presentation/widgets/movimiento_meta_dialog.dart';

import 'metas_fixtures.dart';

Widget _anfitrion(
  ModoMovimientoMeta modo, {
  void Function(Future<MovimientoMetaValor?> resultado)? alAbrir,
}) {
  return MaterialApp(
    theme: SaveUpTheme.light(),
    home: Scaffold(
      body: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () {
            final Future<MovimientoMetaValor?> resultado =
                MovimientoMetaDialog.show(
                  context,
                  meta: metaDePrueba(),
                  modo: modo,
                );
            alAbrir?.call(resultado);
          },
          child: const Text('Abrir'),
        ),
      ),
    ),
  );
}

Future<void> _abrir(
  WidgetTester tester,
  ModoMovimientoMeta modo, {
  void Function(Future<MovimientoMetaValor?> resultado)? alAbrir,
}) async {
  await tester.pumpWidget(_anfitrion(modo, alAbrir: alAbrir));
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('acepta el máximo serializable en un abono', (
    WidgetTester tester,
  ) async {
    Future<MovimientoMetaValor?>? resultado;
    await _abrir(
      tester,
      ModoMovimientoMeta.abono,
      alAbrir: (Future<MovimientoMetaValor?> value) => resultado = value,
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      '9999999999999,99',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Abonar'));
    await tester.pumpAndSettle();

    expect((await resultado)!.monto.toString(), '9999999999999.99');
  });

  for (final ModoMovimientoMeta modo in ModoMovimientoMeta.values) {
    testWidgets('${modo.name} rechaza montos sobre el máximo serializable', (
      WidgetTester tester,
    ) async {
      final String accion = modo == ModoMovimientoMeta.abono
          ? 'Abonar'
          : 'Retirar';
      await _abrir(tester, modo);

      await tester.enterText(
        find.byType(TextFormField).first,
        '10000000000000',
      );
      await tester.tap(find.widgetWithText(FilledButton, accion));
      await tester.pumpAndSettle();

      expect(
        find.text('El monto excede el máximo (13 enteros + 2 decimales).'),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);
    });
  }

  testWidgets('rechaza montos con más de dos decimales', (
    WidgetTester tester,
  ) async {
    await _abrir(tester, ModoMovimientoMeta.abono);
    tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text =
        '1,234';

    await tester.tap(find.widgetWithText(FilledButton, 'Abonar'));
    await tester.pumpAndSettle();

    expect(
      find.text('El monto no puede tener más de 2 decimales.'),
      findsOneWidget,
    );
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('mantiene la validación positiva del monto del movimiento', (
    WidgetTester tester,
  ) async {
    await _abrir(tester, ModoMovimientoMeta.abono);
    await tester.enterText(find.byType(TextFormField).first, '0');

    await tester.tap(find.widgetWithText(FilledButton, 'Abonar'));
    await tester.pumpAndSettle();

    expect(find.text('El monto debe ser mayor a 0.'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
