import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';

import '../../support/load_app_fonts.dart';

class _BoldThemeBoard extends StatelessWidget {
  const _BoldThemeBoard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return Container(
      width: 360,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: colors.canvas,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Bold', style: theme.textTheme.displaySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Papel cálido, tinta y acentos vibrantes.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          NeoSurface(
            density: AppDensity.hero,
            color: colors.surfaceAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Resumen', style: theme.textTheme.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                Text('Tu progreso', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.md),
                NeoProgress(
                  value: 0.72,
                  color: colors.tertiary,
                  trackColor: colors.surface,
                  label: '72 % completado',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              NeoBadge(label: 'Necesidad', color: colors.secondary),
              NeoBadge(label: 'Ahorro', color: colors.primary),
              NeoBadge(label: 'Meta', color: colors.accent),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          NeoButton(
            label: 'Ver resumen',
            icon: Icons.arrow_forward,
            onPressed: () {},
            expanded: true,
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('golden del tema Bold', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: SaveUpTheme.bold(),
        home: const Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: ValueKey<String>('bold-theme'),
              child: _BoldThemeBoard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey<String>('bold-theme')),
      matchesGoldenFile('goldens/neo_bold_theme.png'),
    );
  });
}
