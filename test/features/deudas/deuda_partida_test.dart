import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/core/time/business_month.dart';
import 'package:saveup_app/core/time/calendar_date.dart';
import 'package:saveup_app/features/deudas/data/dio_deudas_repository.dart';
import 'package:saveup_app/features/deudas/domain/deuda.dart';
import 'package:saveup_app/features/deudas/domain/deudas_repository.dart';
import 'package:saveup_app/features/deudas/domain/pago_deuda.dart';
import 'package:saveup_app/features/deudas/presentation/deuda_form_screen.dart';
import 'package:saveup_app/features/deudas/presentation/deuda_partida_controller.dart';
import 'package:saveup_app/features/deudas/presentation/deudas_controller.dart';
import 'package:saveup_app/features/presupuesto/data/dio_plan_mensual_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_mensual.dart';

import '../presupuesto/plan_fixtures.dart';

Deuda deudaDePrueba({int id = 7, String nombre = 'Crédito auto'}) {
  return Deuda(
    id: id,
    nombre: nombre,
    tipo: TipoDeuda.otro,
    modalidad: ModalidadCalculo.sinInteres,
    estado: EstadoDeuda.pendiente,
    montoCapital: d('300000'),
    tasaMensual: Decimal.zero,
    tasaAnualEfectiva: Decimal.zero,
    gastosIniciales: Decimal.zero,
    costoAdicionalPorCuota: Decimal.zero,
    costoTotalCredito: d('300000'),
    cargaAnualEquivalente: Decimal.zero,
    fechaCreacion: DateTime.utc(2026, 11, 1),
    cuotasPagadasPrevias: 0,
    montoPagadoPrevio: Decimal.zero,
    montoTotal: d('300000'),
    cantidadCuotas: 3,
    montoPagadoReal: Decimal.zero,
    montoPagado: Decimal.zero,
    montoRestante: d('300000'),
    totalPorPagar: d('300000'),
    saldoCapital: d('300000'),
    cuotasPagadas: 0,
    interesesPagados: Decimal.zero,
  );
}

DeudaCreacion deudaCreacionDePrueba() {
  return DeudaCreacion(
    nombre: 'Crédito auto',
    tipo: TipoDeuda.otro,
    condiciones: CondicionesCredito(
      modalidad: ModalidadCalculo.sinInteres,
      montoCapital: d('300000'),
      cantidadCuotas: 3,
    ),
  );
}

class FakeDeudasRepository implements DeudasRepository {
  FakeDeudasRepository({required this.deuda});

  final Deuda deuda;
  final List<DeudaCreacion> creadas = <DeudaCreacion>[];
  CalendarDate? fechaActualizada;

  @override
  Future<List<Deuda>> listar() async => <Deuda>[deuda];

  @override
  Future<Deuda> detalle(int id) async => deuda;

  @override
  Future<Deuda> crear(DeudaCreacion deuda) async {
    creadas.add(deuda);
    return this.deuda;
  }

  @override
  Future<Deuda> editar(int id, DeudaCreacion deuda) async => this.deuda;

  @override
  Future<Deuda> actualizarFechaPrimeraCuota(int id, CalendarDate fecha) async {
    fechaActualizada = fecha;
    return deuda;
  }

  @override
  Future<List<CuotaAmortizacion>> amortizacion(int id) async {
    return const <CuotaAmortizacion>[];
  }

  @override
  Future<Deuda> pagar(
    int id, {
    Decimal? monto,
    required ModoPago modo,
    required String descripcion,
  }) async {
    return deuda;
  }

  @override
  Future<PaginaPagos> pagos(int id, {required int page, int size = 20}) async {
    return const PaginaPagos(
      content: <PagoDeuda>[],
      currentPage: 0,
      totalItems: 0,
      totalPages: 0,
    );
  }

  @override
  Future<Deuda> cancelar(int id) async => deuda;
}

String mesActual() => BusinessMonth.fromInstant(DateTime.now()).toString();

void main() {
  test('partidaDeDeudaProvider encuentra la partida del mes', () async {
    final FakePlanMensualRepository planRepo = FakePlanMensualRepository(
      plan: planDePrueba(
        mes: mesActual(),
        partidas: <PartidaSpec>[
          PartidaSpec(
            id: 20,
            nombre: 'Cuota crédito',
            categoriaId: 8,
            codigo: 'DEUDAS',
            tipo: TipoPresupuesto.necesidad,
            monto: d('43500'),
            deudaId: 7,
            deudaNombre: 'Crédito auto',
          ),
        ],
      ),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [planMensualRepositoryProvider.overrideWithValue(planRepo)],
    );
    addTearDown(container.dispose);

    final PartidaPlan? partida = await container.read(
      partidaDeDeudaProvider(7).future,
    );
    expect(partida?.id, 20);
    expect(partida?.deudaNombre, 'Crédito auto');
    expect(await container.read(partidaDeDeudaProvider(99).future), isNull);
  });

  test('asociarPartida crea la partida con deudaId y el mes en curso', () async {
    final FakePlanMensualRepository planRepo = FakePlanMensualRepository(
      plan: planDePrueba(mes: mesActual()),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [planMensualRepositoryProvider.overrideWithValue(planRepo)],
    );
    addTearDown(container.dispose);

    final Object? failure = await container
        .read(deudaAccionesProvider.notifier)
        .asociarPartida(7, nombre: 'Crédito auto');

    expect(failure, isNull);
    expect(planRepo.partidasCreadas, hasLength(1));
    expect(planRepo.partidasCreadas.single['mes'], mesActual());
    expect(planRepo.partidasCreadas.single['nombre'], 'Crédito auto');
    expect(planRepo.partidasCreadas.single['deudaId'], 7);
  });

  test('actualizarFechaPrimeraCuota pasa la fecha al repositorio', () async {
    final FakeDeudasRepository deudas = FakeDeudasRepository(
      deuda: deudaDePrueba(),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [deudasRepositoryProvider.overrideWithValue(deudas)],
    );
    addTearDown(container.dispose);

    final Object? failure = await container
        .read(deudaAccionesProvider.notifier)
        .actualizarFechaPrimeraCuota(7, CalendarDate(2026, 9, 15));

    expect(failure, isNull);
    expect(deudas.fechaActualizada?.toString(), '2026-09-15');
  });

  test('crear una deuda con la opción activa crea también la partida', () async {
    final Deuda deuda = deudaDePrueba();
    final FakeDeudasRepository deudas = FakeDeudasRepository(deuda: deuda);
    final FakePlanMensualRepository planRepo = FakePlanMensualRepository(
      plan: planDePrueba(mes: mesActual()),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [
        deudasRepositoryProvider.overrideWithValue(deudas),
        planMensualRepositoryProvider.overrideWithValue(planRepo),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(deudaFormProvider.notifier)
        .submit(deuda: deudaCreacionDePrueba(), crearPartida: true);

    expect(container.read(deudaFormProvider), isA<DeudaFormSuccess>());
    expect(deudas.creadas, hasLength(1));
    expect(planRepo.partidasCreadas, hasLength(1));
    expect(planRepo.partidasCreadas.single['deudaId'], deuda.id);
    expect(planRepo.partidasCreadas.single['mes'], mesActual());
  });

  testWidgets('la opción de partida exige cuotas con fecha', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SaveUpTheme.light(),
          home: const DeudaFormScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder switchFinder = find.widgetWithText(
      SwitchListTile,
      'Crear partida en el plan de ${mesActual()}',
    );
    await tester.scrollUntilVisible(
      switchFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Por cuotas: la opción está deshabilitada.
    expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
    expect(tester.widget<SwitchListTile>(switchFinder).onChanged, isNull);

    await tester.scrollUntilVisible(
      find.text('Por fechas'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Por fechas'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      switchFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<SwitchListTile>(switchFinder).onChanged, isNotNull);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
  });
}
