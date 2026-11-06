import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/features/movimientos/data/dio_categorias_repository.dart';
import 'package:saveup_app/features/movimientos/domain/categoria.dart';
import 'package:saveup_app/features/movimientos/domain/categorias_repository.dart';
import 'package:saveup_app/features/movimientos/domain/sugerencia_categoria.dart';
import 'package:saveup_app/features/movimientos/presentation/categoria_sugerencia_controller.dart';

typedef _Llamada = ({String texto, ContextoSugerencia contexto});

class _FakeCategorias implements CategoriasRepository {
  final List<_Llamada> llamadas = <_Llamada>[];
  final List<Completer<RespuestaSugerencia>> pendientes =
      <Completer<RespuestaSugerencia>>[];

  @override
  Future<List<Categoria>> listar() async => const <Categoria>[];

  @override
  Future<RespuestaSugerencia> sugerir({
    required String texto,
    ContextoSugerencia contexto = ContextoSugerencia.gasto,
  }) {
    llamadas.add((texto: texto, contexto: contexto));
    final Completer<RespuestaSugerencia> completer =
        Completer<RespuestaSugerencia>();
    pendientes.add(completer);
    return completer.future;
  }
}

RespuestaSugerencia respuesta(String texto, {bool ambigua = false}) {
  return RespuestaSugerencia(
    texto: texto,
    sugerencias: <SugerenciaCategoria>[
      SugerenciaCategoria(
        categoriaId: 17,
        codigo: 'REGALOS_CELEBRACIONES',
        nombre: 'Regalos y Celebraciones',
        confianza: Decimal.parse('0.90'),
        motivo: 'PALABRA_CLAVE',
      ),
    ],
    ambigua: ambigua,
  );
}

void main() {
  late _FakeCategorias repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeCategorias();
    container = ProviderContainer(
      overrides: [
        categoriasRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> avanzar(WidgetTester tester, int ms) async {
    await tester.pump(Duration(milliseconds: ms));
  }

  testWidgets('debounce de 400 ms: una sola consulta', (
    WidgetTester tester,
  ) async {
    container.read(sugerenciaCategoriaProvider);
    final SugerenciaCategoriaController controller = container.read(
      sugerenciaCategoriaProvider.notifier,
    );

    controller.actualizarTexto('cena');
    await avanzar(tester, 399);
    expect(repo.llamadas, isEmpty);

    await avanzar(tester, 2);
    expect(repo.llamadas, hasLength(1));
    expect(repo.llamadas.single.texto, 'cena');
  });

  testWidgets('teclas seguidas reinician el debounce', (
    WidgetTester tester,
  ) async {
    container.read(sugerenciaCategoriaProvider);
    final SugerenciaCategoriaController controller = container.read(
      sugerenciaCategoriaProvider.notifier,
    );

    controller.actualizarTexto('ce');
    await avanzar(tester, 300);
    controller.actualizarTexto('cena');
    await avanzar(tester, 300);
    expect(repo.llamadas, isEmpty);

    await avanzar(tester, 101);
    expect(repo.llamadas.single.texto, 'cena');
  });

  testWidgets('descarta la respuesta atrasada por eco de texto', (
    WidgetTester tester,
  ) async {
    container.read(sugerenciaCategoriaProvider);
    final SugerenciaCategoriaController controller = container.read(
      sugerenciaCategoriaProvider.notifier,
    );

    controller.actualizarTexto('uno');
    await avanzar(tester, 401);
    expect(repo.llamadas, hasLength(1));

    controller.actualizarTexto('dos');
    await avanzar(tester, 401);
    expect(repo.llamadas, hasLength(2));

    // Llega primero la respuesta de "uno": debe descartarse.
    repo.pendientes[0].complete(respuesta('uno'));
    await tester.pump();
    expect(
      container.read(sugerenciaCategoriaProvider).value,
      isNull,
      reason: 'la respuesta de "uno" llegó cuando el texto es "dos"',
    );

    repo.pendientes[1].complete(respuesta('dos'));
    await tester.pump();
    expect(
      container.read(sugerenciaCategoriaProvider).value?.texto,
      'dos',
    );
  });

  testWidgets('usa contexto INGRESO al consultar', (
    WidgetTester tester,
  ) async {
    container.read(sugerenciaCategoriaProvider);
    final SugerenciaCategoriaController controller = container.read(
      sugerenciaCategoriaProvider.notifier,
    );

    controller.actualizarTexto(
      'sueldo',
      contexto: ContextoSugerencia.ingreso,
    );
    await avanzar(tester, 401);

    expect(repo.llamadas.single.contexto, ContextoSugerencia.ingreso);
  });

  testWidgets('expone ambigua para que la UI pida confirmación', (
    WidgetTester tester,
  ) async {
    container.read(sugerenciaCategoriaProvider);
    final SugerenciaCategoriaController controller = container.read(
      sugerenciaCategoriaProvider.notifier,
    );

    controller.actualizarTexto('comida');
    await avanzar(tester, 401);
    repo.pendientes.single.complete(respuesta('comida', ambigua: true));
    await tester.pump();

    expect(
      container.read(sugerenciaCategoriaProvider).value?.ambigua,
      isTrue,
    );
  });

  testWidgets('texto vacío no consulta y limpia el estado', (
    WidgetTester tester,
  ) async {
    container.read(sugerenciaCategoriaProvider);
    final SugerenciaCategoriaController controller = container.read(
      sugerenciaCategoriaProvider.notifier,
    );

    controller.actualizarTexto('   ');
    await avanzar(tester, 500);

    expect(repo.llamadas, isEmpty);
    expect(container.read(sugerenciaCategoriaProvider).value, isNull);
  });
}
