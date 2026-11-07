import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';

import '../../support/load_app_fonts.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: SaveUpTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('NeoBottomNav muestra destinos y notifica selección', (
    WidgetTester tester,
  ) async {
    int selected = -1;
    await tester.pumpWidget(
      _wrap(
        NeoBottomNav(
          destinations: const <NeoBottomDestination>[
            NeoBottomDestination(label: 'Inicio', icon: Icons.home_outlined),
            NeoBottomDestination(
              label: 'Deudas',
              icon: Icons.account_balance_wallet_outlined,
            ),
            NeoBottomDestination(
              label: 'Plan',
              icon: Icons.calendar_month_outlined,
            ),
            NeoBottomDestination(
              label: 'Presupuesto',
              icon: Icons.pie_chart_outline,
            ),
            NeoBottomDestination(
              label: 'Más',
              icon: Icons.grid_view_outlined,
            ),
          ],
          selectedIndex: 0,
          onSelected: (int index) => selected = index,
        ),
      ),
    );

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Deudas'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Presupuesto'), findsOneWidget);
    expect(find.text('Más'), findsOneWidget);

    await tester.tap(find.text('Deudas'));
    expect(selected, 1);
    await tester.tap(find.text('Más'));
    expect(selected, 4);
  });

  testWidgets('NeoAppBar muestra título y acciones', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SaveUpTheme.light(),
        home: Scaffold(
          appBar: NeoAppBar(
            title: 'Título',
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: const Text('Body'),
        ),
      ),
    );

    expect(find.text('Título'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('NeoMoreMenu muestra opciones, ejecuta y respeta deshabilitadas', (
    WidgetTester tester,
  ) async {
    int metas = 0;
    int analitica = 0;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (BuildContext context) => NeoButton(
            label: 'Abrir',
            onPressed: () => NeoMoreMenu.show(
              context,
              options: <NeoMoreOption>[
                NeoMoreOption(
                  label: 'Metas',
                  icon: Icons.savings_outlined,
                  onTap: () => metas += 1,
                ),
                NeoMoreOption(
                  label: 'Analítica',
                  icon: Icons.insights_outlined,
                  badge: const NeoBadge(label: 'Pronto'),
                  onTap: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Metas'), findsOneWidget);
    expect(find.text('Analítica'), findsOneWidget);
    expect(find.text('Pronto'), findsOneWidget);

    await tester.tap(find.text('Analítica'));
    await tester.pumpAndSettle();
    expect(analitica, 0);

    await tester.tap(find.text('Metas'));
    await tester.pumpAndSettle();
    expect(metas, 1);
    expect(find.text('Metas'), findsNothing);
  });

  testWidgets('NeoScaffold integra app bar, body y navegación', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SaveUpTheme.light(),
        home: NeoScaffold(
          appBar: const NeoAppBar(title: 'Inicio'),
          body: const Text('Contenido'),
          bottomNavigationBar: NeoBottomNav(
            destinations: const <NeoBottomDestination>[
              NeoBottomDestination(label: 'Inicio', icon: Icons.home_outlined),
              NeoBottomDestination(label: 'Deudas', icon: Icons.wallet_outlined),
            ],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Contenido'), findsOneWidget);
    expect(find.text('Deudas'), findsOneWidget);
  });
}
