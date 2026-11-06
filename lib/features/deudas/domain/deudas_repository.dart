import 'package:decimal/decimal.dart';

import '../../../core/time/calendar_date.dart';
import 'deuda.dart';

/// Condiciones de un crédito para crear/editar una deuda
/// (`CondicionesCreditoInput`).
///
/// El plazo llega por `cantidadCuotas` **o** por
/// `fechaPrimeraCuota`+`fechaUltimaCuota` (exactamente una vía). En
/// `TASA_CONOCIDA` va una sola tasa; `valorCuota` solo en `CUOTA_CONOCIDA`.
class CondicionesCredito {
  const CondicionesCredito({
    required this.modalidad,
    required this.montoCapital,
    this.cantidadCuotas,
    this.fechaPrimeraCuota,
    this.fechaUltimaCuota,
    this.tasaMensual,
    this.tasaAnualEfectiva,
    this.valorCuota,
    this.gastosIniciales,
    this.costoAdicionalPorCuota,
  });

  final ModalidadCalculo modalidad;
  final Decimal montoCapital;
  final int? cantidadCuotas;
  final CalendarDate? fechaPrimeraCuota;
  final CalendarDate? fechaUltimaCuota;
  final Decimal? tasaMensual;
  final Decimal? tasaAnualEfectiva;
  final Decimal? valorCuota;
  final Decimal? gastosIniciales;
  final Decimal? costoAdicionalPorCuota;
}

/// Datos de creación/edición (`DeudaCreacionDTO`).
class DeudaCreacion {
  const DeudaCreacion({
    required this.nombre,
    this.descripcion,
    required this.tipo,
    this.cuotasPagadasPrevias = 0,
    required this.condiciones,
  });

  final String nombre;
  final String? descripcion;
  final TipoDeuda tipo;
  final int cuotasPagadasPrevias;
  final CondicionesCredito condiciones;
}

/// Contrato de datos de deudas (F4; los pagos llegan en la fase 2).
abstract interface class DeudasRepository {
  /// `GET /deudas/me` (incluye todos los estados).
  Future<List<Deuda>> listar();

  /// `GET /deudas/{id}`.
  Future<Deuda> detalle(int id);

  /// `POST /deudas`.
  Future<Deuda> crear(DeudaCreacion deuda);

  /// `PUT /deudas/{id}` (mismo `DeudaCreacionDTO`).
  Future<Deuda> editar(int id, DeudaCreacion deuda);

  /// `GET /deudas/{id}/amortizacion`.
  Future<List<CuotaAmortizacion>> amortizacion(int id);
}
