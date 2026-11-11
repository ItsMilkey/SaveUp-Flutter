import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/features/movimientos/domain/categoria.dart';
import 'package:saveup_app/features/movimientos/domain/movimiento.dart';
import 'package:saveup_app/features/movimientos/domain/movimiento_tipo.dart';
import 'package:saveup_app/features/movimientos/presentation/categoria_picker.dart';
import 'package:saveup_app/features/movimientos/presentation/categoria_visual.dart';

Categoria categoria(
  int id,
  String codigo, {
  String? tipo,
  String? nombre,
}) {
  return Categoria(
    id: id,
    codigo: codigo,
    nombre: nombre ?? codigo,
    tipoPresupuesto: tipo,
  );
}

Movimiento movimiento(
  int id,
  Categoria categoria, {
  MovimientoTipo tipo = MovimientoTipo.gastoGeneral,
}) {
  return Movimiento(
    id: id,
    monto: Decimal.parse('-1000'),
    descripcion: 'movimiento $id',
    fecha: DateTime.utc(2026, 11, 1),
    tipo: tipo,
    categoria: categoria,
  );
}

List<int> ids(List<Categoria> categorias) {
  return <int>[for (final Categoria c in categorias) c.id];
}

void main() {
  test('ingreso solo permite SUELDO y OTROS; gasto excluye SUELDO y AHORRO', () {
    final List<Categoria> todas = <Categoria>[
      categoria(1, 'ALIMENTACION_BASE', tipo: 'NECESIDAD'),
      categoria(2, 'SUELDO', tipo: 'OTROS'),
      categoria(3, 'AHORRO', tipo: 'AHORRO'),
      categoria(4, 'OTROS', tipo: 'OTROS'),
    ];

    expect(
      ids(categoriasPermitidas(todas, MovimientoTipo.ingresoGeneral)),
      <int>[2, 4],
    );
    expect(
      ids(categoriasPermitidas(todas, MovimientoTipo.gastoGeneral)),
      <int>[1, 4],
    );
  });

  test('recientes y más usadas salen solo de los movimientos del tipo', () {
    final List<Categoria> permitidas = <Categoria>[
      categoria(1, 'A', tipo: 'NECESIDAD'),
      categoria(2, 'B', tipo: 'NECESIDAD'),
      categoria(3, 'C', tipo: 'DESEO'),
      categoria(4, 'D', tipo: 'DESEO'),
      categoria(5, 'E', tipo: 'OTROS'),
    ];
    final Categoria a = permitidas[0];
    final Categoria b = permitidas[1];
    final Categoria c = permitidas[2];
    final Categoria d = permitidas[3];
    final Categoria e = permitidas[4];
    final List<Movimiento> movimientos = <Movimiento>[
      movimiento(1, a),
      movimiento(2, b),
      movimiento(3, c),
      movimiento(4, d),
      movimiento(5, e),
      movimiento(6, e),
      movimiento(7, a),
      movimiento(8, a),
      // Un ingreso con otra categoría no debe contar para gastos.
      movimiento(9, b, tipo: MovimientoTipo.ingresoGeneral),
    ];

    final CategoriasSugeridas sugeridas = categoriasPorUso(
      permitidas: permitidas,
      movimientos: movimientos,
      tipo: MovimientoTipo.gastoGeneral,
    );

    expect(ids(sugeridas.recientes), <int>[1, 2, 3, 4]);
    expect(ids(sugeridas.frecuentes), <int>[5]);
  });

  test('con pocos movimientos no se muestra “más usadas”', () {
    final List<Categoria> permitidas = <Categoria>[
      categoria(1, 'A', tipo: 'NECESIDAD'),
      categoria(2, 'B', tipo: 'NECESIDAD'),
    ];
    final List<Movimiento> pocos = <Movimiento>[
      movimiento(1, permitidas[0]),
      movimiento(2, permitidas[1]),
      movimiento(3, permitidas[0]),
      movimiento(4, permitidas[1]),
    ];

    final CategoriasSugeridas sugeridas = categoriasPorUso(
      permitidas: permitidas,
      movimientos: pocos,
      tipo: MovimientoTipo.gastoGeneral,
    );

    expect(ids(sugeridas.recientes), <int>[1, 2]);
    expect(sugeridas.frecuentes, isEmpty);
  });

  test('agrupa en el orden Necesidades → Deseos → Ahorro → Otros', () {
    final List<GrupoCategorias> grupos = agruparCategorias(<Categoria>[
      categoria(1, 'A', tipo: 'OTROS'),
      categoria(2, 'B', tipo: 'AHORRO'),
      categoria(3, 'C', tipo: 'DESEO'),
      categoria(4, 'D', tipo: 'NECESIDAD'),
      categoria(5, 'E'),
    ]);

    expect(
      <String>[for (final GrupoCategorias g in grupos) g.titulo],
      <String>['Necesidades', 'Deseos', 'Ahorro', 'Otros'],
    );
    expect(ids(grupos.last.categorias), <int>[1, 5]);
  });

  test('los iconos usan iconId y caen al código', () {
    expect(
      iconoDeCategoria(categoria(1, 'ALIMENTACION_BASE')),
      Icons.fastfood,
    );
    expect(
      iconoDeCategoria(
        const Categoria(
          id: 2,
          codigo: 'RARO',
          nombre: 'Raro',
          iconId: 'ic_pets',
        ),
      ),
      Icons.pets,
    );
    expect(
      iconoDeCategoria(categoria(3, 'DESCONOCIDA')),
      Icons.category_outlined,
    );
  });
}
