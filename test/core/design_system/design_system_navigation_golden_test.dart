import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';

import '../../support/load_app_fonts.dart';

class _NavigationBoard extends StatelessWidget {
  const _NavigationBoard();

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return Container(
      width: 360,
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: colors.canvas,
      child: NeoBottomNav(
        destinations: const <NeoBottomDestination>[
          NeoBottomDestination(
            label: 'Inicio',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
          ),
          NeoBottomDestination(
            label: 'Deudas',
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet,
          ),
          NeoBottomDestination(
            label: 'Plan',
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
          ),
          NeoBottomDestination(
            label: 'Presupuesto',
            icon: Icons.pie_chart_outline,
            selectedIcon: Icons.pie_chart,
          ),
          NeoBottomDestination(
            label: 'Más',
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view,
          ),
        ],
        selectedIndex: 1,
        onSelected: (_) {},
      ),
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('golden de navegación en claro y oscuro', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: SaveUpTheme.light(),
        home: const Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: ValueKey<String>('navigation'),
              child: _NavigationBoard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey<String>('navigation')),
      matchesGoldenFile('goldens/neo_navigation_light.png'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: SaveUpTheme.dark(),
        home: const Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: ValueKey<String>('navigation'),
              child: _NavigationBoard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey<String>('navigation')),
      matchesGoldenFile('goldens/neo_navigation_dark.png'),
    );
  });
}
