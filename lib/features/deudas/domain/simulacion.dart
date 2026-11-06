import 'package:decimal/decimal.dart';

import '../../../core/time/calendar_date.dart';
import 'deuda.dart';

/// Entrada de `POST /simulaciones/credito`.
///
/// Plazo por `cantidadCuotas` **o** por fechas (exactamente una vía). En
/// `TASA_CONOCIDA` va una sola tasa; `valorCuota` solo en `CUOTA_CONOCIDA`.
class SimulacionRequest {
  const SimulacionRequest({
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
    this.ingresoMensual,
    this.cantidadCuotasAlternativas = const <int>[],
    this.incluirTabla = true,
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
  final Decimal? ingresoMensual;
  final List<int> cantidadCuotasAlternativas;
  final bool incluirTabla;
}

/// Resumen educativo de la simulación.
class ResumenEducativo {
  const ResumenEducativo({
    required this.costoPorCada100,
    required this.porcentajeSobreCapital,
    required this.porcentajeInteresesYCostos,
    this.porcentajeIngresoComprometido,
  });

  final Decimal costoPorCada100;
  final Decimal porcentajeSobreCapital;
  final Decimal porcentajeInteresesYCostos;
  final Decimal? porcentajeIngresoComprometido;
}

/// Comparación con un plazo alternativo.
class ComparacionPlazo {
  const ComparacionPlazo({
    required this.cantidadCuotas,
    required this.valorCuota,
    required this.costoTotalCredito,
    required this.interesesYCostos,
    required this.cargaAnualEquivalente,
  });

  final int cantidadCuotas;
  final Decimal valorCuota;
  final Decimal costoTotalCredito;
  final Decimal interesesYCostos;
  final Decimal cargaAnualEquivalente;
}

/// Resultado de `POST /simulaciones/credito`.
class SimulacionResultado {
  const SimulacionResultado({
    required this.modalidad,
    required this.montoCapital,
    required this.cantidadCuotas,
    this.fechaPrimeraCuota,
    this.fechaUltimaCuota,
    required this.tasaMensual,
    required this.tasaAnualEfectiva,
    required this.valorCuota,
    required this.montoTotal,
    required this.gastosIniciales,
    required this.costoTotalCredito,
    required this.interesesYCostos,
    required this.cargaAnualEquivalente,
    required this.resumen,
    required this.tabla,
    required this.comparacion,
    required this.advertencias,
  });

  final ModalidadCalculo modalidad;
  final Decimal montoCapital;
  final int cantidadCuotas;
  final CalendarDate? fechaPrimeraCuota;
  final CalendarDate? fechaUltimaCuota;
  final Decimal tasaMensual;
  final Decimal tasaAnualEfectiva;
  final Decimal valorCuota;
  final Decimal montoTotal;
  final Decimal gastosIniciales;
  final Decimal costoTotalCredito;
  final Decimal interesesYCostos;
  final Decimal cargaAnualEquivalente;
  final ResumenEducativo resumen;
  final List<CuotaAmortizacion> tabla;
  final List<ComparacionPlazo> comparacion;
  final List<String> advertencias;
}
