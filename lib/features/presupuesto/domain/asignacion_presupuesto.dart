import 'package:decimal/decimal.dart';

/// Reparto del porcentaje de ahorro entre metas (`GET /presupuestos/
/// asignaciones/me`).
class AsignacionPresupuesto {
  const AsignacionPresupuesto({
    required this.metaId,
    required this.metaNombre,
    required this.porcentaje,
  });

  final int metaId;
  final String metaNombre;
  final Decimal porcentaje;
}

/// Par (`metaId`, `porcentaje`) que viaja en `POST /presupuestos/me`.
class AsignacionPresupuestoDatos {
  const AsignacionPresupuestoDatos({
    required this.metaId,
    required this.porcentaje,
  });

  final int metaId;
  final Decimal porcentaje;
}
