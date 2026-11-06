import 'package:decimal/decimal.dart';

import 'plan_calculo.dart';

/// Partida del plan con su metadata de presentación.
class PartidaPlan {
  const PartidaPlan({
    required this.id,
    required this.nombre,
    required this.categoriaId,
    required this.categoriaCodigo,
    required this.montoPlanificado,
    required this.real,
    required this.diferencia,
    required this.porcentajeUsado,
    required this.estado,
    required this.orden,
    required this.actualizadoEn,
    this.estadoCuota,
    this.grupoId,
    this.deudaId,
    this.vinculoDesactualizado = false,
  });

  final int id;
  final String nombre;
  final int categoriaId;
  final String categoriaCodigo;
  final Decimal montoPlanificado;
  final Decimal real;
  final Decimal diferencia;
  final Decimal? porcentajeUsado;
  final EstadoEjecucion estado;
  final EstadoCuota? estadoCuota;
  final int? grupoId;
  final int? deudaId;

  /// `true` si la cuota ya no se puede recalcular y se muestra el último monto.
  final bool vinculoDesactualizado;
  final int orden;
  final DateTime actualizadoEn;

  bool get vinculadaADeuda => deudaId != null;

  PartidaPlan copyWith({
    Decimal? montoPlanificado,
    Decimal? real,
    Decimal? diferencia,
    Decimal? porcentajeUsado,
    bool limpiarPorcentaje = false,
    EstadoEjecucion? estado,
  }) {
    return PartidaPlan(
      id: id,
      nombre: nombre,
      categoriaId: categoriaId,
      categoriaCodigo: categoriaCodigo,
      montoPlanificado: montoPlanificado ?? this.montoPlanificado,
      real: real ?? this.real,
      diferencia: diferencia ?? this.diferencia,
      porcentajeUsado: limpiarPorcentaje
          ? null
          : (porcentajeUsado ?? this.porcentajeUsado),
      estado: estado ?? this.estado,
      estadoCuota: estadoCuota,
      grupoId: grupoId,
      deudaId: deudaId,
      vinculoDesactualizado: vinculoDesactualizado,
      orden: orden,
      actualizadoEn: actualizadoEn,
    );
  }
}

/// Aviso informativo del plan (p. ej. copia con deudas sin cuota).
class AvisoPlan {
  const AvisoPlan({
    required this.motivo,
    this.partidaId,
    this.nombre,
    this.deudaId,
    this.mensaje,
  });

  final String motivo;
  final int? partidaId;
  final String? nombre;
  final int? deudaId;
  final String? mensaje;
}

/// Plan del mes con el cálculo completo y la metadata de presentación.
class PlanMensual {
  const PlanMensual({
    required this.mes,
    required this.existe,
    required this.ingresoReferencia,
    required this.calculo,
    required this.partidas,
    required this.grupos,
    required this.avisos,
  });

  final String mes;
  final bool existe;
  final Decimal? ingresoReferencia;

  /// Resultado del motor (servidor o recálculo local provisional).
  final PlanCalculado calculo;

  final List<PartidaPlan> partidas;
  final List<GrupoResultado> grupos;
  final List<AvisoPlan> avisos;

  PartidaPlan? partida(int id) {
    for (final PartidaPlan partida in partidas) {
      if (partida.id == id) {
        return partida;
      }
    }
    return null;
  }

  /// Aplica un cálculo (local o del servidor) a la metadata de partidas.
  PlanMensual conCalculo(PlanCalculado nuevoCalculo) {
    final Map<int, PartidaResultado> porId = <int, PartidaResultado>{
      for (final PartidaResultado p in nuevoCalculo.partidas) p.id: p,
    };
    return PlanMensual(
      mes: mes,
      existe: existe,
      ingresoReferencia: ingresoReferencia,
      calculo: nuevoCalculo,
      partidas: <PartidaPlan>[
        for (final PartidaPlan partida in partidas)
          _aplicar(partida, porId[partida.id]),
      ],
      grupos: nuevoCalculo.grupos,
      avisos: avisos,
    );
  }

  PlanMensual conPartidas(List<PartidaPlan> nuevas) {
    return PlanMensual(
      mes: mes,
      existe: existe,
      ingresoReferencia: ingresoReferencia,
      calculo: calculo,
      partidas: nuevas,
      grupos: grupos,
      avisos: avisos,
    );
  }

  PartidaPlan _aplicar(PartidaPlan partida, PartidaResultado? calculada) {
    if (calculada == null) {
      return partida;
    }
    return partida.copyWith(
      montoPlanificado: calculada.montoPlanificado,
      real: calculada.real,
      diferencia: calculada.diferencia,
      porcentajeUsado: calculada.porcentajeUsado,
      limpiarPorcentaje: calculada.porcentajeUsado == null,
      estado: calculada.estado,
    );
  }
}

/// Cambio de monto de una partida (`CambioMontoDTO`).
class CambioMonto {
  const CambioMonto({required this.partidaId, required this.monto});

  final int partidaId;
  final Decimal monto;
}

/// Contrato de datos del plan mensual (F6a; el resto del CRUD llega después).
abstract interface class PlanMensualRepository {
  /// `GET /planes/{mes}`.
  Future<PlanMensual> obtener(
    String mes, {
    bool incluirReferencias = false,
  });

  /// `PATCH /planes/{mes}/montos` (lote atómico de 1 a 100).
  Future<PlanMensual> actualizarMontos(
    String mes,
    List<CambioMonto> cambios,
  );
}
