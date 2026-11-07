import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';

import '../../support/load_app_fonts.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? SaveUpTheme.light(),
    home: Scaffold(
      body: Center(
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('NeoMoneyText formatea Decimal, signo y tono', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeoMoneyText(
              amount: Decimal.fromInt(25000),
              signed: true,
            ),
            NeoMoneyText(
              amount: Decimal.fromInt(-25000),
              tone: NeoMoneyTone.expense,
            ),
          ],
        ),
      ),
    );

    expect(find.text(r'+$25.000'), findsOneWidget);
    expect(find.text(r'-$25.000'), findsOneWidget);
    final Text expense = tester.widget(find.text(r'-$25.000'));
    expect(expense.style!.color, SaveUpColors.light.negativeText);
  });

  testWidgets('NeoStat muestra label, valor y helper', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const NeoStat(
          label: 'Ingresos',
          value: Text('42'),
          helper: 'Este mes',
          icon: Icons.trending_up,
        ),
      ),
    );

    expect(find.text('INGRESOS'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Este mes'), findsOneWidget);
  });

  testWidgets('NeoListItem muestra contenido y responde al tap', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      _wrap(
        NeoListItem(
          leading: const Icon(Icons.shopping_bag_outlined),
          title: 'Supermercado',
          subtitle: 'Alimentación',
          trailing: const Text(r'$25.000'),
          onTap: () => taps += 1,
        ),
      ),
    );

    expect(find.text('Supermercado'), findsOneWidget);
    expect(find.text('Alimentación'), findsOneWidget);
    await tester.tap(find.text('Supermercado'));
    expect(taps, 1);
  });

  testWidgets('NeoSectionHeader, EmptyState y ErrorState', (
    WidgetTester tester,
  ) async {
    int retries = 0;
    await tester.pumpWidget(
      _wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const NeoSectionHeader(
              title: 'Movimientos',
              subtitle: 'Últimos',
              action: Text('Ver todo'),
            ),
            NeoEmptyState(
              title: 'Sin datos',
              message: 'No hay movimientos.',
              action: NeoButton(
                label: 'Actualizar',
                onPressed: () {},
              ),
            ),
            NeoErrorState(
              message: 'Error de red.',
              onRetry: () => retries += 1,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Sin datos'), findsOneWidget);
    expect(find.text('Error de red.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });

  testWidgets('NeoLoading muestra mensaje y filas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const NeoLoading(rows: 2)));

    expect(find.text('Cargando…'), findsOneWidget);
    expect(find.byType(NeoSurface), findsNWidgets(2));
  });

  testWidgets('NeoConfirmDialog devuelve true y destructive', (
    WidgetTester tester,
  ) async {
    bool? resultado;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (BuildContext context) => NeoButton(
            label: 'Abrir',
            onPressed: () async {
              resultado = await NeoConfirmDialog.show(
                context,
                title: '¿Eliminar meta?',
                message: 'Esta acción no se puede deshacer.',
                confirmLabel: 'Eliminar',
                destructive: true,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar meta?'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(resultado, isTrue);
  });

  testWidgets('NeoSnackbar muestra mensaje y acción', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (BuildContext context) => NeoButton(
            label: 'Mostrar',
            onPressed: () => NeoSnackbar.show(
              context,
              'Guardado.',
              tone: NeoSnackbarTone.success,
              actionLabel: 'OK',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostrar'));
    await tester.pump();
    expect(find.text('Guardado.'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('NeoMonthPicker dispara anterior/siguiente', (
    WidgetTester tester,
  ) async {
    int previous = 0;
    int next = 0;
    await tester.pumpWidget(
      _wrap(
        NeoMonthPicker(
          label: '2026-11',
          onPrevious: () => previous += 1,
          onNext: () => next += 1,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.tap(find.byTooltip('Mes siguiente'));
    expect(previous, 1);
    expect(next, 1);
  });

  testWidgets('NeoChartCard muestra título, leyenda y estado vacío', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const NeoChartCard(
          title: 'Gastos',
          subtitle: 'Últimos 6 meses',
          legend: NeoBadge(label: 'Mensual'),
          isEmpty: true,
          child: SizedBox(height: 40),
        ),
      ),
    );

    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Últimos 6 meses'), findsOneWidget);
    expect(find.text('Sin datos'), findsOneWidget);
  });
}
