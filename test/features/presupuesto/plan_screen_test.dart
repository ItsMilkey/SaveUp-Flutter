import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/features/presupuesto/data/dio_plan_mensual_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_mensual.dart';
import 'package:saveup_app/features/presupuesto/presentation/screens/plan_screen.dart';

import 'plan_fixtures.dart';

PlanMensual planConGrupos() {
  return planDePrueba(
    ingresoReferencia: d('1000000'),
    grupos: const <GrupoCalculo>[
      GrupoCalculo(id: 1, nombre: 'Fijos', orden: 1),
      GrupoCalculo(id: 2, nombre: 'Variable', orden: 2),
    ],
    partidas: <PartidaSpec>[
      PartidaSpec(
        id: 1,
        nombre: 'Arriendo',
        categoriaId: 4,
        codigo: 'VIVIENDA_SUMINISTROS',
        tipo: TipoPresupuesto.necesidad,
        monto: d('400000'),
        grupoId: 1,
      ),
      PartidaSpec(
        id: 2,
        nombre: 'Netflix',
        categoriaId: 8,
        codigo: 'SUSCRIPCIONES_DIGITAL',
        tipo: TipoPresupuesto.deseo,
        monto: d('10000'),
        grupoId: 1,
      ),
      PartidaSpec(
        id: 3,
        nombre: 'Supermercado',
        categoriaId: 2,
        codigo: 'ALIMENTACION_BASE',
        tipo: TipoPresupuesto.necesidad,
        monto: d('250000'),
        grupoId: 2,
      ),
      PartidaSpec(
        id: 4,
        nombre: 'Transporte',
        categoriaId: 3,
        codigo: 'TRANSPORTE_MOVILIDAD',
        tipo: TipoPresupuesto.necesidad,
        monto: d('80000'),
        grupoId: 2,
      ),
    ],
  );
}

PlanMensual conReferencia(PlanMensual base) {
  return PlanMensual(
    mes: base.mes,
    existe: base.existe,
    ingresoReferencia: base.ingresoReferencia,
    calculo: PlanCalculado(
      resumen: base.calculo.resumen,
      partidas: base.calculo.partidas,
      porCategoria: <CategoriaResultado>[
        CategoriaResultado(
          categoriaId: 4,
          codigo: 'VIVIENDA_SUMINISTROS',
          tipo: TipoPresupuesto.necesidad,
          planificado: Decimal.zero,
          real: Decimal.zero,
          diferencia: Decimal.zero,
          porcentajeUsado: null,
          estado: EstadoEjecucion.bajoElPlan,
          referencia: ReferenciaCategoria(
            mesAnterior: Decimal.zero,
            promedio3Meses: Decimal.zero,
          ),
        ),
      ],
      repartoPorTipo: base.calculo.repartoPorTipo,
      guia: base.calculo.guia,
      grupos: base.calculo.grupos,
    ),
    partidas: base.partidas,
    grupos: base.grupos,
    avisos: base.avisos,
  );
}

Future<void> montar(
  WidgetTester tester,
  FakePlanMensualRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [planMensualRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: PlanScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra resumen, grupos y sliders de las partidas', (
    WidgetTester tester,
  ) async {
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: planConGrupos(),
    );
    await montar(tester, repo);

    expect(find.text('Resumen'), findsOneWidget);
    expect(find.textContaining(r'$740.000'), findsWidgets);
    expect(find.textContaining(r'$260.000'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Fijos'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Fijos'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Variable'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Variable'), findsOneWidget);
    expect(find.byType(Slider), findsWidgets);
    expect(find.text('Sin grupo'), findsNothing);
  });

  testWidgets('navegar al mes siguiente vuelve a consultar el plan', (
    WidgetTester tester,
  ) async {
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: planConGrupos(),
    );
    await montar(tester, repo);
    expect(repo.consultas, hasLength(1));

    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();

    expect(repo.consultas, hasLength(2));
    expect(repo.consultas[0], isNot(repo.consultas[1]));
    expect(repo.consultas[1], matches(RegExp(r'^\d{4}-\d{2}$')));
  });

  testWidgets('el interruptor de referencias recarga y muestra los valores', (
    WidgetTester tester,
  ) async {
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: conReferencia(planConGrupos()),
    );
    await montar(tester, repo);
    expect(repo.consultasReferencias.last, isFalse);

    await tester.tap(find.byTooltip('Referencias históricas'));
    await tester.pumpAndSettle();

    expect(repo.consultasReferencias.last, isTrue);
    await tester.scrollUntilVisible(
      find.text('Referencias históricas'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('Mes anterior'),
      findsWidgets,
    );
  });

  testWidgets('copiar un mes muestra los avisos como información', (
    WidgetTester tester,
  ) async {
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: planConGrupos(),
    );
    repo.avisosCopia = const <AvisoPlan>[
      AvisoPlan(
        motivo: 'SIN_COUOTA_EN_EL_MES',
        partidaId: 20,
        nombre: 'Cuota crédito',
        deudaId: 77,
        mensaje: 'La deuda no tiene cuota en este mes.',
      ),
    ];
    await montar(tester, repo);

    await tester.tap(find.byTooltip('Copiar desde otro mes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SimpleDialogOption).first);
    await tester.pumpAndSettle();

    expect(repo.copias, hasLength(1));
    expect(find.text('Avisos de la copia'), findsOneWidget);
    expect(
      find.textContaining('La deuda no tiene cuota en este mes.'),
      findsOneWidget,
    );
  });

  testWidgets('crear un grupo desde el diálogo', (WidgetTester tester) async {
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: planConGrupos(),
    );
    await montar(tester, repo);

    await tester.tap(find.byTooltip('Grupos'));
    await tester.pumpAndSettle();
    expect(find.text('Grupos del plan'), findsOneWidget);
    expect(find.text('Todavía no hay grupos.'), findsOneWidget);

    await tester.tap(find.text('Nuevo grupo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fijos');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.grupos.single.nombre, 'Fijos');
    expect(find.text('Fijos'), findsWidgets);
  });

  testWidgets('editar el ingreso de referencia desde el resumen', (
    WidgetTester tester,
  ) async {
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: planConGrupos(),
    );
    await montar(tester, repo);
    expect(find.text(r'$1.000.000'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar ingreso de referencia'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ingreso mensual'),
      '900000',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.ingresos.single.$2, d('900000'));
    expect(find.text(r'$900.000'), findsOneWidget);
    expect(find.text(r'$160.000'), findsOneWidget);
  });

  testWidgets('eliminar una partida pide confirmación y llama al DELETE', (
    WidgetTester tester,
  ) async {
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: planConGrupos(),
    );
    await montar(tester, repo);

    await tester.scrollUntilVisible(
      find.byTooltip('Eliminar partida').first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Eliminar partida').first);
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar partida?'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(repo.partidasEliminadas, hasLength(1));
  });

  testWidgets('editar una partida vinculada bloquea categoría y monto', (
    WidgetTester tester,
  ) async {
    final PlanMensual plan = planDePrueba(
      ingresoReferencia: d('1000000'),
      partidas: <PartidaSpec>[
        PartidaSpec(
          id: 20,
          nombre: 'Cuota crédito',
          categoriaId: 8,
          codigo: 'DEUDAS',
          tipo: TipoPresupuesto.necesidad,
          monto: d('43500'),
          deudaId: 77,
        ),
      ],
    );
    final FakePlanMensualRepository repo = FakePlanMensualRepository(
      plan: plan,
    );
    await montar(tester, repo);

    await tester.scrollUntilVisible(
      find.byTooltip('Editar partida'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar partida'));
    await tester.pumpAndSettle();

    expect(find.textContaining('fijada por la deuda'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Monto planificado'), findsNothing);
  });
}
