import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/movimientos/data/dio_categorias_repository.dart';
import 'package:saveup_app/features/presupuesto/data/dio_presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/limite_categoria.dart';
import 'package:saveup_app/features/presupuesto/presentation/controllers/limites_categorias_controller.dart';

import 'presupuesto_fixtures.dart';

void main() {
  late FakePresupuestoRepository presupuesto;
  late FakeCategoriasRepository categorias;
  late ProviderContainer container;

  void montar({
    FakePresupuestoRepository? repoPresupuesto,
    FakeCategoriasRepository? repoCategorias,
  }) {
    presupuesto = repoPresupuesto ?? FakePresupuestoRepository();
    categorias = repoCategorias ?? FakeCategoriasRepository();
    container = ProviderContainer(
      overrides: [
        presupuestoRepositoryProvider.overrideWithValue(presupuesto),
        categoriasRepositoryProvider.overrideWithValue(categorias),
      ],
    );
    addTearDown(container.dispose);
  }

  LimitesCategoriasController controller() =>
      container.read(limitesCategoriasProvider.notifier);

  LimitesCategoriasState estado() =>
      container.read(limitesCategoriasProvider);

  test('cargar trae catálogo y límites guardados', () async {
    montar(
      repoPresupuesto: FakePresupuestoRepository(
        limites: <LimiteCategoria>[
          limiteDePrueba(),
        ],
      ),
    );
    await controller().cargar();

    expect(estado().categorias, hasLength(2));
    expect(estado().guardados, hasLength(1));
    expect(estado().valores[2].toString(), '100000');
    expect(estado().errorCarga, isNull);
  });

  test('setLimite agrega/actualiza y quitar elimina del conjunto', () async {
    montar();
    await controller().cargar();

    controller().setLimite(2, Decimal.fromInt(50000));
    expect(estado().valores[2].toString(), '50000');

    controller().setLimite(2, Decimal.fromInt(75000));
    expect(estado().valores[2].toString(), '75000');

    controller().setLimite(3, Decimal.parse('12500.50'));
    expect(estado().valores[3].toString(), '12500.5');

    controller().quitar(2);
    expect(estado().valores.containsKey(2), isFalse);
    expect(estado().valores[3].toString(), '12500.5');
  });

  test('guardar envía el conjunto completo y refresca la ejecución', () async {
    montar();
    await controller().cargar();

    await container.read(ejecucionCategoriasProvider.future);
    final int llamadasAntes = presupuesto.llamadasEjecucionCategorias;

    controller().setLimite(2, Decimal.fromInt(100000));
    controller().setLimite(3, Decimal.fromInt(200000));
    await controller().guardar();

    expect(presupuesto.limitesEnviados, hasLength(2));
    final Map<int, String> enviados = <int, String>{
      for (final item in presupuesto.limitesEnviados!)
        item.categoriaId: item.limiteMensual.toString(),
    };
    expect(enviados, <int, String>{2: '100000', 3: '200000'});
    expect(estado().guardado, isTrue);
    expect(estado().error, isNull);

    await container.read(ejecucionCategoriasProvider.future);
    expect(presupuesto.llamadasEjecucionCategorias, greaterThan(llamadasAntes));
  });

  test('guardar rechaza límites ≤ 0 sin llamar al repositorio', () async {
    montar();
    await controller().cargar();

    controller().setLimite(2, Decimal.zero);
    await controller().guardar();

    expect(presupuesto.limitesEnviados, isNull);
    expect(estado().mensajeValidacion, isNotNull);
    expect(estado().guardado, isFalse);
  });

  test('guardar muestra el failure del backend y conserva lo editado', () async {
    montar(
      repoPresupuesto: FakePresupuestoRepository(
        errorGuardarLimites: const BadRequestFailure(
          codigo: 'DATOS_INVALIDOS',
          detail: 'El límite mensual debe ser mayor a 0.',
        ),
      ),
    );
    await controller().cargar();
    controller().setLimite(2, Decimal.fromInt(100000));

    await controller().guardar();

    expect(estado().error, isA<BadRequestFailure>());
    expect(estado().valores[2].toString(), '100000');
    expect(estado().guardado, isFalse);
  });
}
