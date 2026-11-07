import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/time/business_month.dart';
import 'package:saveup_app/features/presupuesto/data/dio_presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/ejecucion_presupuesto.dart';
import 'package:saveup_app/features/presupuesto/presentation/controllers/ejecucion_presupuesto_controller.dart';

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

  EjecucionPresupuestoController controller() =>
      container.read(ejecucionPresupuestoProvider.notifier);

  EjecucionPresupuestoState estado() =>
      container.read(ejecucionPresupuestoProvider);

  test('cargar pide la ejecución del mes y 6 meses de historial', () async {
    montar(
      FakePresupuestoRepository(
        historial: <HistorialPresupuesto>[
          historialDePrueba(anio: 2026, mes: 10),
        ],
      ),
    );
    await controller().cargar(mes: const BusinessMonth(2026, 10));

    expect(repo.monthSolicitado, 10);
    expect(repo.yearSolicitado, 2026);
    expect(repo.desdeSolicitado, '2026-05');
    expect(repo.hastaSolicitado, '2026-10');
    expect(estado().cargando, isFalse);
    expect(estado().ejecucion, isNotNull);
    expect(estado().historial, hasLength(1));
    expect(estado().error, isNull);
  });

  test('cambiarMes cruza el año en ambos sentidos', () async {
    montar(FakePresupuestoRepository());
    await controller().cargar(mes: const BusinessMonth(2026, 1));

    await controller().cambiarMes(-1);
    expect(estado().mes, const BusinessMonth(2025, 12));
    expect(repo.monthSolicitado, 12);
    expect(repo.yearSolicitado, 2025);
    expect(repo.desdeSolicitado, '2025-07');
    expect(repo.hastaSolicitado, '2025-12');

    await controller().cambiarMes(1);
    expect(estado().mes, const BusinessMonth(2026, 1));
  });

  test('un error al recargar conserva la ejecución previa', () async {
    montar(FakePresupuestoRepository());
    await controller().cargar(mes: const BusinessMonth(2026, 10));
    expect(estado().ejecucion, isNotNull);

    repo.errorEjecucion = const NetworkFailure();
    await controller().cambiarMes(1);

    expect(estado().error, isA<NetworkFailure>());
    expect(estado().ejecucion, isNotNull);
    expect(estado().mes, const BusinessMonth(2026, 11));
  });

  test('si falla el historial, la ejecución igual se muestra', () async {
    montar(
      FakePresupuestoRepository(
        errorHistorial: const ServerFailure(),
      ),
    );
    await controller().cargar(mes: const BusinessMonth(2026, 10));

    expect(estado().ejecucion, isNotNull);
    expect(estado().error, isA<ServerFailure>());
  });
}
