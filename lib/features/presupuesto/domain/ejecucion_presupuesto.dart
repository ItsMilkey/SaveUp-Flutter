import 'package:decimal/decimal.dart';

import 'plan_calculo.dart';

/// Ejecución mensual de la regla (`EjecucionPresupuestoDTO`).
class EjecucionPresupuesto {
  const EjecucionPresupuesto({
    required this.presupuestoNecesidades,
    required this.gastoNecesidades,
    required this.presupuestoDeseos,
    required this.gastoDeseos,
    required this.presupuestoAhorro,
    required this.ahorroRealizado,
    required this.totalIngresos,
    required this.porcentajeNecesidadesConfigurado,
    required this.porcentajeDeseosConfigurado,
    required this.porcentajeAhorroConfigurado,
    required this.automatizarAhorroEnMetas,
  });

  final Decimal presupuestoNecesidades;
  final Decimal gastoNecesidades;
  final Decimal presupuestoDeseos;
  final Decimal gastoDeseos;
  final Decimal presupuestoAhorro;
  final Decimal ahorroRealizado;
  final Decimal totalIngresos;
  final Decimal porcentajeNecesidadesConfigurado;
  final Decimal porcentajeDeseosConfigurado;
  final Decimal porcentajeAhorroConfigurado;
  final bool automatizarAhorroEnMetas;
}

/// Entrada del historial mensual (`HistorialPresupuestoDTO`).
class HistorialPresupuesto {
  const HistorialPresupuesto({
    required this.anio,
    required this.mes,
    required this.ejecucion,
  });

  final int anio;

  /// Mes numérico (1–12).
  final int mes;
  final EjecucionPresupuesto ejecucion;
}

/// Ejecución del límite de una categoría (`EjecucionCategoriaDTO`).
class EjecucionCategoria {
  const EjecucionCategoria({
    required this.categoriaId,
    required this.categoria,
    required this.limite,
    required this.gastado,
    required this.porcentajeUsado,
    required this.estado,
  });

  final int categoriaId;
  final String categoria;
  final Decimal limite;
  final Decimal gastado;
  final Decimal porcentajeUsado;
  final EstadoEjecucion estado;
}
