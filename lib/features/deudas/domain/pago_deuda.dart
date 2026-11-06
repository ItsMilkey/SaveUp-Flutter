import 'package:decimal/decimal.dart';

/// Modo de pago de una deuda (`PagoDeudaDTO.modoPago`).
enum ModoPago {
  cuotaCalculada('CUOTA_CALCULADA'),
  montoPersonalizado('MONTO_PERSONALIZADO');

  const ModoPago(this.codigo);

  final String codigo;
}

/// Pago registrado sobre una deuda (`PagoDeudaResponseDTO`).
class PagoDeuda {
  const PagoDeuda({
    required this.id,
    required this.fecha,
    required this.monto,
    required this.capital,
    required this.interes,
    required this.costos,
    required this.descripcion,
  });

  final int id;
  final DateTime fecha;

  /// Monto en positivo (el movimiento `PAGO_DEUDA` es negativo).
  final Decimal monto;
  final Decimal capital;
  final Decimal interes;
  final Decimal costos;
  final String descripcion;
}

/// Página de pagos (`PageResponseDTO`).
class PaginaPagos {
  const PaginaPagos({
    required this.content,
    required this.currentPage,
    required this.totalItems,
    required this.totalPages,
  });

  final List<PagoDeuda> content;
  final int currentPage;
  final int totalItems;
  final int totalPages;

  bool get esUltima => currentPage + 1 >= totalPages;
}
