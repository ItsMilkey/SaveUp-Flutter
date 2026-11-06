/// DTOs escritos a mano para deudas (F4).
///
/// El dinero se lee con `moneyFromJson` (único borde con `num`), las fechas de
/// calendario con `CalendarDate.parse` y los instantes con `parseInstant`.
library;

import 'package:decimal/decimal.dart';

import '../../../core/money/money_json.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/instants.dart';
import '../domain/deuda.dart';
import '../domain/deudas_repository.dart';

Decimal _money(Map<String, dynamic> json, String key) =>
    moneyFromJson(json[key]);

Decimal? _moneyOpt(Map<String, dynamic> json, String key) =>
    json[key] == null ? null : moneyFromJson(json[key]);

CalendarDate? _dateOpt(Object? value) =>
    value is String && value.isNotEmpty ? CalendarDate.parse(value) : null;

int _int(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! int) {
    throw FormatException('Se esperaba un entero en "$key".');
  }
  return value;
}

String _string(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! String) {
    throw FormatException('Se esperaba un texto en "$key".');
  }
  return value;
}

/// `DeudaResponseDTO`.
class DeudaDto {
  const DeudaDto._();

  static Deuda fromJson(Map<String, dynamic> json) {
    return Deuda(
      id: _int(json, 'id'),
      nombre: _string(json, 'nombre'),
      descripcion: json['descripcion'] as String?,
      tipo: TipoDeuda.parse(json['tipoDeuda'] as String?),
      modalidad: ModalidadCalculo.parse(_string(json, 'modalidadCalculo')),
      estado: EstadoDeuda.parse(_string(json, 'estado')),
      montoCapital: _money(json, 'montoCapital'),
      tasaMensual: _money(json, 'tasaMensual'),
      tasaAnualEfectiva: _money(json, 'tasaAnualEfectiva'),
      valorCuota: _moneyOpt(json, 'valorCuota'),
      gastosIniciales: _money(json, 'gastosIniciales'),
      costoAdicionalPorCuota: _money(json, 'costoAdicionalPorCuota'),
      costoTotalCredito: _money(json, 'costoTotalCredito'),
      cargaAnualEquivalente: _money(json, 'cargaAnualEquivalente'),
      fechaPrimeraCuota: _dateOpt(json['fechaPrimeraCuota']),
      fechaUltimaCuota: _dateOpt(json['fechaUltimaCuota']),
      fechaCreacion: parseInstant(_string(json, 'fechaCreacion')),
      cuotasPagadasPrevias: _int(json, 'cuotasPagadasPrevias'),
      montoPagadoPrevio: _money(json, 'montoPagadoPrevio'),
      montoTotal: _money(json, 'montoTotal'),
      cantidadCuotas: _int(json, 'cantidadCuotas'),
      montoPagadoReal: _money(json, 'montoPagadoReal'),
      montoPagado: _money(json, 'montoPagado'),
      montoRestante: _money(json, 'montoRestante'),
      totalPorPagar: _money(json, 'totalPorPagar'),
      saldoCapital: _money(json, 'saldoCapital'),
      cuotasPagadas: _int(json, 'cuotasPagadas'),
      proximaCuotaNumero: json['proximaCuotaNumero'] as int?,
      proximaCuotaMontoPendiente: _moneyOpt(
        json,
        'proximaCuotaMontoPendiente',
      ),
      proximaFechaVencimiento: _dateOpt(json['proximaFechaVencimiento']),
      interesesPagados: _money(json, 'interesesPagados'),
    );
  }
}

/// Cuerpo de `POST /deudas` y `PUT /deudas/{id}` (`DeudaCreacionDTO`).
class DeudaCreacionDto {
  const DeudaCreacionDto({required this.deuda});

  final DeudaCreacion deuda;

  Map<String, Object?> toJson() {
    final CondicionesCredito condiciones = deuda.condiciones;
    return <String, Object?>{
      'nombre': deuda.nombre,
      if (deuda.descripcion != null && deuda.descripcion!.isNotEmpty)
        'descripcion': deuda.descripcion,
      'tipoDeuda': deuda.tipo.codigo,
      'cuotasPagadasPrevias': deuda.cuotasPagadasPrevias,
      'condiciones': <String, Object?>{
        'modalidad': condiciones.modalidad.codigo,
        'montoCapital': moneyToJson(condiciones.montoCapital),
        if (condiciones.cantidadCuotas != null)
          'cantidadCuotas': condiciones.cantidadCuotas,
        if (condiciones.fechaPrimeraCuota != null)
          'fechaPrimeraCuota': condiciones.fechaPrimeraCuota!.toJson(),
        if (condiciones.fechaUltimaCuota != null)
          'fechaUltimaCuota': condiciones.fechaUltimaCuota!.toJson(),
        if (condiciones.tasaMensual != null)
          'tasaMensual': moneyToJson(condiciones.tasaMensual!),
        if (condiciones.tasaAnualEfectiva != null)
          'tasaAnualEfectiva': moneyToJson(condiciones.tasaAnualEfectiva!),
        if (condiciones.valorCuota != null)
          'valorCuota': moneyToJson(condiciones.valorCuota!),
        if (condiciones.gastosIniciales != null)
          'gastosIniciales': moneyToJson(condiciones.gastosIniciales!),
        if (condiciones.costoAdicionalPorCuota != null)
          'costoAdicionalPorCuota': moneyToJson(
            condiciones.costoAdicionalPorCuota!,
          ),
      },
    };
  }
}

/// `CuotaSimulacionDTO` aplicado al cronograma de una deuda.
class CuotaAmortizacionDto {
  const CuotaAmortizacionDto._();

  static CuotaAmortizacion fromJson(Map<String, dynamic> json) {
    return CuotaAmortizacion(
      numero: _int(json, 'numero'),
      fechaVencimiento: _dateOpt(json['fechaVencimiento']),
      cuota: _money(json, 'cuota'),
      capital: _money(json, 'capital'),
      interes: _money(json, 'interes'),
      costoAdicional: _money(json, 'costoAdicional'),
      saldo: _money(json, 'saldo'),
      estado: EstadoCuota.parse(json['estado'] as String?),
      montoPagado: _moneyOpt(json, 'montoPagado'),
      previa: json['previa'] == true,
    );
  }
}
