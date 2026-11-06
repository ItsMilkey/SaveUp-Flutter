import 'package:decimal/decimal.dart';

import '../plan_calculo.dart';

/// Espejo 1:1 de `CalculadoraPlan.java` (T10c/T10d).
///
/// Clase pura: no muta las entradas, no conoce Flutter ni Dio. Todos los
/// montos se normalizan a escala 2 con HALF_UP; `porcentajeUsado` es la única
/// métrica truncada (DOWN) para que el porcentaje mostrado nunca alcance un
/// umbral antes que el estado.
class CalculadoraPlanDart {
  const CalculadoraPlanDart();

  static final Decimal _cien = Decimal.fromInt(100);
  static final BigInt _diezMil = BigInt.from(10000);

  PlanCalculado calcular({
    Decimal? ingresoReferencia,
    GuiaCalculo? guia,
    List<GrupoCalculo> grupos = const <GrupoCalculo>[],
    required List<PartidaCalculo> partidas,
    required List<MovimientoCalculo> movimientos,
  }) {
    final Map<int, PartidaCalculo> partidaPorId = <int, PartidaCalculo>{};
    final Map<int, PartidaCalculo> partidaPorDeuda = <int, PartidaCalculo>{};
    final Map<int, List<PartidaCalculo>> partidasPorCategoria =
        <int, List<PartidaCalculo>>{};
    final Map<int, List<PartidaCalculo>> partidasPorGrupo =
        <int, List<PartidaCalculo>>{};
    final Map<TipoPresupuesto, Decimal> planificadoPorTipo =
        <TipoPresupuesto, Decimal>{};
    final Map<int, Decimal> realPorPartida = <int, Decimal>{};
    final Map<int, Decimal> realPorCategoria = <int, Decimal>{};
    final Map<TipoPresupuesto, Decimal> realPorTipo =
        <TipoPresupuesto, Decimal>{};
    final Map<int, CategoriaRef> categorias = <int, CategoriaRef>{};
    final Map<int, GrupoCalculo> gruposPorId = <int, GrupoCalculo>{
      for (final GrupoCalculo grupo in grupos)
        if (grupo.id != null) grupo.id!: grupo,
    };

    Decimal planificadoTotal = Decimal.zero;
    for (final PartidaCalculo partida in partidas) {
      final Decimal monto = _dinero(partida.montoPlanificado);
      planificadoTotal += monto;
      realPorPartida[partida.id] = Decimal.zero;
      partidaPorId[partida.id] = partida;
      if (partida.deudaId != null) {
        partidaPorDeuda.putIfAbsent(partida.deudaId!, () => partida);
      }
      if (_grupoConocido(partida, gruposPorId)) {
        partidasPorGrupo
            .putIfAbsent(partida.grupoId!, () => <PartidaCalculo>[])
            .add(partida);
      }
      final CategoriaRef? categoria = partida.categoria;
      if (categoria != null) {
        partidasPorCategoria
            .putIfAbsent(categoria.id, () => <PartidaCalculo>[])
            .add(partida);
        categorias.putIfAbsent(categoria.id, () => categoria);
        planificadoPorTipo[categoria.tipo] =
            (planificadoPorTipo[categoria.tipo] ?? Decimal.zero) + monto;
      }
    }
    planificadoTotal = _dinero(planificadoTotal);

    Decimal ingresoReal = Decimal.zero;
    Decimal gastoRealTotal = Decimal.zero;
    Decimal ahorroRegistrado = Decimal.zero;

    Decimal montoSinPlanificar = Decimal.zero;
    int movimientosSinPlanificar = 0;
    final Map<MotivoSinPlanificar, Decimal> montoPorMotivo =
        <MotivoSinPlanificar, Decimal>{};
    final Map<MotivoSinPlanificar, int> movimientosPorMotivo =
        <MotivoSinPlanificar, int>{};

    for (final MovimientoCalculo movimiento in movimientos) {
      final Decimal monto = _dinero(movimiento.monto);
      switch (movimiento.tipo) {
        case TipoMovimientoPlan.ingresoGeneral:
          ingresoReal += monto;
          continue;
        case TipoMovimientoPlan.abonoMeta:
          ahorroRegistrado += monto.abs();
          continue;
        case TipoMovimientoPlan.retiroMeta:
          continue;
        case TipoMovimientoPlan.gastoGeneral:
        case TipoMovimientoPlan.pagoDeuda:
          break;
      }

      final Decimal gasto = monto.abs();
      gastoRealTotal += gasto;

      final CategoriaRef? categoria = movimiento.categoria;
      if (categoria != null) {
        categorias.putIfAbsent(categoria.id, () => categoria);
        realPorCategoria[categoria.id] =
            (realPorCategoria[categoria.id] ?? Decimal.zero) + gasto;
        realPorTipo[categoria.tipo] =
            (realPorTipo[categoria.tipo] ?? Decimal.zero) + gasto;
      }

      MotivoSinPlanificar? motivo;
      PartidaCalculo? objetivo;
      if (movimiento.partidaId != null) {
        objetivo = partidaPorId[movimiento.partidaId];
        if (objetivo == null) {
          motivo = MotivoSinPlanificar.sinPartida;
        }
      } else {
        if (movimiento.tipo == TipoMovimientoPlan.pagoDeuda &&
            movimiento.deudaId != null) {
          objetivo = partidaPorDeuda[movimiento.deudaId];
        }
        if (objetivo == null) {
          if (categoria == null) {
            motivo = MotivoSinPlanificar.sinPartida;
          } else {
            final List<PartidaCalculo> candidatas =
                partidasPorCategoria[categoria.id] ?? const <PartidaCalculo>[];
            if (candidatas.length == 1) {
              objetivo = candidatas.first;
            } else if (candidatas.length >= 2) {
              motivo = MotivoSinPlanificar.categoriaAmbigua;
            } else {
              motivo = MotivoSinPlanificar.sinPartida;
            }
          }
        }
      }

      if (objetivo != null) {
        realPorPartida[objetivo.id] =
            (realPorPartida[objetivo.id] ?? Decimal.zero) + gasto;
      } else {
        montoSinPlanificar += gasto;
        movimientosSinPlanificar += 1;
        final MotivoSinPlanificar motivoFinal =
            motivo ?? MotivoSinPlanificar.sinPartida;
        montoPorMotivo[motivoFinal] =
            (montoPorMotivo[motivoFinal] ?? Decimal.zero) + gasto;
        movimientosPorMotivo[motivoFinal] =
            (movimientosPorMotivo[motivoFinal] ?? 0) + 1;
      }
    }

    final List<PartidaResultado> partidasCalculadas = <PartidaResultado>[
      for (final PartidaCalculo partida in partidas)
        _resultadoPartida(
          partida,
          _dinero(realPorPartida[partida.id] ?? Decimal.zero),
        ),
    ];

    final List<CategoriaResultado> porCategoria = <CategoriaResultado>[];
    for (final MapEntry<int, CategoriaRef> entrada in categorias.entries) {
      final int categoriaId = entrada.key;
      final CategoriaRef categoria = entrada.value;
      Decimal planificado = Decimal.zero;
      for (final PartidaCalculo partida
          in partidasPorCategoria[categoriaId] ?? const <PartidaCalculo>[]) {
        planificado += _dinero(partida.montoPlanificado);
      }
      planificado = _dinero(planificado);
      final Decimal real = _dinero(
        realPorCategoria[categoriaId] ?? Decimal.zero,
      );
      porCategoria.add(
        CategoriaResultado(
          categoriaId: categoriaId,
          codigo: categoria.codigo,
          tipo: categoria.tipo,
          planificado: planificado,
          real: real,
          diferencia: _dinero(planificado - real),
          porcentajeUsado: _porcentajeUsado(real, planificado),
          estado: EstadoEjecucion.desde(real, planificado),
        ),
      );
    }
    porCategoria.sort(
      (CategoriaResultado a, CategoriaResultado b) =>
          a.categoriaId.compareTo(b.categoriaId),
    );

    final List<MotivoCalculado> motivos = <MotivoCalculado>[];
    for (final MotivoSinPlanificar motivo in MotivoSinPlanificar.values) {
      final int cantidad = movimientosPorMotivo[motivo] ?? 0;
      if (cantidad > 0) {
        motivos.add(
          MotivoCalculado(
            motivo: motivo,
            monto: _dinero(montoPorMotivo[motivo] ?? Decimal.zero),
            movimientos: cantidad,
          ),
        );
      }
    }

    final Decimal? remanenteLibre = ingresoReferencia == null
        ? null
        : _dinero(ingresoReferencia - planificadoTotal);
    final Decimal? margenSeguridadPct =
        ingresoReferencia == null || ingresoReferencia == Decimal.zero
        ? null
        : _porcentajeHalfUp(remanenteLibre!, ingresoReferencia);
    final bool excedeIngreso =
        ingresoReferencia != null && planificadoTotal > ingresoReferencia;

    final ResumenCalculado resumen = ResumenCalculado(
      planificadoTotal: planificadoTotal,
      remanenteLibre: remanenteLibre,
      margenSeguridadPct: margenSeguridadPct,
      excedeIngreso: excedeIngreso,
      ingresoReal: _dinero(ingresoReal),
      gastoRealTotal: _dinero(gastoRealTotal),
      disponibleReal: _dinero(ingresoReal - gastoRealTotal),
      ahorroRegistrado: _dinero(ahorroRegistrado),
      sinPlanificar: SinPlanificarCalculado(
        monto: _dinero(montoSinPlanificar),
        movimientos: movimientosSinPlanificar,
        porMotivo: motivos,
      ),
    );

    final List<RepartoTipoResultado> repartoPorTipo = <RepartoTipoResultado>[
      for (final TipoPresupuesto tipo in <TipoPresupuesto>[
        TipoPresupuesto.necesidad,
        TipoPresupuesto.deseo,
        TipoPresupuesto.otros,
      ])
        _reparto(
          tipo,
          _dinero(planificadoPorTipo[tipo] ?? Decimal.zero),
          _dinero(realPorTipo[tipo] ?? Decimal.zero),
          ingresoReferencia,
          _dinero(ingresoReal),
          guia,
        ),
    ];

    return PlanCalculado(
      resumen: resumen,
      partidas: partidasCalculadas,
      porCategoria: porCategoria,
      repartoPorTipo: repartoPorTipo,
      guia: guia,
      grupos: _grupos(
        grupos,
        partidas,
        gruposPorId,
        realPorPartida,
        planificadoTotal,
      ),
    );
  }

  PartidaResultado _resultadoPartida(
    PartidaCalculo partida,
    Decimal real,
  ) {
    final Decimal planificado = _dinero(partida.montoPlanificado);
    return PartidaResultado(
      id: partida.id,
      nombre: partida.nombre,
      real: real,
      diferencia: _dinero(planificado - real),
      porcentajeUsado: _porcentajeUsado(real, planificado),
      estado: EstadoEjecucion.desde(real, planificado),
      estadoCuota: partida.deudaId == null
          ? null
          : EstadoCuota.desde(real, planificado),
    );
  }

  RepartoTipoResultado _reparto(
    TipoPresupuesto tipo,
    Decimal planificado,
    Decimal real,
    Decimal? ingresoReferencia,
    Decimal ingresoReal,
    GuiaCalculo? guia,
  ) {
    final Decimal? porcentajeDelIngreso = _porcentajeHalfUp(
      planificado,
      ingresoReferencia,
    );
    final Decimal? porcentajeReal = _porcentajeHalfUp(real, ingresoReal);
    Decimal? diferenciaPuntos;
    if (tipo != TipoPresupuesto.otros &&
        porcentajeDelIngreso != null &&
        guia != null) {
      final Decimal referencia = tipo == TipoPresupuesto.necesidad
          ? guia.necesidades
          : guia.deseos;
      diferenciaPuntos = _dinero(porcentajeDelIngreso - referencia);
    }
    return RepartoTipoResultado(
      tipo: tipo,
      planificado: planificado,
      porcentajeDelIngreso: porcentajeDelIngreso,
      real: real,
      porcentajeRealDelIngresoReal: porcentajeReal,
      diferenciaPuntos: diferenciaPuntos,
    );
  }

  List<GrupoResultado> _grupos(
    List<GrupoCalculo> grupos,
    List<PartidaCalculo> partidas,
    Map<int, GrupoCalculo> gruposPorId,
    Map<int, Decimal> realPorPartida,
    Decimal planificadoTotal,
  ) {
    final List<GrupoResultado> resultados = <GrupoResultado>[
      for (final GrupoCalculo grupo in grupos)
        _resultadoGrupo(
          grupo,
          partidas,
          realPorPartida,
          planificadoTotal,
          filtrarPorGrupo: true,
        ),
    ];

    final List<PartidaCalculo> sinGrupo = <PartidaCalculo>[
      for (final PartidaCalculo partida in partidas)
        if (!_grupoConocido(partida, gruposPorId)) partida,
    ];
    if (sinGrupo.isNotEmpty) {
      resultados.add(
        _resultadoGrupo(
          const GrupoCalculo(id: null, nombre: 'Sin grupo'),
          sinGrupo,
          realPorPartida,
          planificadoTotal,
          filtrarPorGrupo: false,
        ),
      );
    }
    return resultados;
  }

  GrupoResultado _resultadoGrupo(
    GrupoCalculo grupo,
    List<PartidaCalculo> partidas,
    Map<int, Decimal> realPorPartida,
    Decimal planificadoTotal, {
    required bool filtrarPorGrupo,
  }) {
    Decimal planificado = Decimal.zero;
    Decimal real = Decimal.zero;
    final List<int> ids = <int>[];
    for (final PartidaCalculo partida in partidas) {
      if (filtrarPorGrupo && grupo.id != partida.grupoId) {
        continue;
      }
      planificado += _dinero(partida.montoPlanificado);
      real += _dinero(realPorPartida[partida.id] ?? Decimal.zero);
      ids.add(partida.id);
    }
    planificado = _dinero(planificado);
    return GrupoResultado(
      id: grupo.id,
      nombre: grupo.nombre,
      orden: grupo.orden,
      planificado: planificado,
      porcentajeDelPlanificado: _porcentajeHalfUp(
        planificado,
        planificadoTotal,
      ),
      real: _dinero(real),
      partidaIds: ids,
    );
  }

  bool _grupoConocido(
    PartidaCalculo partida,
    Map<int, GrupoCalculo> gruposPorId,
  ) {
    return partida.grupoId != null && gruposPorId.containsKey(partida.grupoId);
  }

  Decimal _dinero(Decimal? valor) => (valor ?? Decimal.zero).round(scale: 2);

  /// Porcentaje HALF_UP a 2 decimales; nulo si el total es nulo o 0.
  Decimal? _porcentajeHalfUp(Decimal parte, Decimal? total) {
    if (total == null || total == Decimal.zero) {
      return null;
    }
    final BigInt numerador = _centavos(parte) * _diezMil;
    final BigInt denominador = _centavos(total);
    if (denominador == BigInt.zero) {
      return null;
    }
    final bool negativo = numerador.isNegative != denominador.isNegative;
    final BigInt absoluto =
        (numerador.abs() * BigInt.two + denominador.abs()) ~/
        (denominador.abs() * BigInt.two);
    return Decimal.fromBigInt(negativo ? -absoluto : absoluto).shift(-2);
  }

  /// `real·100/plan` truncado DOWN a 2 decimales; nulo si plan = 0.
  Decimal? _porcentajeUsado(Decimal real, Decimal planificado) {
    if (planificado == Decimal.zero) {
      return null;
    }
    final BigInt truncado = (_centavos(real) * _diezMil) ~/ _centavos(planificado);
    return Decimal.fromBigInt(truncado).shift(-2);
  }

  BigInt _centavos(Decimal valor) => (valor * _cien).toBigInt();
}
