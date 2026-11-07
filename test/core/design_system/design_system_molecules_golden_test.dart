import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';

import '../../support/load_app_fonts.dart';

class _MoleculesBoard extends StatelessWidget {
  const _MoleculesBoard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return Container(
      width: 360,
      padding: const EdgeInsets.all(20),
      color: colors.canvas,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Moléculas', style: theme.textTheme.displaySmall),
          const SizedBox(height: AppSpacing.sm),
          const NeoSectionHeader(
            title: 'Resumen',
            subtitle: 'Noviembre',
            action: Text('Ver todo'),
          ),
          const SizedBox(height: AppSpacing.sm),
          NeoStat(
            label: 'Ingresos',
            icon: Icons.trending_up,
            value: NeoMoneyText(
              amount: Decimal.fromInt(1234567),
              size: NeoMoneySize.headline,
              tone: NeoMoneyTone.income,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          NeoListItem(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: 'Supermercado',
            subtitle: 'Alimentación · Hoy',
            trailing: NeoMoneyText(
              amount: Decimal.fromInt(-25000),
              tone: NeoMoneyTone.expense,
            ),
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          NeoChartCard(
            title: 'Gastos por mes',
            subtitle: 'Últimos 6 meses',
            legend: const Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                NeoBadge(label: 'Gastos', color: AppColors.orange),
                NeoBadge(label: 'Ahorro', color: AppColors.green),
              ],
            ),
            child: SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (int i = 0; i < 6; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          height: 30.0 + i * 10,
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? AppColors.orange
                                : AppColors.green,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadii.sm),
                            ),
                            border: Border.all(
                              color: colors.border,
                              width: AppBorders.regular,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('golden de moléculas en claro y oscuro', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: SaveUpTheme.light(),
        home: const Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: ValueKey<String>('molecules'),
              child: _MoleculesBoard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey<String>('molecules')),
      matchesGoldenFile('goldens/neo_molecules_light.png'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: SaveUpTheme.dark(),
        home: const Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: ValueKey<String>('molecules'),
              child: _MoleculesBoard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey<String>('molecules')),
      matchesGoldenFile('goldens/neo_molecules_dark.png'),
    );
  });
}
