import 'package:decimal/decimal.dart';

import 'categoria.dart';
import 'movimiento_tipo.dart';

/// Movimiento del usuario tal como lo devuelve el backend.
class Movimiento {
  const Movimiento({
    required this.id,
    required this.monto,
    required this.descripcion,
    required this.fecha,
    required this.tipo,
    this.categoria,
    this.partidaId,
  });

  final int id;

  /// Monto con signo y escala 2 (suma o resta al saldo).
  final Decimal monto;

  final String descripcion;

  /// Instante UTC del movimiento.
  final DateTime fecha;

  final MovimientoTipo tipo;
  final Categoria? categoria;

  /// Partida del plan a la que se imputa el gasto; `null` si no tiene.
  final int? partidaId;
}
