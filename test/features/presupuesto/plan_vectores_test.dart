import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/services/calculadora_plan_dart.dart';

/// Versión de `plan-vectores.json` que este motor porta.
const int _versionEsperada = 3;

Decimal _money(Object? value) => Decimal.parse(value!.toString());
Decimal? _moneyOrNull(Object? value) =>
    value == null ? null : Decimal.parse(value.toString());

CategoriaRef _categoria(Object? json) {
  final Map<String, dynamic> c = json as Map<String, dynamic>;
  return CategoriaRef(
    id: c['id'] as int,
    codigo: c['codigo'] as String,
    tipo: TipoPresupuesto.parse(c['tipo'] as String),
  );
}

PartidaCalculo _partida(Object? json) {
  final Map<String, dynamic> p = json as Map<String, dynamic>;
  return PartidaCalculo(
    id: p['id'] as int,
    nombre: p['nombre'] as String,
    categoria: p['categoria'] == null ? null : _categoria(p['categoria']),
    montoPlanificado: _money(p['montoPlanificado']),
    orden: p['orden'] as int,
    grupoId: p['grupoId'] as int?,
    deudaId: p['deudaId'] as int?,
  );
}

MovimientoCalculo _movimiento(Object? json) {
  final Map<String, dynamic> m = json as Map<String, dynamic>;
  return MovimientoCalculo(
    monto: _money(m['monto']),
    tipo: TipoMovimientoPlan.parse(m['tipo'] as String),
    partidaId: m['partidaId'] as int?,
    deudaId: m['deudaId'] as int?,
    categoria: m['categoria'] == null ? null : _categoria(m['categoria']),
  );
}

GrupoCalculo _grupo(Object? json) {
  final Map<String, dynamic> g = json as Map<String, dynamic>;
  return GrupoCalculo(
    id: g['id'] as int?,
    nombre: g['nombre'] as String,
    orden: g['orden'] as int?,
  );
}

void _expectMoney(Decimal? actual, Object? expected, String where) {
  if (expected == null) {
    expect(actual, isNull, reason: where);
    return;
  }
  expect(actual, isNotNull, reason: where);
  expect(
    actual!.compareTo(_money(expected)),
    0,
    reason: '$where: esperado ${_money(expected)}, obtenido $actual',
  );
}

void main() {
  final Map<String, dynamic> documento =
      jsonDecode(
            File('docs/contrato/plan-vectores.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  test('la versión de los vectores es la soportada por este motor', () {
    final int version = documento['version'] as int;
    expect(
      version,
      lessThanOrEqualTo(_versionEsperada),
      reason:
          'plan-vectores.json subió a v$version: revisa PLAN_FORMULAS.md y '
          'actualiza CalculadoraPlanDart antes de avanzar.',
    );
  });

  test('el archivo cubre los 33 casos V01–V33', () {
    final List<dynamic> casos = documento['casos'] as List<dynamic>;
    expect(casos, hasLength(33));
    expect(
      casos.map((Object? c) => (c as Map<String, dynamic>)['id']).toList(),
      List<String>.generate(33, (int i) => 'V${(i + 1).toString().padLeft(2, '0')}'),
    );
  });

  group('vectores del plan', () {
    final List<dynamic> casos = documento['casos'] as List<dynamic>;

    for (final dynamic raw in casos) {
      final Map<String, dynamic> caso = raw as Map<String, dynamic>;
      final String id = caso['id'] as String;
      final String descripcion = caso['descripcion'] as String;

      test('$id — $descripcion', () {
        final Map<String, dynamic> esperado =
            caso['esperado'] as Map<String, dynamic>;
        final Map<String, dynamic>? guiaJson =
            esperado['guia'] as Map<String, dynamic>?;

        final PlanCalculado resultado = const CalculadoraPlanDart().calcular(
          ingresoReferencia: _moneyOrNull(caso['ingresoReferencia']),
          guia: guiaJson == null
              ? null
              : GuiaCalculo(
                  necesidades: _money(guiaJson['necesidades']),
                  deseos: _money(guiaJson['deseos']),
                  ahorro: _money(guiaJson['ahorro']),
                ),
          grupos: <GrupoCalculo>[
            for (final Object? g in caso['grupos'] as List<dynamic>)
              _grupo(g),
          ],
          partidas: <PartidaCalculo>[
            for (final Object? p in caso['partidas'] as List<dynamic>)
              _partida(p),
          ],
          movimientos: <MovimientoCalculo>[
            for (final Object? m in caso['movimientos'] as List<dynamic>)
              _movimiento(m),
          ],
        );

        // Resumen
        final Map<String, dynamic> resumen =
            esperado['resumen'] as Map<String, dynamic>;
        final ResumenCalculado obtenido = resultado.resumen;
        _expectMoney(
          obtenido.planificadoTotal,
          resumen['planificadoTotal'],
          '$id resumen.planificadoTotal',
        );
        _expectMoney(
          obtenido.remanenteLibre,
          resumen['remanenteLibre'],
          '$id resumen.remanenteLibre',
        );
        _expectMoney(
          obtenido.margenSeguridadPct,
          resumen['margenSeguridadPct'],
          '$id resumen.margenSeguridadPct',
        );
        expect(
          obtenido.excedeIngreso,
          resumen['excedeIngreso'],
          reason: '$id resumen.excedeIngreso',
        );
        for (final String campo in <String>[
          'ingresoReal',
          'gastoRealTotal',
          'disponibleReal',
          'ahorroRegistrado',
        ]) {
          _expectMoney(
            switch (campo) {
              'ingresoReal' => obtenido.ingresoReal,
              'gastoRealTotal' => obtenido.gastoRealTotal,
              'disponibleReal' => obtenido.disponibleReal,
              _ => obtenido.ahorroRegistrado,
            },
            resumen[campo],
            '$id resumen.$campo',
          );
        }

        final Map<String, dynamic> sinPlanificar =
            resumen['sinPlanificar'] as Map<String, dynamic>;
        _expectMoney(
          obtenido.sinPlanificar.monto,
          sinPlanificar['monto'],
          '$id sinPlanificar.monto',
        );
        expect(
          obtenido.sinPlanificar.movimientos,
          sinPlanificar['movimientos'],
          reason: '$id sinPlanificar.movimientos',
        );
        final List<dynamic> motivosEsperados =
            sinPlanificar['porMotivo'] as List<dynamic>;
        expect(
          obtenido.sinPlanificar.porMotivo,
          hasLength(motivosEsperados.length),
          reason: '$id sinPlanificar.porMotivo.length',
        );
        for (int i = 0; i < motivosEsperados.length; i++) {
          final Map<String, dynamic> motivo =
              motivosEsperados[i] as Map<String, dynamic>;
          final MotivoCalculado actual = obtenido.sinPlanificar.porMotivo[i];
          expect(
            actual.motivo.codigo,
            motivo['motivo'],
            reason: '$id motivo[$i].motivo',
          );
          _expectMoney(
            actual.monto,
            motivo['monto'],
            '$id motivo[$i].monto',
          );
          expect(
            actual.movimientos,
            motivo['movimientos'],
            reason: '$id motivo[$i].movimientos',
          );
        }

        // Partidas
        final List<dynamic> partidasEsperadas =
            esperado['partidas'] as List<dynamic>;
        expect(resultado.partidas, hasLength(partidasEsperadas.length));
        for (int i = 0; i < partidasEsperadas.length; i++) {
          final Map<String, dynamic> p =
              partidasEsperadas[i] as Map<String, dynamic>;
          final PartidaResultado actual = resultado.partidas[i];
          expect(actual.id, p['id'], reason: '$id partida[$i].id');
          expect(actual.nombre, p['nombre'], reason: '$id partida[$i].nombre');
          _expectMoney(actual.real, p['real'], '$id partida[$i].real');
          _expectMoney(
            actual.diferencia,
            p['diferencia'],
            '$id partida[$i].diferencia',
          );
          _expectMoney(
            actual.porcentajeUsado,
            p['porcentajeUsado'],
            '$id partida[$i].porcentajeUsado',
          );
          expect(
            actual.estado.codigo,
            p['estado'],
            reason: '$id partida[$i].estado',
          );
          expect(
            actual.estadoCuota?.codigo,
            p['estadoCuota'],
            reason: '$id partida[$i].estadoCuota',
          );
        }

        // Por categoría
        final List<dynamic> categoriasEsperadas =
            esperado['porCategoria'] as List<dynamic>;
        expect(resultado.porCategoria, hasLength(categoriasEsperadas.length));
        for (int i = 0; i < categoriasEsperadas.length; i++) {
          final Map<String, dynamic> c =
              categoriasEsperadas[i] as Map<String, dynamic>;
          final CategoriaResultado actual = resultado.porCategoria[i];
          expect(actual.categoriaId, c['categoriaId'], reason: '$id cat[$i].id');
          expect(actual.codigo, c['codigo'], reason: '$id cat[$i].codigo');
          expect(actual.tipo.codigo, c['tipo'], reason: '$id cat[$i].tipo');
          _expectMoney(
            actual.planificado,
            c['planificado'],
            '$id cat[$i].planificado',
          );
          _expectMoney(actual.real, c['real'], '$id cat[$i].real');
          _expectMoney(
            actual.diferencia,
            c['diferencia'],
            '$id cat[$i].diferencia',
          );
          _expectMoney(
            actual.porcentajeUsado,
            c['porcentajeUsado'],
            '$id cat[$i].porcentajeUsado',
          );
          expect(
            actual.estado.codigo,
            c['estado'],
            reason: '$id cat[$i].estado',
          );
        }

        // Reparto por tipo
        final List<dynamic> repartoEsperado =
            esperado['repartoPorTipo'] as List<dynamic>;
        expect(resultado.repartoPorTipo, hasLength(3));
        for (int i = 0; i < repartoEsperado.length; i++) {
          final Map<String, dynamic> r =
              repartoEsperado[i] as Map<String, dynamic>;
          final RepartoTipoResultado actual = resultado.repartoPorTipo[i];
          expect(actual.tipo.codigo, r['tipo'], reason: '$id reparto[$i].tipo');
          _expectMoney(
            actual.planificado,
            r['planificado'],
            '$id reparto[$i].planificado',
          );
          _expectMoney(
            actual.porcentajeDelIngreso,
            r['porcentajeDelIngreso'],
            '$id reparto[$i].porcentajeDelIngreso',
          );
          _expectMoney(actual.real, r['real'], '$id reparto[$i].real');
          _expectMoney(
            actual.porcentajeRealDelIngresoReal,
            r['porcentajeRealDelIngresoReal'],
            '$id reparto[$i].porcentajeRealDelIngresoReal',
          );
          _expectMoney(
            actual.diferenciaPuntos,
            r['diferenciaPuntos'],
            '$id reparto[$i].diferenciaPuntos',
          );
        }

        // Guía
        if (guiaJson == null) {
          expect(resultado.guia, isNull, reason: '$id guia');
        } else {
          expect(resultado.guia, isNotNull, reason: '$id guia');
          _expectMoney(
            resultado.guia!.necesidades,
            guiaJson['necesidades'],
            '$id guia.necesidades',
          );
          _expectMoney(
            resultado.guia!.deseos,
            guiaJson['deseos'],
            '$id guia.deseos',
          );
          _expectMoney(
            resultado.guia!.ahorro,
            guiaJson['ahorro'],
            '$id guia.ahorro',
          );
        }

        // Grupos
        final List<dynamic> gruposEsperados =
            esperado['grupos'] as List<dynamic>;
        expect(resultado.grupos, hasLength(gruposEsperados.length));
        for (int i = 0; i < gruposEsperados.length; i++) {
          final Map<String, dynamic> g =
              gruposEsperados[i] as Map<String, dynamic>;
          final GrupoResultado actual = resultado.grupos[i];
          expect(actual.id, g['id'], reason: '$id grupo[$i].id');
          expect(actual.nombre, g['nombre'], reason: '$id grupo[$i].nombre');
          expect(actual.orden, g['orden'], reason: '$id grupo[$i].orden');
          _expectMoney(
            actual.planificado,
            g['planificado'],
            '$id grupo[$i].planificado',
          );
          _expectMoney(
            actual.porcentajeDelPlanificado,
            g['porcentajeDelPlanificado'],
            '$id grupo[$i].porcentajeDelPlanificado',
          );
          _expectMoney(actual.real, g['real'], '$id grupo[$i].real');
          expect(
            actual.partidaIds,
            g['partidaIds'],
            reason: '$id grupo[$i].partidaIds',
          );
        }
      });
    }
  });

  group('reglas adicionales del motor', () {
    PartidaCalculo partida(Decimal monto, {int id = 1}) => PartidaCalculo(
      id: id,
      nombre: 'Partida $id',
      categoria: const CategoriaRef(
        id: 1,
        codigo: 'ALIMENTACION_BASE',
        tipo: TipoPresupuesto.necesidad,
      ),
      montoPlanificado: monto,
      orden: id,
    );

    test('no muta las entradas y es idempotente', () {
      final PartidaCalculo p = partida(Decimal.parse('100000.00'));
      final MovimientoCalculo m = MovimientoCalculo(
        monto: Decimal.parse('-120000.00'),
        tipo: TipoMovimientoPlan.gastoGeneral,
        partidaId: p.id,
      );
      final Decimal montoOriginal = p.montoPlanificado;
      final Decimal movimientoOriginal = m.monto;

      final CalculadoraPlanDart calculadora = const CalculadoraPlanDart();
      final PlanCalculado uno = calculadora.calcular(
        ingresoReferencia: Decimal.parse('1000000.00'),
        partidas: <PartidaCalculo>[p],
        movimientos: <MovimientoCalculo>[m],
      );
      final PlanCalculado dos = calculadora.calcular(
        ingresoReferencia: Decimal.parse('1000000.00'),
        partidas: <PartidaCalculo>[p],
        movimientos: <MovimientoCalculo>[m],
      );

      expect(p.montoPlanificado, montoOriginal);
      expect(m.monto, movimientoOriginal);
      expect(
        uno.partidas.single.real.compareTo(dos.partidas.single.real),
        0,
      );
      expect(uno.partidas.single.estado, EstadoEjecucion.sobreElPlan);
    });

    test('plan 0: SOBRE con real > 0 y BAJO con real = 0', () {
      final PartidaCalculo p = partida(Decimal.zero);
      final PlanCalculado conGasto = const CalculadoraPlanDart().calcular(
        partidas: <PartidaCalculo>[p],
        movimientos: <MovimientoCalculo>[
          MovimientoCalculo(
            monto: Decimal.parse('-100.00'),
            tipo: TipoMovimientoPlan.gastoGeneral,
            partidaId: p.id,
          ),
        ],
      );
      expect(conGasto.partidas.single.estado, EstadoEjecucion.sobreElPlan);
      expect(conGasto.partidas.single.porcentajeUsado, isNull);

      final PlanCalculado sinGasto = const CalculadoraPlanDart().calcular(
        partidas: <PartidaCalculo>[p],
        movimientos: const <MovimientoCalculo>[],
      );
      expect(sinGasto.partidas.single.estado, EstadoEjecucion.bajoElPlan);
    });

    test('ingreso 0: remanente 0, margen nulo y sin exceso', () {
      final PlanCalculado r = const CalculadoraPlanDart().calcular(
        ingresoReferencia: Decimal.zero,
        partidas: <PartidaCalculo>[],
        movimientos: const <MovimientoCalculo>[],
      );
      expect(r.resumen.remanenteLibre, Decimal.zero);
      expect(r.resumen.margenSeguridadPct, isNull);
      expect(r.resumen.excedeIngreso, isFalse);
    });

    test('250.001 sobre 250.000: porcentaje 100,00 y SOBRE (V10)', () {
      final PartidaCalculo p = partida(Decimal.parse('250000.00'));
      final PlanCalculado r = const CalculadoraPlanDart().calcular(
        partidas: <PartidaCalculo>[p],
        movimientos: <MovimientoCalculo>[
          MovimientoCalculo(
            monto: Decimal.parse('-250001.00'),
            tipo: TipoMovimientoPlan.gastoGeneral,
            partidaId: p.id,
          ),
        ],
      );
      final PartidaResultado partidaResultado = r.partidas.single;
      expect(partidaResultado.porcentajeUsado!.compareTo(
        Decimal.parse('100.00'),
      ), 0);
      expect(partidaResultado.estado, EstadoEjecucion.sobreElPlan);
    });

    test('porcentajeUsado trunca DOWN, no redondea', () {
      // 1 / 3 de 100 = 33,333... → 33,33 (truncado; HALF_UP daría 33,33 igual).
      // 2 / 3 de 100 = 66,666... → 66,66 truncado (HALF_UP daría 66,67).
      final PartidaCalculo p = partida(Decimal.parse('3.00'));
      final PlanCalculado r = const CalculadoraPlanDart().calcular(
        partidas: <PartidaCalculo>[p],
        movimientos: <MovimientoCalculo>[
          MovimientoCalculo(
            monto: Decimal.parse('-2.00'),
            tipo: TipoMovimientoPlan.gastoGeneral,
            partidaId: p.id,
          ),
        ],
      );
      expect(
        r.partidas.single.porcentajeUsado!.compareTo(Decimal.parse('66.66')),
        0,
      );
    });
  });
}
