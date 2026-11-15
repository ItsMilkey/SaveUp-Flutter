import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/time/business_month.dart';
import 'package:saveup_app/features/analitica/presentation/controllers/analitica_controller.dart';
import 'package:saveup_app/features/movimientos/data/dio_categorias_repository.dart';
import 'package:saveup_app/features/movimientos/domain/categoria.dart';
import 'package:saveup_app/features/movimientos/domain/categorias_repository.dart';
import 'package:saveup_app/features/presupuesto/data/dio_plan_mensual_repository.dart';
import 'package:saveup_app/features/presupuesto/data/dio_presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/ejecucion_presupuesto.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/presupuesto_repository.dart';

import '../presupuesto/presupuesto_fixtures.dart';
import 'analitica_fixtures.dart';

void main() {
  late FakePlanAnaliticaRepository planRepo;
  late FakePresupuestoRepository presupuestoRepo;
  late FakeCategoriasAnaliticaRepository categoriasRepo;
  late ProviderContainer container;

  void montar({
    FakePlanAnaliticaRepository? plan,
    FakePresupuestoRepository? presupuesto,
    FakeCategoriasAnaliticaRepository? categorias,
  }) {
    planRepo = plan ?? FakePlanAnaliticaRepository();
    presupuestoRepo = presupuesto ?? FakePresupuestoRepository();
    categoriasRepo = categorias ?? FakeCategoriasAnaliticaRepository();
    container = ProviderContainer(
      overrides: [
        planMensualRepositoryProvider.overrideWithValue(planRepo),
        presupuestoRepositoryProvider.overrideWithValue(presupuestoRepo),
        categoriasRepositoryProvider.overrideWithValue(categoriasRepo),
      ],
    );
    addTearDown(container.dispose);
  }

  AnaliticaController controller() =>
      container.read(analiticaProvider.notifier);
  AnaliticaState estado() => container.read(analiticaProvider);

  test('carga plan, historial y catálogo del mes', () async {
    final List<CategoriaResultado> categorias = <CategoriaResultado>[
      categoriaResultado('ALIMENTACION_BASE', '100'),
    ];
    montar(
      plan: FakePlanAnaliticaRepository(
        plan: planAnalitica(
          mes: '2026-11',
          ingresos: '1000',
          gastos: '100',
          ahorro: '200',
          disponible: '700',
          categorias: categorias,
        ),
      ),
      presupuesto: FakePresupuestoRepository(
        historial: <HistorialPresupuesto>[
          historialAnalitica(
            anio: 2026,
            mes: 11,
            ingresos: '1000',
            gastoNecesidades: '100',
          ),
        ],
      ),
      categorias: FakeCategoriasAnaliticaRepository(
        categorias: <Categoria>[
          categoriaAnalitica(codigo: 'ALIMENTACION_BASE'),
        ],
      ),
    );

    await controller().cargar(mes: const BusinessMonth(2026, 11));

    expect(planRepo.mesSolicitado, '2026-11');
    expect(planRepo.incluirReferenciasSolicitado, isFalse);
    expect(presupuestoRepo.desdeSolicitado, '2026-06');
    expect(presupuestoRepo.hastaSolicitado, '2026-11');
    expect(categoriasRepo.llamadas, 1);

    final AnaliticaState state = estado();
    expect(state.cargando, isFalse);
    expect(state.error, isNull);
    expect(state.errorHistorial, isNull);
    expect(state.resumen!.ingresos.toString(), '1000');
    expect(state.resumen!.categorias.single.nombre, 'Alimentación Básica');
    expect(state.resumen!.tendencia, hasLength(1));
  });

  test('inicia historial y catálogo en paralelo después del plan', () async {
    final _HistorialBloqueado historial = _HistorialBloqueado();
    final _CategoriasBloqueadas categorias = _CategoriasBloqueadas();
    container = ProviderContainer(
      overrides: [
        planMensualRepositoryProvider.overrideWithValue(
          FakePlanAnaliticaRepository(),
        ),
        presupuestoRepositoryProvider.overrideWithValue(historial),
        categoriasRepositoryProvider.overrideWithValue(categorias),
      ],
    );
    addTearDown(container.dispose);

    final Future<void> carga = controller().cargar(
      mes: const BusinessMonth(2026, 11),
    );
    await historial.iniciada.future;
    final bool ambasIniciadas = categorias.iniciada.isCompleted;
    historial.continuar.complete();
    categorias.continuar.complete();
    await carga;

    expect(ambasIniciadas, isTrue);
    expect(estado().resumen, isNotNull);
  });

  test('si falla el plan no hay resumen y no se pide historial', () async {
    montar(plan: FakePlanAnaliticaRepository(error: const NetworkFailure()));

    await controller().cargar(mes: const BusinessMonth(2026, 11));

    expect(estado().error, isA<NetworkFailure>());
    expect(estado().resumen, isNull);
    expect(estado().cargando, isFalse);
    expect(presupuestoRepo.desdeSolicitado, isNull);
  });

  test('si falla el historial el resumen del mes sigue disponible', () async {
    montar(
      plan: FakePlanAnaliticaRepository(
        plan: planAnalitica(
          gastos: '100',
          categorias: <CategoriaResultado>[categoriaResultado('A', '100')],
        ),
      ),
      presupuesto: FakePresupuestoRepository(
        errorHistorial: const ServerFailure(),
      ),
    );

    await controller().cargar(mes: const BusinessMonth(2026, 11));

    expect(estado().error, isNull);
    expect(estado().errorHistorial, isA<ServerFailure>());
    expect(estado().resumen, isNotNull);
    expect(estado().resumen!.tendencia, isEmpty);
  });

  test('si falla el catálogo usa el código como nombre y sin color', () async {
    montar(
      plan: FakePlanAnaliticaRepository(
        plan: planAnalitica(
          gastos: '100',
          categorias: <CategoriaResultado>[
            categoriaResultado('SIN_NOMBRE', '100'),
          ],
        ),
      ),
      categorias: FakeCategoriasAnaliticaRepository(
        error: const NetworkFailure(),
      ),
    );

    await controller().cargar(mes: const BusinessMonth(2026, 11));

    expect(estado().error, isNull);
    expect(estado().resumen!.categorias.single.nombre, 'SIN_NOMBRE');
    expect(estado().resumen!.categorias.single.colorHex, isNull);
  });

  test('cambiarMes cruza el año y mueve la ventana del historial', () async {
    montar();

    await controller().cargar(mes: const BusinessMonth(2026, 1));
    await controller().cambiarMes(-1);

    expect(estado().mes, const BusinessMonth(2025, 12));
    expect(planRepo.mesSolicitado, '2025-12');
    expect(presupuestoRepo.desdeSolicitado, '2025-07');
    expect(presupuestoRepo.hastaSolicitado, '2025-12');
  });

  test('reintentar recupera el resumen tras un error', () async {
    montar(plan: FakePlanAnaliticaRepository(error: const TimeoutFailure()));
    await controller().cargar(mes: const BusinessMonth(2026, 11));
    expect(estado().error, isA<TimeoutFailure>());

    planRepo.error = null;
    await controller().reintentar();

    expect(estado().error, isNull);
    expect(estado().resumen, isNotNull);
  });
}

class _HistorialBloqueado implements PresupuestoRepository {
  final Completer<void> iniciada = Completer<void>();
  final Completer<void> continuar = Completer<void>();

  @override
  Future<List<HistorialPresupuesto>> historial({
    required String desde,
    required String hasta,
  }) async {
    iniciada.complete();
    await continuar.future;
    return <HistorialPresupuesto>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CategoriasBloqueadas implements CategoriasRepository {
  final Completer<void> iniciada = Completer<void>();
  final Completer<void> continuar = Completer<void>();

  @override
  Future<List<Categoria>> listar() async {
    iniciada.complete();
    await continuar.future;
    return <Categoria>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
