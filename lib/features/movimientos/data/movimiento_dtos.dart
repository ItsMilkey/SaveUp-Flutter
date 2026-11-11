/// DTOs escritos a mano para movimientos, saldo y categorías.
///
/// La forma viene de `docs/contrato/openapi.json`. El dinero se lee con
/// `moneyFromJson` (único borde con `num`) y las fechas con `parseInstant`.
library;

import 'package:decimal/decimal.dart';

import '../../../core/money/money_json.dart';
import '../../../core/time/instants.dart';
import '../domain/categoria.dart';
import '../domain/movimiento.dart';
import '../domain/movimiento_filtro.dart';
import '../domain/movimiento_tipo.dart';
import '../domain/sugerencia_categoria.dart';

/// `GET /saldos/me` → `{ saldo }`.
class SaldoDto {
  const SaldoDto({required this.saldo});

  factory SaldoDto.fromJson(Map<String, dynamic> json) {
    return SaldoDto(saldo: moneyFromJson(json['saldo']));
  }

  final Decimal saldo;
}

/// `CategoriaDTO`.
class CategoriaDto {
  const CategoriaDto({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.iconId,
    this.colorHex,
    this.tipoPresupuesto,
  });

  factory CategoriaDto.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? codigo = json['codigo'];
    final Object? nombre = json['nombre'];
    if (id is! int || codigo is! String || nombre is! String) {
      throw const FormatException('Categoría incompleta.');
    }
    return CategoriaDto(
      id: id,
      codigo: codigo,
      nombre: nombre,
      iconId: json['iconId'] as String?,
      colorHex: json['colorHex'] as String?,
      tipoPresupuesto: json['tipoPresupuesto'] as String?,
    );
  }

  final int id;
  final String codigo;
  final String nombre;
  final String? iconId;
  final String? colorHex;
  final String? tipoPresupuesto;

  Categoria toDomain() => Categoria(
    id: id,
    codigo: codigo,
    nombre: nombre,
    iconId: iconId,
    colorHex: colorHex,
    tipoPresupuesto: tipoPresupuesto,
  );
}

/// `MovimientoResponseDTO`.
class MovimientoDto {
  const MovimientoDto({
    required this.id,
    required this.monto,
    required this.descripcion,
    required this.fecha,
    required this.tipo,
    this.categoria,
    this.partidaId,
  });

  factory MovimientoDto.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? descripcion = json['descripcion'];
    final Object? fecha = json['fecha'];
    final Object? tipo = json['tipoMovimiento'];
    if (id is! int ||
        descripcion is! String ||
        fecha is! String ||
        tipo is! String) {
      throw const FormatException('Movimiento incompleto.');
    }
    final Object? categoriaJson = json['categoria'];
    return MovimientoDto(
      id: id,
      monto: moneyFromJson(json['monto']),
      descripcion: descripcion,
      fecha: parseInstant(fecha),
      tipo: MovimientoTipo.parse(tipo),
      categoria: categoriaJson is Map
          ? CategoriaDto.fromJson(
              categoriaJson.map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ).toDomain()
          : null,
      partidaId: json['partidaId'] as int?,
    );
  }

  final int id;
  final Decimal monto;
  final String descripcion;
  final DateTime fecha;
  final MovimientoTipo tipo;
  final Categoria? categoria;
  final int? partidaId;

  Movimiento toDomain() => Movimiento(
    id: id,
    monto: monto,
    descripcion: descripcion,
    fecha: fecha,
    tipo: tipo,
    categoria: categoria,
    partidaId: partidaId,
  );
}

/// `PageResponseDTO<MovimientoResponseDTO>`.
class PaginaMovimientosDto {
  const PaginaMovimientosDto({
    required this.content,
    required this.currentPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginaMovimientosDto.fromJson(Map<String, dynamic> json) {
    final Object? content = json['content'];
    final Object? currentPage = json['currentPage'];
    final Object? totalItems = json['totalItems'];
    final Object? totalPages = json['totalPages'];
    if (content is! List ||
        currentPage is! int ||
        totalItems is! int ||
        totalPages is! int) {
      throw const FormatException('Página de movimientos incompleta.');
    }
    return PaginaMovimientosDto(
      content: content
          .map(
            (Object? item) => MovimientoDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ).toDomain(),
          )
          .toList(growable: false),
      currentPage: currentPage,
      totalItems: totalItems,
      totalPages: totalPages,
    );
  }

  final List<Movimiento> content;
  final int currentPage;
  final int totalItems;
  final int totalPages;

  PaginaMovimientos toDomain() => PaginaMovimientos(
    content: content,
    currentPage: currentPage,
    totalItems: totalItems,
    totalPages: totalPages,
  );
}

/// Cuerpo de `POST /movimientos`.
class MovimientoRegistroDto {
  const MovimientoRegistroDto({
    required this.monto,
    required this.descripcion,
    required this.tipo,
    this.categoriaId,
    this.partidaId,
  });

  final Decimal monto;
  final String descripcion;
  final MovimientoTipo tipo;
  final int? categoriaId;
  final int? partidaId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'monto': moneyToJson(monto),
      'descripcion': descripcion,
      'tipoMovimiento': tipo.codigo,
      'categoriaId': ?categoriaId,
      'partidaId': ?partidaId,
    };
  }
}

/// Cuerpo de `PUT /movimientos/{id}` (edición parcial; los nulos no se envían).
///
/// El contrato **no** acepta `tipoMovimiento`: el signo lo impone el tipo
/// actual del movimiento.
class MovimientoEdicionDto {
  const MovimientoEdicionDto({
    this.monto,
    this.descripcion,
    this.categoriaId,
    this.partidaId,
    this.desvincularPartida = false,
  });

  final Decimal? monto;
  final String? descripcion;
  final int? categoriaId;
  final int? partidaId;
  final bool desvincularPartida;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (monto != null) 'monto': moneyToJson(monto!),
      if (descripcion != null) 'descripcion': descripcion,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (partidaId != null) 'partidaId': partidaId,
      if (desvincularPartida) 'desvincularPartida': true,
    };
  }
}

/// `SugerenciaCategoriaDTO`.
class SugerenciaCategoriaDto {
  const SugerenciaCategoriaDto({
    required this.categoriaId,
    required this.codigo,
    required this.nombre,
    required this.confianza,
    required this.motivo,
  });

  factory SugerenciaCategoriaDto.fromJson(Map<String, dynamic> json) {
    final Object? categoriaId = json['categoriaId'];
    final Object? codigo = json['codigo'];
    final Object? nombre = json['nombre'];
    final Object? motivo = json['motivo'];
    if (categoriaId is! int ||
        codigo is! String ||
        nombre is! String ||
        motivo is! String) {
      throw const FormatException('Sugerencia incompleta.');
    }
    return SugerenciaCategoriaDto(
      categoriaId: categoriaId,
      codigo: codigo,
      nombre: nombre,
      confianza: moneyFromJson(json['confianza']),
      motivo: motivo,
    );
  }

  final int categoriaId;
  final String codigo;
  final String nombre;
  final Decimal confianza;
  final String motivo;

  SugerenciaCategoria toDomain() => SugerenciaCategoria(
    categoriaId: categoriaId,
    codigo: codigo,
    nombre: nombre,
    confianza: confianza,
    motivo: motivo,
  );
}

/// `SugerenciaCategoriaResponseDTO`.
class SugerenciaRespuestaDto {
  const SugerenciaRespuestaDto({
    required this.texto,
    required this.sugerencias,
    required this.ambigua,
  });

  factory SugerenciaRespuestaDto.fromJson(Map<String, dynamic> json) {
    final Object? texto = json['texto'];
    final Object? sugerencias = json['sugerencias'];
    final Object? ambigua = json['ambigua'];
    if (texto is! String || sugerencias is! List || ambigua is! bool) {
      throw const FormatException('Respuesta de sugerencia incompleta.');
    }
    return SugerenciaRespuestaDto(
      texto: texto,
      sugerencias: sugerencias
          .map(
            (Object? item) => SugerenciaCategoriaDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ).toDomain(),
          )
          .toList(growable: false),
      ambigua: ambigua,
    );
  }

  final String texto;
  final List<SugerenciaCategoria> sugerencias;
  final bool ambigua;

  RespuestaSugerencia toDomain() => RespuestaSugerencia(
    texto: texto,
    sugerencias: sugerencias,
    ambigua: ambigua,
  );
}
