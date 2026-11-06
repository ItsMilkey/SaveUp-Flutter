import 'package:decimal/decimal.dart';

/// Modelos puros del cálculo del plan mensual (espejo de T10c/T10d).
///
/// El dinero y los porcentajes son [Decimal] con escala 2; los porcentajes de
/// `porcentajeUsado` se truncan down y el resto se redondea HALF_UP.

/// Tipo efectivo de una categoría para el reparto 50/30/20.
enum TipoPresupuesto {
  necesidad('NECESIDAD'),
  deseo('DESEO'),
  ahorro('AHORRO'),
  otros('OTROS');

  const TipoPresupuesto(this.codigo);

  final String codigo;

  static TipoPresupuesto parse(String codigo) {
    for (final TipoPresupuesto tipo in values) {
      if (tipo.codigo == codigo) {
        return tipo;
      }
    }
    throw FormatException('Tipo de presupuesto desconocido: "$codigo".');
  }
}

/// Estado informativo de ejecución de un monto frente a su plan.
enum EstadoEjecucion {
  bajoElPlan('BAJO_EL_PLAN'),
  cercaDelPlan('CERCA_DEL_PLAN'),
  sobreElPlan('SOBRE_EL_PLAN');

  const EstadoEjecucion(this.codigo);

  final String codigo;

  static EstadoEjecucion parse(String codigo) {
    for (final EstadoEjecucion estado in values) {
      if (estado.codigo == codigo) {
        return estado;
      }
    }
    throw FormatException('Estado de ejecución desconocido: "$codigo".');
  }

  /// Compara por **multiplicación cruzada**: `real·100` contra
  /// `80·plan` y `100·plan`; nunca usa el porcentaje truncado.
  static EstadoEjecucion desde(Decimal real, Decimal planificado) {
    if (planificado <= Decimal.zero) {
      return real > Decimal.zero ? sobreElPlan : bajoElPlan;
    }
    final Decimal realEnPorcentaje = real * Decimal.fromInt(100);
    if (realEnPorcentaje < Decimal.fromInt(80) * planificado) {
      return bajoElPlan;
    }
    if (realEnPorcentaje > Decimal.fromInt(100) * planificado) {
      return sobreElPlan;
    }
    return cercaDelPlan;
  }
}

/// Estado del pago de la cuota de una partida vinculada a una deuda.
enum EstadoCuota {
  pendiente('PENDIENTE'),
  parcial('PARCIAL'),
  pagada('PAGADA');

  const EstadoCuota(this.codigo);

  final String codigo;

  static EstadoCuota parse(String codigo) {
    for (final EstadoCuota estado in values) {
      if (estado.codigo == codigo) {
        return estado;
      }
    }
    throw FormatException('Estado de cuota desconocido: "$codigo".');
  }

  static EstadoCuota desde(Decimal real, Decimal montoCuota) {
    if (real == Decimal.zero) {
      return pendiente;
    }
    return real >= montoCuota ? pagada : parcial;
  }
}

/// Motivo por el que un gasto no se imputó a una partida.
enum MotivoSinPlanificar {
  categoriaAmbigua('CATEGORIA_AMBIGUA'),
  sinPartida('SIN_PARTIDA');

  const MotivoSinPlanificar(this.codigo);

  final String codigo;

  static MotivoSinPlanificar parse(String codigo) {
    for (final MotivoSinPlanificar motivo in values) {
      if (motivo.codigo == codigo) {
        return motivo;
      }
    }
    throw FormatException('Motivo sin planificar desconocido: "$codigo".');
  }
}

/// Tipos de movimiento que participan del plan.
enum TipoMovimientoPlan {
  ingresoGeneral('INGRESO_GENERAL'),
  gastoGeneral('GASTO_GENERAL'),
  pagoDeuda('PAGO_DEUDA'),
  abonoMeta('ABONO_META'),
  retiroMeta('RETIRO_META');

  const TipoMovimientoPlan(this.codigo);

  final String codigo;

  static TipoMovimientoPlan parse(String codigo) {
    for (final TipoMovimientoPlan tipo in values) {
      if (tipo.codigo == codigo) {
        return tipo;
      }
    }
    throw FormatException('Tipo de movimiento desconocido: "$codigo".');
  }
}

/// Categoría mínima que necesita el cálculo.
class CategoriaRef {
  const CategoriaRef({
    required this.id,
    required this.codigo,
    required this.tipo,
  });

  final int id;
  final String codigo;
  final TipoPresupuesto tipo;
}

/// Partida del plan tal como entra al cálculo.
class PartidaCalculo {
  const PartidaCalculo({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.montoPlanificado,
    required this.orden,
    this.grupoId,
    this.deudaId,
  });

  final int id;
  final String nombre;
  final CategoriaRef? categoria;
  final Decimal montoPlanificado;
  final int orden;
  final int? grupoId;
  final int? deudaId;
}

/// Movimiento del mes reducido a lo que importa al plan.
class MovimientoCalculo {
  const MovimientoCalculo({
    required this.monto,
    required this.tipo,
    this.partidaId,
    this.deudaId,
    this.categoria,
  });

  final Decimal monto;
  final TipoMovimientoPlan tipo;
  final int? partidaId;
  final int? deudaId;
  final CategoriaRef? categoria;
}

/// Grupo del usuario.
class GrupoCalculo {
  const GrupoCalculo({required this.id, required this.nombre, this.orden});

  final int? id;
  final String nombre;
  final int? orden;
}

/// Guía 50/30/20 del usuario (porcentajes).
class GuiaCalculo {
  const GuiaCalculo({
    required this.necesidades,
    required this.deseos,
    required this.ahorro,
  });

  final Decimal necesidades;
  final Decimal deseos;
  final Decimal ahorro;
}

/// Resultado del cálculo, completo.
class PlanCalculado {
  const PlanCalculado({
    required this.resumen,
    required this.partidas,
    required this.porCategoria,
    required this.repartoPorTipo,
    required this.guia,
    required this.grupos,
  });

  final ResumenCalculado resumen;
  final List<PartidaResultado> partidas;
  final List<CategoriaResultado> porCategoria;
  final List<RepartoTipoResultado> repartoPorTipo;
  final GuiaCalculo? guia;
  final List<GrupoResultado> grupos;
}

class ResumenCalculado {
  const ResumenCalculado({
    required this.planificadoTotal,
    required this.remanenteLibre,
    required this.margenSeguridadPct,
    required this.excedeIngreso,
    required this.ingresoReal,
    required this.gastoRealTotal,
    required this.disponibleReal,
    required this.ahorroRegistrado,
    required this.sinPlanificar,
  });

  final Decimal planificadoTotal;
  final Decimal? remanenteLibre;
  final Decimal? margenSeguridadPct;
  final bool excedeIngreso;
  final Decimal ingresoReal;
  final Decimal gastoRealTotal;
  final Decimal disponibleReal;
  final Decimal ahorroRegistrado;
  final SinPlanificarCalculado sinPlanificar;
}

class SinPlanificarCalculado {
  const SinPlanificarCalculado({
    required this.monto,
    required this.movimientos,
    required this.porMotivo,
  });

  final Decimal monto;
  final int movimientos;
  final List<MotivoCalculado> porMotivo;
}

class MotivoCalculado {
  const MotivoCalculado({
    required this.motivo,
    required this.monto,
    required this.movimientos,
  });

  final MotivoSinPlanificar motivo;
  final Decimal monto;
  final int movimientos;
}

class PartidaResultado {
  const PartidaResultado({
    required this.id,
    required this.nombre,
    required this.real,
    required this.diferencia,
    required this.porcentajeUsado,
    required this.estado,
    required this.estadoCuota,
    required this.montoPlanificado,
    this.categoria,
    this.grupoId,
    this.deudaId,
  });

  final int id;
  final String nombre;
  final Decimal real;
  final Decimal diferencia;
  final Decimal? porcentajeUsado;
  final EstadoEjecucion estado;

  /// Solo para partidas vinculadas a una deuda.
  final EstadoCuota? estadoCuota;

  final Decimal montoPlanificado;
  final CategoriaRef? categoria;
  final int? grupoId;
  final int? deudaId;
}

class CategoriaResultado {
  const CategoriaResultado({
    required this.categoriaId,
    required this.codigo,
    required this.tipo,
    required this.planificado,
    required this.real,
    required this.diferencia,
    required this.porcentajeUsado,
    required this.estado,
  });

  final int categoriaId;
  final String codigo;
  final TipoPresupuesto tipo;
  final Decimal planificado;
  final Decimal real;
  final Decimal diferencia;
  final Decimal? porcentajeUsado;
  final EstadoEjecucion estado;
}

class RepartoTipoResultado {
  const RepartoTipoResultado({
    required this.tipo,
    required this.planificado,
    required this.porcentajeDelIngreso,
    required this.real,
    required this.porcentajeRealDelIngresoReal,
    required this.diferenciaPuntos,
  });

  final TipoPresupuesto tipo;
  final Decimal planificado;
  final Decimal? porcentajeDelIngreso;
  final Decimal real;
  final Decimal? porcentajeRealDelIngresoReal;
  final Decimal? diferenciaPuntos;
}

class GrupoResultado {
  const GrupoResultado({
    required this.id,
    required this.nombre,
    required this.orden,
    required this.planificado,
    required this.porcentajeDelPlanificado,
    required this.real,
    required this.partidaIds,
  });

  final int? id;
  final String nombre;
  final int? orden;
  final Decimal planificado;
  final Decimal? porcentajeDelPlanificado;
  final Decimal real;
  final List<int> partidaIds;
}
