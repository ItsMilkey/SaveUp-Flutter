import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/presupuesto/data/dio_presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/presentation/controllers/regla_presupuestaria_controller.dart';

import 'presupuesto_fixtures.dart';

void main() {
  late FakePresupuestoRepository repo;
  late ProviderContainer container;

  void montar(FakePresupuestoRepository fake) {
    repo = fake;
    container = ProviderContainer(
      overrides: [presupuestoRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  }

  ReglaPresupuestariaController controller() =>
      container.read(reglaPresupuestariaProvider.notifier);

  ReglaPresupuestariaState estado() =>
      container.read(reglaPresupuestariaProvider);

  test('cargar usa la configuración existente', () async {
    montar(
      FakePresupuestoRepository(
        config: configuracion(),
        sugerencia: sugerenciaDePrueba(propuesta: porcentajes(necesidades: '55', deseos: '25'),
        ),
      ),
    );
    await controller().cargar();

    expect(estado().necesidades.toString(), '50');
    expect(estado().deseos.toString(), '30');
    expect(estado().ahorro.toString(), '20');
    expect(estado().sumaValida, isTrue);
    expect(estado().config, isNotNull);
  });

  test('sin configuración (404) arranca con la sugerencia', () async {
    montar(
      FakePresupuestoRepository(
        sugerencia: sugerenciaDePrueba(propuesta: porcentajes(necesidades: '55', deseos: '25'),
        ),
      ),
    );
    await controller().cargar();

    expect(estado().config, isNull);
    expect(estado().necesidades.toString(), '55');
    expect(estado().errorCarga, isNull);
  });

  test('autobalanceo proporcional mantiene 100.00', () async {
    montar(FakePresupuestoRepository(config: configuracion()));
    await controller().cargar();

    controller().setNecesidades(Decimal.fromInt(60));
    expect(estado().suma.compareTo(Decimal.fromInt(100)), 0);
    expect(estado().necesidades.toString(), '60');
    expect(estado().deseos.toString(), '24');
    expect(estado().ahorro.toString(), '16');

    controller().setAhorro(Decimal.fromInt(70));
    expect(estado().suma.compareTo(Decimal.fromInt(100)), 0);
    expect(estado().ahorro.toString(), '70');
    expect(
      estado().necesidades + estado().deseos,
      Decimal.fromInt(30),
    );

    // Varios movimientos seguidos nunca rompen la suma.
    for (int i = 0; i <= 100; i++) {
      controller().setDeseos(Decimal.fromInt(i));
      expect(estado().suma.compareTo(Decimal.fromInt(100)), 0);
    }
  });

  test('clamp a 0..100 y resto entregado a los otros bloques', () async {
    montar(FakePresupuestoRepository(config: configuracion()));
    await controller().cargar();

    controller().setDeseos(Decimal.fromInt(150));
    expect(estado().deseos.toString(), '100');
    expect(estado().necesidades.toString(), '0');
    expect(estado().ahorro.toString(), '0');
    expect(estado().sumaValida, isTrue);
  });

  test('aplicarSugerencia copia los tres valores', () async {
    montar(
      FakePresupuestoRepository(
        config: configuracion(),
        sugerencia: sugerenciaDePrueba(propuesta: porcentajes(necesidades: '55', deseos: '25'),
        ),
      ),
    );
    await controller().cargar();
    controller().aplicarSugerencia();

    expect(estado().necesidades.toString(), '55');
    expect(estado().deseos.toString(), '25');
    expect(estado().ahorro.toString(), '20');
  });

  test('guardar envía la regla y las banderas', () async {
    montar(FakePresupuestoRepository(config: configuracion()));
    await controller().cargar();
    controller().setNecesidades(Decimal.fromInt(60));
    controller().setAutomatizarAhorroEnMetas(true);

    await controller().guardar();

    expect(repo.guardados!.necesidades.toString(), '60');
    expect(repo.guardados!.deseos.toString(), '24');
    expect(repo.guardados!.ahorro.toString(), '16');
    expect(repo.automatizarGuardado, isTrue);
    expect(estado().guardado, isTrue);
    expect(estado().sumaValida, isTrue);
  });

  test('guardar muestra el detail de DATOS_INVALIDOS', () async {
    montar(
      FakePresupuestoRepository(
        config: configuracion(),
        errorGuardar: const BadRequestFailure(
          codigo: 'DATOS_INVALIDOS',
          detail: 'Los porcentajes deben sumar 100.00.',
        ),
      ),
    );
    await controller().cargar();
    await controller().guardar();

    expect(estado().error, isA<BadRequestFailure>());
    expect(estado().guardado, isFalse);
  });
}
