/// Tipos de movimiento del contrato (`openapi.json`).
enum MovimientoTipo {
  ingresoGeneral('INGRESO_GENERAL'),
  gastoGeneral('GASTO_GENERAL'),
  pagoDeuda('PAGO_DEUDA'),
  abonoMeta('ABONO_META'),
  retiroMeta('RETIRO_META');

  const MovimientoTipo(this.codigo);

  /// Valor JSON estable del backend.
  final String codigo;

  static MovimientoTipo parse(String codigo) {
    for (final MovimientoTipo tipo in values) {
      if (tipo.codigo == codigo) {
        return tipo;
      }
    }
    throw FormatException('Tipo de movimiento desconocido: "$codigo".');
  }

  /// Los tipos que se ofrecen al filtro del listado (todos los del contrato).
  static List<MovimientoTipo> get todos => List<MovimientoTipo>.of(values);
}
