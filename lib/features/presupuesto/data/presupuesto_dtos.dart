/// DTOs escritos a mano del presupuesto (regla, ejecución, historial y límites).
library;

import 'package:decimal/decimal.dart';

import '../../../core/money/money_json.dart';
import '../domain/asignacion_presupuesto.dart';
import '../domain/ejecucion_presupuesto.dart';
import '../domain/limite_categoria.dart';
import '../domain/plan_calculo.dart';
import '../domain/regla_presupuestaria.dart';

Decimal _money(Map<String, dynamic> json, String key) =>
    moneyFromJson(json[key]);

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

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) {
    throw const FormatException('Se esperaba un objeto JSON.');
  }
  return value.map((Object? k, Object? v) => MapEntry(k.toString(), v));
}

class PorcentajesReglaDto {
  const PorcentajesReglaDto._();

  static PorcentajesRegla fromJson(Map<String, dynamic> json) {
    return PorcentajesRegla(
      necesidades: _money(json, 'necesidades'),
      deseos: _money(json, 'deseos'),
      ahorro: _money(json, 'ahorro'),
    );
  }

  static Map<String, Object?> toJson(PorcentajesRegla porcentajes) {
    return <String, Object?>{
      'necesidades': moneyToJson(porcentajes.necesidades),
      'deseos': moneyToJson(porcentajes.deseos),
      'ahorro': moneyToJson(porcentajes.ahorro),
    };
  }
}

/// `ConfiguracionPresupuestoResponseDTO`.
class ConfiguracionPresupuestoDto {
  const ConfiguracionPresupuestoDto._();

  static ConfiguracionPresupuesto fromJson(Map<String, dynamic> json) {
    return ConfiguracionPresupuesto(
      id: _int(json, 'id'),
      usuarioRut: _string(json, 'usuarioRut'),
      porcentajes: PorcentajesRegla(
        necesidades: _money(json, 'porcentajeNecesidades'),
        deseos: _money(json, 'porcentajeDeseos'),
        ahorro: _money(json, 'porcentajeAhorro'),
      ),
      activo: json['activo'] == true,
      automatizarAhorroEnMetas: json['automatizarAhorroEnMetas'] == true,
    );
  }
}

/// `ConfiguracionPresupuestoRequestDTO`.
class ConfiguracionPresupuestoRequestDto {
  const ConfiguracionPresupuestoRequestDto({
    required this.porcentajes,
    required this.activo,
    required this.automatizarAhorroEnMetas,
    this.asignaciones,
  });

  final PorcentajesRegla porcentajes;
  final bool activo;
  final bool automatizarAhorroEnMetas;

  /// `null` = omitir el campo (conserva); `[]` = limpiar.
  final List<AsignacionPresupuestoDatos>? asignaciones;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'porcentajeNecesidades': moneyToJson(porcentajes.necesidades),
      'porcentajeDeseos': moneyToJson(porcentajes.deseos),
      'porcentajeAhorro': moneyToJson(porcentajes.ahorro),
      'activo': activo,
      'automatizarAhorroEnMetas': automatizarAhorroEnMetas,
      if (asignaciones != null)
        'asignaciones': <Map<String, Object?>>[
          for (final AsignacionPresupuestoDatos item in asignaciones!)
            <String, Object?>{
              'metaId': item.metaId,
              'porcentaje': moneyToJson(item.porcentaje),
            },
        ],
    };
  }
}

/// `AsignacionPresupuestoDTO`.
class AsignacionPresupuestoDto {
  const AsignacionPresupuestoDto._();

  static AsignacionPresupuesto fromJson(Map<String, dynamic> json) {
    return AsignacionPresupuesto(
      metaId: _int(json, 'metaId'),
      metaNombre: _string(json, 'metaNombre'),
      porcentaje: _money(json, 'porcentaje'),
    );
  }
}

/// `SugerenciaReglaResponseDTO`.
class SugerenciaReglaDto {
  const SugerenciaReglaDto._();

  static SugerenciaRegla fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? sugerenciaJson = json['sugerencia'] == null
        ? null
        : _map(json['sugerencia']);
    return SugerenciaRegla(
      actual: PorcentajesReglaDto.fromJson(_map(json['actual'])),
      sugerencia: sugerenciaJson == null
          ? null
          : PorcentajesReglaDto.fromJson(sugerenciaJson),
      mesesAnalizados: <String>[
        for (final Object? mes in (json['mesesAnalizados'] as List?) ?? const <dynamic>[])
          mes as String,
      ],
      gastoSuperaIngreso: json['gastoSuperaIngreso'] == true,
      igualALaGuia: json['igualALaGuia'] == true,
      motivo: json['motivo'] as String?,
    );
  }
}

/// `EjecucionPresupuestoDTO`.
class EjecucionPresupuestoDto {
  const EjecucionPresupuestoDto._();

  static EjecucionPresupuesto fromJson(Map<String, dynamic> json) {
    return EjecucionPresupuesto(
      presupuestoNecesidades: _money(json, 'presupuestoNecesidades'),
      gastoNecesidades: _money(json, 'gastoNecesidades'),
      presupuestoDeseos: _money(json, 'presupuestoDeseos'),
      gastoDeseos: _money(json, 'gastoDeseos'),
      presupuestoAhorro: _money(json, 'presupuestoAhorro'),
      ahorroRealizado: _money(json, 'ahorroRealizado'),
      totalIngresos: _money(json, 'totalIngresos'),
      porcentajeNecesidadesConfigurado: _money(
        json,
        'porcentajeNecesidadesConfigurado',
      ),
      porcentajeDeseosConfigurado: _money(
        json,
        'porcentajeDeseosConfigurado',
      ),
      porcentajeAhorroConfigurado: _money(
        json,
        'porcentajeAhorroConfigurado',
      ),
      automatizarAhorroEnMetas: json['automatizarAhorroEnMetas'] == true,
    );
  }
}

/// `HistorialPresupuestoDTO`.
class HistorialPresupuestoDto {
  const HistorialPresupuestoDto._();

  static HistorialPresupuesto fromJson(Map<String, dynamic> json) {
    return HistorialPresupuesto(
      anio: _int(json, 'anio'),
      mes: _int(json, 'mes'),
      ejecucion: EjecucionPresupuestoDto.fromJson(_map(json['ejecucion'])),
    );
  }
}

/// `PresupuestoCategoriaDTO`.
class LimiteCategoriaDto {
  const LimiteCategoriaDto._();

  static LimiteCategoria fromJson(Map<String, dynamic> json) {
    return LimiteCategoria(
      categoriaId: _int(json, 'categoriaId'),
      categoria: _string(json, 'categoria'),
      limiteMensual: _money(json, 'limiteMensual'),
    );
  }
}

/// Cuerpo de `PUT /presupuestos/categorias/me`.
class LimitesCategoriaRequestDto {
  const LimitesCategoriaRequestDto({required this.categorias});

  final List<LimiteCategoriaItem> categorias;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'categorias': <Map<String, Object?>>[
        for (final LimiteCategoriaItem item in categorias)
          <String, Object?>{
            'categoriaId': item.categoriaId,
            'limiteMensual': moneyToJson(item.limiteMensual),
          },
      ],
    };
  }
}

/// `EjecucionCategoriaDTO`.
class EjecucionCategoriaDto {
  const EjecucionCategoriaDto._();

  static EjecucionCategoria fromJson(Map<String, dynamic> json) {
    return EjecucionCategoria(
      categoriaId: _int(json, 'categoriaId'),
      categoria: _string(json, 'categoria'),
      limite: _money(json, 'limite'),
      gastado: _money(json, 'gastado'),
      porcentajeUsado: _money(json, 'porcentajeUsado'),
      estado: EstadoEjecucion.parse(_string(json, 'estado')),
    );
  }
}
