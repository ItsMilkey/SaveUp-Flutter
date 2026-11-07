import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';

import '../../support/load_app_fonts.dart';

class _AtomsBoard extends StatelessWidget {
  const _AtomsBoard();

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
          Text('SaveUp', style: theme.textTheme.displaySmall),
          const SizedBox(height: 4),
          Text('Design system · átomos', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          NeoCard(
            density: AppDensity.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Saldo disponible', style: theme.textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(r'$1.234.567', style: theme.textTheme.displaySmall),
                const SizedBox(height: AppSpacing.sm),
                const NeoBadge(
                  label: 'Ahorro 20 %',
                  color: AppColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: NeoButton(
                  label: 'Abonar',
                  icon: Icons.add,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: NeoButton(
                  label: 'Retirar',
                  variant: NeoButtonVariant.secondary,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const NeoProgress(value: 0.72, label: 'Meta · 72 %'),
          const SizedBox(height: AppSpacing.md),
          NeoCard(
            density: AppDensity.list,
            child: Row(
              children: <Widget>[
                const NeoBadge(label: 'Necesidad'),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Supermercado',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(r'-$25.000', style: theme.textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('golden de átomos en claro y oscuro', (
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
              key: ValueKey<String>('atoms'),
              child: _AtomsBoard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey<String>('atoms')),
      matchesGoldenFile('goldens/neo_atoms_light.png'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: SaveUpTheme.dark(),
        home: const Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: ValueKey<String>('atoms'),
              child: _AtomsBoard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey<String>('atoms')),
      matchesGoldenFile('goldens/neo_atoms_dark.png'),
    );
  });
}
