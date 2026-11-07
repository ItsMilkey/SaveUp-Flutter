import 'package:decimal/decimal.dart';

import '../../../core/time/calendar_date.dart';

/// Meta de ahorro (`MetaAhorroResponseDTO`).
///
/// `montoObjetivo` y `fechaLimite` pueden ser nulos en la meta legacy por
/// defecto («Ahorros»), que solo acumula ahorro sin objetivo fijo.
class MetaAhorro {
  const MetaAhorro({
    required this.id,
    required this.nombre,
    required this.montoActual,
    this.montoObjetivo,
    this.fechaLimite,
  });

  final int id;
  final String nombre;
  final Decimal? montoObjetivo;
  final CalendarDate? fechaLimite;
  final Decimal montoActual;

  bool get sinObjetivo => montoObjetivo == null;

  /// Meta legacy sin objetivo ni fecha: solo permite cambiar el nombre y no
  /// se puede eliminar (el backend responde 409).
  bool get esPorDefecto => montoObjetivo == null && fechaLimite == null;
}

/// Datos de creación/edición (`MetaAhorroCreacionDTO`).
class MetaAhorroDatos {
  const MetaAhorroDatos({
    required this.nombre,
    this.montoObjetivo,
    this.fechaLimite,
  });

  final String nombre;
  final Decimal? montoObjetivo;
  final CalendarDate? fechaLimite;
}
