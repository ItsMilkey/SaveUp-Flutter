import 'package:decimal/decimal.dart';

/// Porcentajes de la regla 50/30/20 (0–100, escala 2; suman 100.00).
class PorcentajesRegla {
  const PorcentajesRegla({
    required this.necesidades,
    required this.deseos,
    required this.ahorro,
  });

  final Decimal necesidades;
  final Decimal deseos;
  final Decimal ahorro;

  static final Decimal _cien = Decimal.fromInt(100);

  /// `true` si la suma es exactamente 100.00 (misma regla que el servidor).
  bool get sumaValida => (necesidades + deseos + ahorro).compareTo(_cien) == 0;

  Decimal get suma => necesidades + deseos + ahorro;
}

/// Configuración de presupuesto guardada (`ConfiguracionPresupuestoResponseDTO`).
class ConfiguracionPresupuesto {
  const ConfiguracionPresupuesto({
    required this.id,
    required this.usuarioRut,
    required this.porcentajes,
    required this.activo,
    required this.automatizarAhorroEnMetas,
  });

  final int id;
  final String usuarioRut;
  final PorcentajesRegla porcentajes;
  final bool activo;
  final bool automatizarAhorroEnMetas;
}

/// Sugerencia de regla desde el historial (`SugerenciaReglaResponseDTO`).
class SugerenciaRegla {
  const SugerenciaRegla({
    required this.actual,
    this.sugerencia,
    required this.mesesAnalizados,
    required this.gastoSuperaIngreso,
    required this.igualALaGuia,
    this.motivo,
  });

  /// Regla vigente del usuario (aunque no tenga configuración).
  final PorcentajesRegla actual;

  /// `null` cuando no hay datos suficientes.
  final PorcentajesRegla? sugerencia;
  final List<String> mesesAnalizados;
  final bool gastoSuperaIngreso;
  final bool igualALaGuia;

  /// `DATOS_INSUFICIENTES` (menos de 2 meses válidos) u otro motivo.
  final String? motivo;
}
