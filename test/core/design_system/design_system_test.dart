import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';

import '../../support/load_app_fonts.dart';

Widget _wrap(Widget child, {ThemeData? theme, TextScaler? textScaler}) {
  return MaterialApp(
    theme: theme ?? SaveUpTheme.light(),
    home: Scaffold(
      body: Center(
        child: MediaQuery(
          data: MediaQueryData(textScaler: textScaler ?? TextScaler.noScaling),
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  test('el tema claro y oscuro exponen tokens y sombras duras', () {
    final ThemeData light = SaveUpTheme.light();
    expect(light.colorScheme.primary, AppColors.yellow);
    expect(light.colorScheme.onPrimary, AppColors.ink);
    expect(light.scaffoldBackgroundColor, AppColors.canvas);
    expect(light.extension<SaveUpColors>(), isNotNull);
    expect(light.extension<SaveUpShadows>(), isNotNull);
    expect(light.extension<SaveUpShadows>()!.md.single.blurRadius, 0);
    expect(light.textTheme.bodyMedium!.fontFamily, AppTypography.bodyFamily);
    expect(light.textTheme.displaySmall!.fontFamily, AppTypography.displayFamily);

    final ThemeData dark = SaveUpTheme.dark();
    expect(dark.scaffoldBackgroundColor, AppColors.darkCanvas);
    expect(dark.colorScheme.primary, AppColors.yellow);
    expect(dark.textTheme.bodyMedium!.color, AppColors.darkText);
  });

  testWidgets('NeoButton ejecuta, se deshabilita y muestra loading', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      _wrap(
        NeoButton(
          label: 'Guardar',
          onPressed: () => taps += 1,
        ),
      ),
    );
    await tester.tap(find.text('Guardar'));
    expect(taps, 1);

    await tester.pumpWidget(
      _wrap(const NeoButton(label: 'Deshabilitado', onPressed: null)),
    );
    await tester.tap(find.text('Deshabilitado'));
    expect(taps, 1);

    await tester.pumpWidget(
      _wrap(
        const NeoButton(
          label: 'Cargando',
          loading: true,
          onPressed: null,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('NeoInput muestra label, helper y error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const NeoInput(
          label: 'Monto',
          hint: '0',
          helper: 'MÃ¡ximo 2 decimales.',
          error: 'Monto invÃ¡lido.',
        ),
      ),
    );

    expect(find.text('Monto'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Monto invÃ¡lido.'), findsOneWidget);
  });

  testWidgets('NeoInput admite icono sufijo y error multilÃ­nea', (
    WidgetTester tester,
  ) async {
    bool suffixTapped = false;
    await tester.pumpWidget(
      _wrap(
        NeoInput(
          label: 'ContraseÃ±a',
          obscureText: true,
          errorMaxLines: 3,
          error: 'La contraseÃ±a no cumple la polÃ­tica.',
          suffixIcon: IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () => suffixTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('La contraseÃ±a no cumple la polÃ­tica.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility));
    expect(suffixTapped, isTrue);
  });

  testWidgets('NeoErrorBand muestra el detalle inline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const NeoErrorBand(message: 'Datos invÃ¡lidos.')),
    );

    expect(find.text('Datos invÃ¡lidos.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('NeoStat y NeoListItem aceptan fondo de color', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeoStat(
              label: 'Ingresos',
              color: AppColors.cyan,
              value: Text(r'$100'),
            ),
            SizedBox(height: 16),
            NeoListItem(
              title: 'Viaje',
              subtitle: '60 %',
              color: AppColors.lavender,
            ),
          ],
        ),
      ),
    );

    expect(find.text('INGRESOS'), findsOneWidget);
    expect(find.text(r'$100'), findsOneWidget);
    expect(find.text('Viaje'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('NeoBadge y NeoProgress renderizan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeoBadge(label: 'Cerca del plan', color: AppColors.cyan),
            SizedBox(height: 16),
            NeoProgress(value: 0.75, label: 'Ahorro'),
          ],
        ),
      ),
    );

    expect(find.text('Cerca del plan'), findsOneWidget);
    expect(find.text('Ahorro'), findsOneWidget);
    final LinearProgressIndicator progress = tester.widget(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 0.75);
  });

  testWidgets('las tarjetas respetan las densidades', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeoCard(density: AppDensity.hero, child: Text('Hero')),
            NeoCard(density: AppDensity.section, child: Text('Section')),
            NeoCard(density: AppDensity.list, child: Text('List')),
            NeoCard(density: AppDensity.table, child: Text('Table')),
          ],
        ),
      ),
    );

    expect(find.text('Hero'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('List'), findsOneWidget);
    expect(find.text('Table'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('soporta text scaling 2.0 sin overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const NeoCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Saldo disponible'),
              Text(r'$1.234.567'),
              NeoBadge(label: 'Necesidad'),
            ],
          ),
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Saldo disponible'), findsOneWidget);
  });

  testWidgets('los Ã¡tomos se renderizan en modo oscuro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const NeoCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Modo oscuro'),
              NeoBadge(label: 'Necesidad'),
              NeoProgress(value: 0.4),
            ],
          ),
        ),
        theme: SaveUpTheme.dark(),
      ),
    );

    expect(find.text('Modo oscuro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('R-1: onAccentSurface es tinta en los tres temas', () {
    expect(SaveUpColors.light.onAccentSurface, AppColors.ink);
    expect(SaveUpColors.dark.onAccentSurface, AppColors.ink);
    expect(SaveUpColors.bold.onAccentSurface, AppColors.ink);
    // `ink` sÃ­ cambia con el brillo: por eso no sirve sobre acentos fijos.
    expect(SaveUpColors.dark.ink, AppColors.darkText);
  });

  testWidgets('R-1: el foreground de una superficie se deduce por contraste', (
    WidgetTester tester,
  ) async {
    // El color efectivo llega por DefaultTextStyle, no por Text.style.
    Color? colorDeTexto(String texto) {
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.text(texto),
      );
      return paragraph.text.style?.color;
    }

    // Superficie de acento clara en tema oscuro -> tinta, no texto claro.
    await tester.pumpWidget(
      _wrap(
        const NeoSurface(color: AppColors.cyan, child: Text('acento')),
        theme: SaveUpTheme.dark(),
      ),
    );
    expect(colorDeTexto('acento'), AppColors.ink);

    // Superficie oscura en tema oscuro -> texto claro del tema.
    await tester.pumpWidget(
      _wrap(
        const NeoSurface(
          color: AppColors.darkSurfaceAlt,
          child: Text('profunda'),
        ),
        theme: SaveUpTheme.dark(),
      ),
    );
    expect(colorDeTexto('profunda'), AppColors.darkText);
  });
}

