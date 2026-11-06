/// DTOs del simulador de crédito.
library;

import 'package:decimal/decimal.dart';

import '../../../core/money/money_json.dart';
import '../../../core/time/calendar_date.dart';
import '../domain/deuda.dart';
import '../domain/simulacion.dart';
import 'deuda_dtos.dart';

Decimal _money(Map<String, dynamic> json, String key) =>
    moneyFromJson(json[key]);

Decimal? _moneyOpt(Map<String, dynamic> json, String key) =>
    json[key] == null ? null : moneyFromJson(json[key]);

CalendarDate? _dateOpt(Object? value) =>
    value is String && value.isNotEmpty ? CalendarDate.parse(value) : null;

/// Cuerpo de `POST /simulaciones/credito`.
class SimulacionRequestDto {
  const SimulacionRequestDto({required this.request});

  final SimulacionRequest request;

  Map<String, Object?> toJson() {
    final SimulacionRequest r = request;
    return <String, Object?>{
      'modalidad': r.modalidad.codigo,
      'montoCapital': moneyToJson(r.montoCapital),
      if (r.cantidadCuotas != null) 'cantidadCuotas': r.cantidadCuotas,
      if (r.fechaPrimeraCuota != null)
        'fechaPrimeraCuota': r.fechaPrimeraCuota!.toJson(),
      if (r.fechaUltimaCuota != null)
        'fechaUltimaCuota': r.fechaUltimaCuota!.toJson(),
      if (r.tasaMensual != null) 'tasaMensual': moneyToJson(r.tasaMensual!),
      if (r.tasaAnualEfectiva != null)
        'tasaAnualEfectiva': moneyToJson(r.tasaAnualEfectiva!),
      if (r.valorCuota != null) 'valorCuota': moneyToJson(r.valorCuota!),
      if (r.gastosIniciales != null)
        'gastosIniciales': moneyToJson(r.gastosIniciales!),
      if (r.costoAdicionalPorCuota != null)
        'costoAdicionalPorCuota': moneyToJson(r.costoAdicionalPorCuota!),
      if (r.ingresoMensual != null)
        'ingresoMensual': moneyToJson(r.ingresoMensual!),
      if (r.cantidadCuotasAlternativas.isNotEmpty)
        'cantidadCuotasAlternativas': r.cantidadCuotasAlternativas,
      'incluirTabla': r.incluirTabla,
    };
  }
}

/// `SimulacionCreditoResponseDTO`.
class SimulacionResponseDto {
  const SimulacionResponseDto._();

  static SimulacionResultado fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> condiciones = _map(json['condiciones']);
    final Map<String, dynamic> resumen = _map(json['resumenEducativo']);
    final List<dynamic> tabla = (json['tablaAmortizacion'] as List?) ?? const <dynamic>[];
    final List<dynamic> comparacion =
        (json['comparacionPlazos'] as List?) ?? const <dynamic>[];
    final List<dynamic> advertencias =
        (json['advertencias'] as List?) ?? const <dynamic>[];

    return SimulacionResultado(
      modalidad: ModalidadCalculo.parse(_string(condiciones, 'modalidad')),
      montoCapital: _money(condiciones, 'montoCapital'),
      cantidadCuotas: _int(condiciones, 'cantidadCuotas'),
      fechaPrimeraCuota: _dateOpt(condiciones['fechaPrimeraCuota']),
      fechaUltimaCuota: _dateOpt(condiciones['fechaUltimaCuota']),
      tasaMensual: _money(condiciones, 'tasaMensual'),
      tasaAnualEfectiva: _money(condiciones, 'tasaAnualEfectiva'),
      valorCuota: _money(json, 'valorCuota'),
      montoTotal: _money(json, 'montoTotal'),
      gastosIniciales: _money(json, 'gastosIniciales'),
      costoTotalCredito: _money(json, 'costoTotalCredito'),
      interesesYCostos: _money(json, 'interesesYCostos'),
      cargaAnualEquivalente: _money(json, 'cargaAnualEquivalente'),
      resumen: ResumenEducativo(
        costoPorCada100: _money(resumen, 'costoPorCada100'),
        porcentajeSobreCapital: _money(resumen, 'porcentajeSobreCapital'),
        porcentajeInteresesYCostos: _money(
          resumen,
          'porcentajeInteresesYCostos',
        ),
        porcentajeIngresoComprometido: _moneyOpt(
          resumen,
          'porcentajeIngresoComprometido',
        ),
      ),
      tabla: tabla
          .map(
            (Object? item) => CuotaAmortizacionDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ),
          )
          .toList(growable: false),
      comparacion: comparacion
          .map((Object? item) {
            final Map<String, dynamic> c = _map(item);
            return ComparacionPlazo(
              cantidadCuotas: _int(c, 'cantidadCuotas'),
              valorCuota: _money(c, 'valorCuota'),
              costoTotalCredito: _money(c, 'costoTotalCredito'),
              interesesYCostos: _money(c, 'interesesYCostos'),
              cargaAnualEquivalente: _money(c, 'cargaAnualEquivalente'),
            );
          })
          .toList(growable: false),
      advertencias: advertencias.map((Object? a) => a.toString()).toList(
        growable: false,
      ),
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map) {
      throw const FormatException('Se esperaba un objeto.');
    }
    return value.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );
  }

  static int _int(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value is! int) {
      throw FormatException('Se esperaba un entero en "$key".');
    }
    return value;
  }

  static String _string(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value is! String) {
      throw FormatException('Se esperaba un texto en "$key".');
    }
    return value;
  }
}
