/// DTOs escritos a mano de metas de ahorro (F7).
library;

import 'package:decimal/decimal.dart';

import '../../../core/money/money_json.dart';
import '../../../core/time/calendar_date.dart';
import '../domain/meta_ahorro.dart';

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

Decimal _money(Map<String, dynamic> json, String key) =>
    moneyFromJson(json[key]);

/// `MetaAhorroResponseDTO`.
class MetaAhorroDto {
  const MetaAhorroDto._();

  static MetaAhorro fromJson(Map<String, dynamic> json) {
    final Object? objetivo = json['montoObjetivo'];
    final Object? fecha = json['fechaLimite'];
    return MetaAhorro(
      id: _int(json, 'id'),
      nombre: _string(json, 'nombre'),
      montoActual: _money(json, 'montoActual'),
      montoObjetivo: objetivo == null ? null : moneyFromJson(objetivo),
      fechaLimite: fecha == null ? null : CalendarDate.parse(fecha as String),
    );
  }
}

/// `MetaAhorroCreacionDTO`.
class MetaAhorroDatosDto {
  const MetaAhorroDatosDto(this.datos);

  final MetaAhorroDatos datos;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'nombre': datos.nombre,
      'montoObjetivo': datos.montoObjetivo == null
          ? null
          : moneyToJson(datos.montoObjetivo!),
      'fechaLimite': datos.fechaLimite?.toJson(),
    };
  }
}

/// `AbonoRetiroDTO`.
class AbonoRetiroDto {
  const AbonoRetiroDto({required this.monto, required this.descripcion});

  final Decimal monto;
  final String descripcion;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'monto': moneyToJson(monto),
      'descripcion': descripcion,
    };
  }
}
