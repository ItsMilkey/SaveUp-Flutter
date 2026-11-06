import 'package:decimal/decimal.dart';

import '../../../core/time/calendar_date.dart';

/// Tipo de deuda (etiqueta; no cambia el cálculo).
enum TipoDeuda {
  personal('PERSONAL'),
  tienda('TIENDA'),
  creditoConsumo('CREDITO_CONSUMO'),
  educacion('EDUCACION'),
  otro('OTRO');

  const TipoDeuda(this.codigo);

  final String codigo;

  static TipoDeuda parse(String? codigo) {
    for (final TipoDeuda tipo in values) {
      if (tipo.codigo == codigo) {
        return tipo;
      }
    }
    return TipoDeuda.otro;
  }
}

/// Modalidad de cálculo del crédito.
enum ModalidadCalculo {
  sinInteres('SIN_INTERES'),
  tasaConocida('TASA_CONOCIDA'),
  cuotaConocida('CUOTA_CONOCIDA');

  const ModalidadCalculo(this.codigo);

  final String codigo;

  static ModalidadCalculo parse(String codigo) {
    for (final ModalidadCalculo modalidad in values) {
      if (modalidad.codigo == codigo) {
        return modalidad;
      }
    }
    throw FormatException('Modalidad desconocida: "$codigo".');
  }
}

/// Estado de la deuda.
enum EstadoDeuda {
  pendiente('PENDIENTE'),
  pagada('PAGADA'),
  cancelada('CANCELADA');

  const EstadoDeuda(this.codigo);

  final String codigo;

  bool get activa => this == EstadoDeuda.pendiente;

  static EstadoDeuda parse(String codigo) {
    for (final EstadoDeuda estado in values) {
      if (estado.codigo == codigo) {
        return estado;
      }
    }
    throw FormatException('Estado de deuda desconocido: "$codigo".');
  }
}

/// Estado de una cuota del cronograma.
enum EstadoCuota {
  pagada('PAGADA'),
  parcial('PARCIAL'),
  pendiente('PENDIENTE');

  const EstadoCuota(this.codigo);

  final String codigo;

  static EstadoCuota? parse(String? codigo) {
    for (final EstadoCuota estado in values) {
      if (estado.codigo == codigo) {
        return estado;
      }
    }
    return null;
  }
}

/// Deuda del usuario según `DeudaResponseDTO`.
///
/// Las tasas llegan en **porcentaje** (1.5 = 1,5 %), no como fracción.
class Deuda {
  const Deuda({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.tipo,
    required this.modalidad,
    required this.estado,
    required this.montoCapital,
    required this.tasaMensual,
    required this.tasaAnualEfectiva,
    this.valorCuota,
    required this.gastosIniciales,
    required this.costoAdicionalPorCuota,
    required this.costoTotalCredito,
    required this.cargaAnualEquivalente,
    this.fechaPrimeraCuota,
    this.fechaUltimaCuota,
    required this.fechaCreacion,
    required this.cuotasPagadasPrevias,
    required this.montoPagadoPrevio,
    required this.montoTotal,
    required this.cantidadCuotas,
    required this.montoPagadoReal,
    required this.montoPagado,
    required this.montoRestante,
    required this.totalPorPagar,
    required this.saldoCapital,
    required this.cuotasPagadas,
    this.proximaCuotaNumero,
    this.proximaCuotaMontoPendiente,
    this.proximaFechaVencimiento,
    required this.interesesPagados,
  });

  final int id;
  final String nombre;
  final String? descripcion;
  final TipoDeuda tipo;
  final ModalidadCalculo modalidad;
  final EstadoDeuda estado;

  final Decimal montoCapital;
  final Decimal tasaMensual;
  final Decimal tasaAnualEfectiva;
  final Decimal? valorCuota;
  final Decimal gastosIniciales;
  final Decimal costoAdicionalPorCuota;
  final Decimal costoTotalCredito;
  final Decimal cargaAnualEquivalente;

  final CalendarDate? fechaPrimeraCuota;
  final CalendarDate? fechaUltimaCuota;
  final DateTime fechaCreacion;

  final int cuotasPagadasPrevias;
  final Decimal montoPagadoPrevio;
  final Decimal montoTotal;
  final int cantidadCuotas;

  final Decimal montoPagadoReal;
  final Decimal montoPagado;
  final Decimal montoRestante;
  final Decimal totalPorPagar;
  final Decimal saldoCapital;
  final int cuotasPagadas;

  final int? proximaCuotaNumero;
  final Decimal? proximaCuotaMontoPendiente;
  final CalendarDate? proximaFechaVencimiento;
  final Decimal interesesPagados;

  /// Progreso para la barra: cuotas pagadas / total.
  double get progreso {
    if (cantidadCuotas <= 0) {
      return 0;
    }
    return (cuotasPagadas / cantidadCuotas).clamp(0, 1).toDouble();
  }

  /// El backend bloquea la edición si ya hay pagos reales (409).
  bool get editable =>
      estado == EstadoDeuda.pendiente && montoPagadoReal == Decimal.zero;
}

/// Fila del cronograma (`CuotaSimulacionDTO` aplicado a una deuda).
class CuotaAmortizacion {
  const CuotaAmortizacion({
    required this.numero,
    this.fechaVencimiento,
    required this.cuota,
    required this.capital,
    required this.interes,
    required this.costoAdicional,
    required this.saldo,
    this.estado,
    this.montoPagado,
    this.previa = false,
  });

  final int numero;
  final CalendarDate? fechaVencimiento;
  final Decimal cuota;
  final Decimal capital;
  final Decimal interes;
  final Decimal costoAdicional;
  final Decimal saldo;
  final EstadoCuota? estado;
  final Decimal? montoPagado;
  final bool previa;
}
