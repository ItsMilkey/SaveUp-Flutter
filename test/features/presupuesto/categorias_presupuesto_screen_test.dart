import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/movimientos/data/dio_categorias_repository.dart';
import 'package:saveup_app/features/presupuesto/data/dio_categorias_preferencias_repository.dart';
import 'package:saveup_app/features/presupuesto/data/dio_presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/limite_categoria.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/presentation/screens/categorias_presupuesto_screen.dart';

import 'presupuesto_fixtures.dart';

Future<void> montar(
  WidgetTester tester, {
  required FakePresupuestoRepository presupuesto,
  required FakeCategoriasRepository categorias,
  required FakePreferenciasRepository preferencias,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presupuestoRepositoryProvider.overrideWithValue(presupuesto),
        categoriasRepositoryProvider.overrideWithValue(categorias),
        categoriasPreferenciasRepositoryProvider.overrideWithValue(
          preferencias,
        ),
      ],
      child: const MaterialApp(home: CategoriasPresupuestoScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Finder scrollableDe(Finder lista) => find
    .descendant(of: lista, matching: find.byType(Scrollable))
    .first;

void main() {
  testWidgets('muestra límites, agrega uno y guarda el conjunto completo', (
    WidgetTester tester,
  ) async {
    final FakePresupuestoRepository presupuesto = FakePresupuestoRepository(
      limites: <LimiteCategoria>[limiteDePrueba()],
    );
    final FakeCategoriasRepository categorias = FakeCategoriasRepository();
    await montar(
      tester,
      presupuesto: presupuesto,
      categorias: categorias,
      preferencias: FakePreferenciasRepository(),
    );

    expect(find.text('Alimentación Básica'), findsOneWidget);
    expect(find.text(r'$100.000'), findsOneWidget);

    await tester.tap(find.text('Agregar límite'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '50000');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Ocio'), findsOneWidget);
    expect(find.text(r'$50.000'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Guardar límites'),
      250,
      scrollable: scrollableDe(find.byType(ListView)),
    );
    await tester.tap(find.text('Guardar límites'));
    await tester.pumpAndSettle();

    expect(presupuesto.limitesEnviados, hasLength(2));
    expect(find.text('Límites guardados.'), findsOneWidget);
  });

  testWidgets('cambia y quita el tipo preferido de una categoría', (
    WidgetTester tester,
  ) async {
    final FakePreferenciasRepository preferencias =
        FakePreferenciasRepository();
    await montar(
      tester,
      presupuesto: FakePresupuestoRepository(),
      categorias: FakeCategoriasRepository(),
      preferencias: preferencias,
    );

    await tester.tap(find.text('Tipos'));
    await tester.pumpAndSettle();

    expect(find.text('No reclasificable (Ahorro)'), findsOneWidget);

    await tester.tap(find.text('Deseo').first);
    await tester.pumpAndSettle();

    expect(preferencias.ultimoIdEstablecido, 2);
    expect(preferencias.ultimoTipoEstablecido, TipoPresupuesto.deseo);
    expect(find.text('Quitar preferencia'), findsOneWidget);

    await tester.tap(find.text('Quitar preferencia'));
    await tester.pumpAndSettle();

    expect(preferencias.ultimoIdQuitado, 2);
    expect(find.text('Quitar preferencia'), findsNothing);
  });

  testWidgets('muestra el límite inválido del backend', (
    WidgetTester tester,
  ) async {
    final FakePresupuestoRepository presupuesto = FakePresupuestoRepository(
      errorGuardarLimites: const BadRequestFailure(
        codigo: 'DATOS_INVALIDOS',
        detail: 'El límite mensual debe ser mayor a 0.',
      ),
    );
    await montar(
      tester,
      presupuesto: presupuesto,
      categorias: FakeCategoriasRepository(),
      preferencias: FakePreferenciasRepository(),
    );

    await tester.tap(find.text('Agregar límite'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1000');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Guardar límites'),
      250,
      scrollable: scrollableDe(find.byType(ListView)),
    );
    await tester.tap(find.text('Guardar límites'));
    await tester.pumpAndSettle();

    expect(
      find.text('El límite mensual debe ser mayor a 0.'),
      findsOneWidget,
    );
  });
}
