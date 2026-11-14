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

const List<NeoBottomDestination> _navDestinations = <NeoBottomDestination>[
  NeoBottomDestination(label: 'Inicio', icon: Icons.home_outlined),
  NeoBottomDestination(
    label: 'Deudas',
    icon: Icons.account_balance_wallet_outlined,
  ),
  NeoBottomDestination(label: 'Plan', icon: Icons.calendar_month_outlined),
  NeoBottomDestination(label: 'Presupuesto', icon: Icons.pie_chart_outline),
  NeoBottomDestination(
    label: 'Más',
    icon: Icons.grid_view_outlined,
    dragSelectable: false,
  ),
];

Widget _nav({
  required int selectedIndex,
  required ValueChanged<int> onSelected,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: SaveUpTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: NeoBottomNav(
          destinations: _navDestinations,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('NeoBottomNav muestra destinos y responde a taps', (
    WidgetTester tester,
  ) async {
    final List<int> selected = <int>[];
    await tester.pumpWidget(_nav(selectedIndex: 0, onSelected: selected.add));

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Deudas'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Presupuesto'), findsOneWidget);
    expect(find.text('Más'), findsOneWidget);

    await tester.tap(find.text('Deudas'));
    expect(selected, <int>[1]);
    await tester.tap(find.text('Más'));
    expect(selected, <int>[1, 4]);
  });

  testWidgets('NeoBottomNav desliza el indicador al cambiar selectedIndex', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_nav(selectedIndex: 0, onSelected: (_) {}));
    final Finder indicator = find.byKey(
      const ValueKey<String>('neo-bottom-nav-indicator-circle'),
    );
    final double startX = tester.getCenter(indicator).dx;

    await tester.pumpWidget(_nav(selectedIndex: 1, onSelected: (_) {}));
    await tester.pump(const Duration(milliseconds: 100));
    final double movingX = tester.getCenter(indicator).dx;
    final double endX = tester.getCenter(find.text('Deudas')).dx;
    expect(movingX, greaterThan(startX));
    expect(movingX, lessThan(endX));

    await tester.pumpAndSettle();
    expect(tester.getCenter(indicator).dx, closeTo(endX, 0.1));
  });

  testWidgets('NeoBottomNav arrastra y confirma una sola vez al soltar', (
    WidgetTester tester,
  ) async {
    final List<int> selected = <int>[];
    await tester.pumpWidget(_nav(selectedIndex: 0, onSelected: selected.add));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Inicio')),
    );
    await gesture.moveTo(tester.getCenter(find.text('Plan')));
    await tester.pump();
    expect(selected, isEmpty, reason: 'el arrastre solo previsualiza');

    await gesture.up();
    expect(selected, <int>[2]);
  });

  testWidgets('NeoBottomNav permite iniciar el arrastre en el icono elevado', (
    WidgetTester tester,
  ) async {
    final List<int> selected = <int>[];
    await tester.pumpWidget(_nav(selectedIndex: 0, onSelected: selected.add));
    final Finder indicator = find.byKey(
      const ValueKey<String>('neo-bottom-nav-indicator-circle'),
    );
    final Offset topHalf = tester.getTopLeft(indicator) + const Offset(22, 7);
    final double targetX = tester.getCenter(find.text('Plan')).dx;

    final TestGesture gesture = await tester.startGesture(topHalf);
    await gesture.moveTo(Offset(targetX, topHalf.dy));
    await tester.pump();
    await gesture.up();

    expect(selected, <int>[2]);
  });

  testWidgets('NeoBottomNav cancela el arrastre fuera de la barra', (
    WidgetTester tester,
  ) async {
    final List<int> selected = <int>[];
    await tester.pumpWidget(_nav(selectedIndex: 0, onSelected: selected.add));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Inicio')),
    );
    await gesture.moveTo(tester.getCenter(find.text('Plan')));
    await tester.pump();
    await gesture.moveTo(const Offset(-20, 24));
    await tester.pump();
    await gesture.up();

    expect(selected, isEmpty);
    expect(
      tester
          .getCenter(
            find.byKey(
              const ValueKey<String>('neo-bottom-nav-indicator-circle'),
            ),
          )
          .dx,
      closeTo(tester.getCenter(find.text('Inicio')).dx, 0.1),
    );
  });

  testWidgets('NeoBottomNav excluye Más del arrastre', (
    WidgetTester tester,
  ) async {
    final List<int> selected = <int>[];
    await tester.pumpWidget(_nav(selectedIndex: 0, onSelected: selected.add));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Inicio')),
    );
    await gesture.moveTo(tester.getCenter(find.text('Más')));
    await tester.pump();
    await gesture.up();

    expect(selected, isEmpty);
  });

  testWidgets('NeoBottomNav cancela una preselección ante cambio externo', (
    WidgetTester tester,
  ) async {
    final List<int> selected = <int>[];
    await tester.pumpWidget(_nav(selectedIndex: 0, onSelected: selected.add));
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Inicio')),
    );
    await gesture.moveTo(tester.getCenter(find.text('Plan')));
    await tester.pump();

    await tester.pumpWidget(_nav(selectedIndex: 1, onSelected: selected.add));
    await tester.pumpAndSettle();
    await gesture.up();

    expect(selected, isEmpty);
    expect(
      tester
          .getCenter(
            find.byKey(
              const ValueKey<String>('neo-bottom-nav-indicator-circle'),
            ),
          )
          .dx,
      closeTo(tester.getCenter(find.text('Deudas')).dx, 0.1),
    );
  });

  testWidgets('NeoBottomNav omite la animación si está reducida', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _nav(selectedIndex: 0, onSelected: (_) {}, disableAnimations: true),
    );
    await tester.pumpWidget(
      _nav(selectedIndex: 2, onSelected: (_) {}, disableAnimations: true),
    );
    await tester.pump();

    expect(
      tester
          .getCenter(
            find.byKey(
              const ValueKey<String>('neo-bottom-nav-indicator-circle'),
            ),
          )
          .dx,
      closeTo(tester.getCenter(find.text('Plan')).dx, 0.1),
    );
  });

  testWidgets('NeoBottomNav expone botones y estado seleccionado a Semantics', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(_nav(selectedIndex: 0, onSelected: (_) {}));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Inicio')),
      matchesSemantics(
        label: 'Inicio',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Deudas')),
      matchesSemantics(
        label: 'Deudas',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('NeoBottomNav cabe en móvil estrecho con texto ampliado', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: SaveUpTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: NeoBottomNav(
              destinations: _navDestinations,
              selectedIndex: 3,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Presupuesto'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  testWidgets(
    'NeoMoreMenu muestra opciones, ejecuta y respeta deshabilitadas',
    (WidgetTester tester) async {
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
    },
  );

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
              NeoBottomDestination(
                label: 'Deudas',
                icon: Icons.wallet_outlined,
              ),
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
