import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/metas/data/dio_metas_repository.dart';
import 'package:saveup_app/features/metas/domain/meta_ahorro.dart';
import 'package:saveup_app/features/metas/presentation/screens/meta_form_screen.dart';

import 'metas_fixtures.dart';

Widget _anfitrion(
  FakeMetasRepository repo, {
  MetaAhorro? meta,
}) {
  return ProviderScope(
    overrides: [metasRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MetaFormScreen(meta: meta),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}

Future<void> abrirFormulario(
  WidgetTester tester,
  FakeMetasRepository repo, {
  MetaAhorro? meta,
}) async {
  await tester.pumpWidget(_anfitrion(repo, meta: meta));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('crea una meta con nombre y monto objetivo', (
    WidgetTester tester,
  ) async {
    final FakeMetasRepository repo = FakeMetasRepository(
      metas: <MetaAhorro>[],
    );
    await abrirFormulario(tester, repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'Notebook');
    await tester.enterText(find.byType(TextFormField).at(1), '800000');
    await tester.tap(find.text('Guardar meta'));
    await tester.pumpAndSettle();

    expect(repo.creado!.nombre, 'Notebook');
    expect(repo.creado!.montoObjetivo!.toString(), '800000');
    expect(repo.creado!.fechaLimite, isNull);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('valida nombre y monto obligatorios', (
    WidgetTester tester,
  ) async {
    await abrirFormulario(tester, FakeMetasRepository());

    await tester.tap(find.text('Guardar meta'));
    await tester.pumpAndSettle();

    expect(find.text('Ponle un nombre.'), findsOneWidget);
    expect(find.text('Ingresa el monto objetivo.'), findsOneWidget);
  });

  testWidgets('la meta por defecto solo permite cambiar el nombre', (
    WidgetTester tester,
  ) async {
    final FakeMetasRepository repo = FakeMetasRepository(
      metas: <MetaAhorro>[metaPorDefecto()],
    );
    await abrirFormulario(tester, repo, meta: metaPorDefecto());

    expect(
      find.textContaining('La meta base no tiene objetivo ni fecha'),
      findsOneWidget,
    );
    expect(find.text('Monto objetivo'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ahorros varios');
    await tester.tap(find.text('Guardar meta'));
    await tester.pumpAndSettle();

    expect(repo.editadoId, 1);
    expect(repo.editado!.nombre, 'Ahorros varios');
    expect(repo.editado!.montoObjetivo, isNull);
    expect(repo.editado!.fechaLimite, isNull);
  });

  testWidgets('muestra el error de campo del backend', (
    WidgetTester tester,
  ) async {
    final FakeMetasRepository repo = FakeMetasRepository(
      errorCrear: const ValidationFailure(<FieldError>[
        FieldError(field: 'nombre', message: 'El nombre ya existe.'),
      ]),
    );
    await abrirFormulario(tester, repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'Viaje');
    await tester.enterText(find.byType(TextFormField).at(1), '1000');
    await tester.tap(find.text('Guardar meta'));
    await tester.pumpAndSettle();

    expect(find.text('El nombre ya existe.'), findsOneWidget);
  });
}
