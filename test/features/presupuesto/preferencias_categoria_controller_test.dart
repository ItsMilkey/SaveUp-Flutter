import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/presupuesto/data/dio_categorias_preferencias_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/presentation/controllers/preferencias_categoria_controller.dart';

import 'presupuesto_fixtures.dart';

void main() {
  late FakePreferenciasRepository repo;
  late ProviderContainer container;

  void montar(FakePreferenciasRepository fake) {
    repo = fake;
    container = ProviderContainer(
      overrides: [
        categoriasPreferenciasRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
  }

  PreferenciasCategoriaController controller() =>
      container.read(preferenciasCategoriaProvider.notifier);

  PreferenciasCategoriaState estado() =>
      container.read(preferenciasCategoriaProvider);

  test('cargar lista las preferencias con sus tipos', () async {
    montar(FakePreferenciasRepository());
    await controller().cargar();

    expect(estado().preferencias, hasLength(3));
    expect(estado().errorCarga, isNull);
    expect(estado().preferencias[2].reclasificable, isFalse);
  });

  test('establecer cambia el tipo preferido y limpia el guardando', () async {
    montar(FakePreferenciasRepository());
    await controller().cargar();

    await controller().establecer(2, TipoPresupuesto.deseo);

    expect(repo.ultimoIdEstablecido, 2);
    expect(repo.ultimoTipoEstablecido, TipoPresupuesto.deseo);
    final preferencia = estado().preferencias.firstWhere(
      (item) => item.id == 2,
    );
    expect(preferencia.tipoPreferido, TipoPresupuesto.deseo);
    expect(preferencia.tipoEfectivo, TipoPresupuesto.deseo);
    expect(estado().guardando, isEmpty);
    expect(estado().error, isNull);
  });

  test('quitar elimina la preferencia y vuelve al tipo por defecto', () async {
    montar(FakePreferenciasRepository());
    await controller().cargar();

    await controller().establecer(2, TipoPresupuesto.deseo);
    await controller().quitar(2);

    expect(repo.ultimoIdQuitado, 2);
    final preferencia = estado().preferencias.firstWhere(
      (item) => item.id == 2,
    );
    expect(preferencia.tipoPreferido, isNull);
    expect(preferencia.tipoEfectivo, TipoPresupuesto.necesidad);
  });

  test('establecer ignora AHORRO/OTROS sin llamar al repositorio', () async {
    montar(FakePreferenciasRepository());
    await controller().cargar();

    await controller().establecer(8, TipoPresupuesto.ahorro);
    await controller().establecer(8, TipoPresupuesto.otros);

    expect(repo.ultimoIdEstablecido, isNull);
    expect(estado().guardando, isEmpty);
  });

  test('un error deja el failure visible y libera el guardando', () async {
    montar(
      FakePreferenciasRepository(
        errorEstablecer: const BadRequestFailure(
          codigo: 'DATOS_INVALIDOS',
          detail: 'El tipo preferido debe ser NECESIDAD o DESEO.',
        ),
      ),
    );
    await controller().cargar();

    await controller().establecer(2, TipoPresupuesto.deseo);

    expect(estado().error, isA<BadRequestFailure>());
    expect(estado().guardando, isEmpty);
    expect(
      estado().preferencias.firstWhere((item) => item.id == 2).tipoPreferido,
      isNull,
    );
  });
}
