import 'package:decimal/decimal.dart';

import '../../../core/time/calendar_date.dart';
import 'deuda.dart';
import 'pago_deuda.dart';

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

/// Entrada básica de cuota fija sin interés adicional (`CuotaFijaInput`).
class CuotaFija {
  const CuotaFija({
    required this.valorCuota,
    required this.cantidadCuotas,
    this.fechaPrimeraCuota,
  });

  final Decimal valorCuota;
  final int cantidadCuotas;
  final CalendarDate? fechaPrimeraCuota;
}

/// Datos de creación/edición (`DeudaCreacionDTO`).
class DeudaCreacion {
  const DeudaCreacion({
    required this.nombre,
    this.descripcion,
    required this.tipo,
    this.cuotasPagadasPrevias = 0,
    this.condiciones,
    this.cuotaFija,
  });

  final String nombre;
  final String? descripcion;
  final TipoDeuda tipo;
  final int cuotasPagadasPrevias;

  /// Solo presente para alta/edición avanzada.
  final CondicionesCredito? condiciones;

  /// Solo presente para la entrada básica de cuota fija.
  final CuotaFija? cuotaFija;
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

  /// `PATCH /deudas/{id}/fecha-primera-cuota`: fija el calendario sin tocar
  /// montos ni condiciones (también con pagos registrados).
  Future<Deuda> actualizarFechaPrimeraCuota(int id, CalendarDate fecha);

  /// `GET /deudas/{id}/amortizacion`.
  Future<List<CuotaAmortizacion>> amortizacion(int id);

  /// `POST /deudas/{id}/pagar`. Crea un `PAGO_DEUDA` (monto negativo) en el
  /// backend; devuelve la deuda actualizada.
  Future<Deuda> pagar(
    int id, {
    Decimal? monto,
    required ModoPago modo,
    required String descripcion,
  });

  /// `GET /deudas/{id}/pagos?page&size` (orden fecha desc, `size` 20).
  Future<PaginaPagos> pagos(int id, {required int page, int size = 20});

  /// `PATCH /deudas/{id}/cancelar` (no mueve el saldo).
  Future<Deuda> cancelar(int id);
}
