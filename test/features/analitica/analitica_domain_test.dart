import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/time/business_month.dart';
import 'package:saveup_app/features/analitica/domain/analitica.dart';
import 'package:saveup_app/features/movimientos/domain/categoria.dart';
import 'package:saveup_app/features/presupuesto/domain/ejecucion_presupuesto.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';

import 'analitica_fixtures.dart';

void main() {
  test('top 6 + Otros y porcentajes que suman 100', () {
    final List<CategoriaResultado> categorias = <CategoriaResultado>[
      for (int i = 0; i < 8; i++)
        categoriaResultado('C$i', '${100 - i * 10}'),
    ];
    final List<Categoria> catalogo = <Categoria>[
      for (int i = 0; i < 6; i++)
        categoriaAnalitica(
          id: i,
          codigo: 'C$i',
          nombre: 'Categoría $i',
          colorHex: '#00000$i',
        ),
    ];

    final ResumenAnalitica resumen = construirResumenAnalitica(
      mes: const BusinessMonth(2026, 11),
      plan: planAnalitica(
        ingresos: '1000',
        gastos: '520',
        ahorro: '100',
        disponible: '380',
        categorias: categorias,
      ),
      historial: const <HistorialPresupuesto>[],
      catalogo: catalogo,
    );

    expect(resumen.categorias, hasLength(7));
    expect(resumen.categorias.first.nombre, 'Categoría 0');
    expect(resumen.categorias.first.colorHex, '#000000');
    expect(resumen.categorias.first.monto.toString(), '100');
    expect(resumen.categorias.last.codigo, codigoOtrosAgrupados);
    expect(resumen.categorias.last.monto.toString(), '70');
    expect(resumen.categorias.last.esAgrupado, isTrue);
    expect(resumen.sinCategoria, Decimal.zero);

    final Decimal suma = resumen.categorias.fold(
      Decimal.zero,
      (Decimal acc, GastoCategoria c) => acc + c.porcentaje,
    );
    expect(suma.compareTo(Decimal.fromInt(100)), 0);
  });

  test('incluye Sin categoría cuando el total no cuadra con porCategoria', () {
    final ResumenAnalitica resumen = construirResumenAnalitica(
      mes: const BusinessMonth(2026, 11),
      plan: planAnalitica(gastos: '10000'),
      historial: const <HistorialPresupuesto>[],
      catalogo: const <Categoria>[],
    );

    expect(resumen.categorias, hasLength(1));
    expect(resumen.categorias.single.codigo, codigoSinCategoria);
    expect(resumen.categorias.single.nombre, 'Sin categoría');
    expect(resumen.categorias.single.monto.toString(), '10000');
    expect(resumen.categorias.single.porcentaje.toString(), '100');
    expect(resumen.sinCategoria.toString(), '10000');
  });

  test('mezcla categorías reales y Sin categoría', () {
    final ResumenAnalitica resumen = construirResumenAnalitica(
      mes: const BusinessMonth(2026, 11),
      plan: planAnalitica(
        gastos: '10000',
        categorias: <CategoriaResultado>[
          categoriaResultado('A', '4000'),
          categoriaResultado('B', '3000'),
        ],
      ),
      historial: const <HistorialPresupuesto>[],
      catalogo: <Categoria>[
        categoriaAnalitica(id: 1, codigo: 'A', nombre: 'A'),
        categoriaAnalitica(id: 2, codigo: 'B', nombre: 'B'),
      ],
    );

    expect(resumen.categorias, hasLength(3));
    expect(resumen.categorias[0].monto.toString(), '4000');
    expect(resumen.categorias[0].porcentaje.toString(), '40');
    expect(resumen.categorias[1].porcentaje.toString(), '30');
    expect(resumen.categorias[2].codigo, codigoSinCategoria);
    expect(resumen.categorias[2].monto.toString(), '3000');
    expect(resumen.categorias[2].porcentaje.toString(), '30');
  });

  test('reparto por tipo con porcentajes que suman 100', () {
    final ResumenAnalitica resumen = construirResumenAnalitica(
      mes: const BusinessMonth(2026, 11),
      plan: planAnalitica(
        gastos: '100',
        tipos: <RepartoTipoResultado>[
          tipoResultado(TipoPresupuesto.necesidad, '60'),
          tipoResultado(TipoPresupuesto.deseo, '30'),
          tipoResultado(TipoPresupuesto.otros, '10'),
        ],
      ),
      historial: const <HistorialPresupuesto>[],
      catalogo: const <Categoria>[],
    );

    expect(resumen.porTipo, hasLength(3));
    expect(resumen.porTipo[0].monto.toString(), '60');
    expect(resumen.porTipo[1].porcentaje.toString(), '30');
    expect(resumen.porTipo[2].porcentaje.toString(), '10');
  });

  test('tendencia ordenada y gastos = necesidades + deseos', () {
    final ResumenAnalitica resumen = construirResumenAnalitica(
      mes: const BusinessMonth(2026, 11),
      plan: planAnalitica(),
      historial: <HistorialPresupuesto>[
        historialAnalitica(
          anio: 2026,
          mes: 11,
          ingresos: '300',
          gastoNecesidades: '60',
          gastoDeseos: '40',
          ahorro: '50',
        ),
        historialAnalitica(
          anio: 2026,
          mes: 9,
          ingresos: '100',
          gastoNecesidades: '20',
          gastoDeseos: '10',
          ahorro: '5',
        ),
        historialAnalitica(
          anio: 2026,
          mes: 10,
          ingresos: '200',
          gastoNecesidades: '30',
          gastoDeseos: '20',
          ahorro: '10',
        ),
      ],
      catalogo: const <Categoria>[],
    );

    expect(resumen.tendencia, hasLength(3));
    expect(resumen.tendencia[0].mes, const BusinessMonth(2026, 9));
    expect(resumen.tendencia[0].gastos.toString(), '30');
    expect(resumen.tendencia[1].mes, const BusinessMonth(2026, 10));
    expect(resumen.tendencia[2].ingresos.toString(), '300');
    expect(resumen.tendencia[2].ahorro.toString(), '50');
  });

  test('mes sin movimientos queda vacío', () {
    final ResumenAnalitica resumen = construirResumenAnalitica(
      mes: const BusinessMonth(2026, 11),
      plan: planAnalitica(),
      historial: const <dynamic>[].cast(),
      catalogo: const <Categoria>[],
    );

    expect(resumen.vacio, isTrue);
    expect(resumen.categorias, isEmpty);
    expect(resumen.porTipo, isEmpty);
    expect(resumen.tendencia, isEmpty);
  });
}
