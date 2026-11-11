import 'package:decimal/decimal.dart';

import 'movimiento.dart';
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
  ///
  /// `partidaId` solo aplica a `GASTO_GENERAL`/`PAGO_DEUDA` y debe pertenecer
  /// al mes del movimiento; el backend deriva la categoría de la partida.
  Future<void> registrar({
    required Decimal monto,
    required String descripcion,
    required MovimientoTipo tipo,
    int? categoriaId,
    int? partidaId,
  });

  /// `PUT /movimientos/{id}`: edición **parcial**.
  ///
  /// Los `null` significan "no enviado" y conservan el valor actual. El tipo
  /// **no es editable** (el contrato no lo incluye: el signo lo impone el tipo
  /// actual). Devuelve el movimiento actualizado del backend.
  Future<Movimiento> editar({
    required int id,
    Decimal? monto,
    String? descripcion,
    int? categoriaId,
    int? partidaId,
    bool desvincularPartida = false,
  });

  /// `DELETE /movimientos/{id}` → `204` sin cuerpo.
  Future<void> eliminar(int id);
}
