import '../domain/movimiento_tipo.dart';

/// Nombre visible del tipo de movimiento (listado, filtros y formulario).
String tipoMovimientoLabel(MovimientoTipo tipo) => switch (tipo) {
  MovimientoTipo.ingresoGeneral => 'Ingreso',
  MovimientoTipo.gastoGeneral => 'Gasto',
  MovimientoTipo.pagoDeuda => 'Pago de deuda',
  MovimientoTipo.abonoMeta => 'Abono a meta',
  MovimientoTipo.retiroMeta => 'Retiro de meta',
};
