import 'package:decimal/decimal.dart';

import '../../../core/money/money_json.dart';
import '../../../core/time/calendar_date.dart';
import 'movimiento.dart';
import 'movimiento_tipo.dart';

/// Filtros de `GET /movimientos/paginados/me`.
///
/// El contrato acepta además `categoriaId`, `partidaId`, `q` y montos; en
/// este corte la UI solo expone rango de fechas y tipo, pero el modelo soporta
/// todos para no rehacerlo en F3b.
class MovimientoFiltro {
  const MovimientoFiltro({
    this.desde,
    this.hasta,
    this.tipo,
    this.categoriaId,
    this.partidaId,
    this.q,
    this.montoMin,
    this.montoMax,
  });

  /// Fecha inicial inclusiva (`yyyy-MM-dd`).
  final CalendarDate? desde;

  /// Fecha final inclusiva (`yyyy-MM-dd`).
  final CalendarDate? hasta;

  final MovimientoTipo? tipo;
  final int? categoriaId;
  final int? partidaId;

  /// Texto a buscar en la descripción (sin distinguir mayúsculas).
  final String? q;

  final Decimal? montoMin;
  final Decimal? montoMax;

  bool get vacio =>
      desde == null &&
      hasta == null &&
      tipo == null &&
      categoriaId == null &&
      partidaId == null &&
      (q == null || q!.trim().isEmpty) &&
      montoMin == null &&
      montoMax == null;

  /// Parámetros de query: omite los nulos/vacíos y serializa fechas.
  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = <String, dynamic>{};
    if (desde != null) {
      params['desde'] = desde!.toJson();
    }
    if (hasta != null) {
      params['hasta'] = hasta!.toJson();
    }
    if (tipo != null) {
      params['tipoMovimiento'] = tipo!.codigo;
    }
    if (categoriaId != null) {
      params['categoriaId'] = categoriaId;
    }
    if (partidaId != null) {
      params['partidaId'] = partidaId;
    }
    if (q != null && q!.trim().isNotEmpty) {
      params['q'] = q!.trim();
    }
    if (montoMin != null) {
      params['montoMin'] = moneyToJson(montoMin!);
    }
    if (montoMax != null) {
      params['montoMax'] = moneyToJson(montoMax!);
    }
    return params;
  }

  MovimientoFiltro copyWith({
    CalendarDate? desde,
    CalendarDate? hasta,
    MovimientoTipo? tipo,
    bool limpiarTipo = false,
    bool limpiarFechas = false,
  }) {
    return MovimientoFiltro(
      desde: limpiarFechas ? null : (desde ?? this.desde),
      hasta: limpiarFechas ? null : (hasta ?? this.hasta),
      tipo: limpiarTipo ? null : (tipo ?? this.tipo),
      categoriaId: categoriaId,
      partidaId: partidaId,
      q: q,
      montoMin: montoMin,
      montoMax: montoMax,
    );
  }
}

/// Página de movimientos del backend (`PageResponseDTO`).
class PaginaMovimientos {
  const PaginaMovimientos({
    required this.content,
    required this.currentPage,
    required this.totalItems,
    required this.totalPages,
  });

  final List<Movimiento> content;

  /// Número de página (base 0).
  final int currentPage;
  final int totalItems;
  final int totalPages;

  bool get esUltima => currentPage + 1 >= totalPages;
}
