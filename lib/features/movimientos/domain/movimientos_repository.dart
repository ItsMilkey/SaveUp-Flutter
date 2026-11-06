import 'package:decimal/decimal.dart';

import 'movimiento_filtro.dart';
import 'movimiento_tipo.dart';

/// Movimientos del usuario (listado paginado y alta mínima).
abstract interface class MovimientosRepository {
  /// `GET /movimientos/paginados/me` (`page` base 0).
  Future<PaginaMovimientos> pagina({
    required MovimientoFiltro filtro,
    required int page,
    int size = 50,
  });

  /// `POST /movimientos` (el signo lo impone el tipo en el backend).
  Future<void> registrar({
    required Decimal monto,
    required String descripcion,
    required MovimientoTipo tipo,
    int? categoriaId,
  });
}
