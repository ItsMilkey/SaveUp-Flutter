import 'plan_calculo.dart';
import 'preferencia_categoria.dart';

/// Contrato de preferencias de tipo de categoría.
abstract interface class CategoriasPreferenciasRepository {
  /// `GET /categorias/preferencias`.
  Future<List<PreferenciaCategoria>> listar();

  /// `PUT /categorias/{id}/tipo-preferido` (solo NECESIDAD o DESEO).
  Future<PreferenciaCategoria> establecerTipoPreferido(
    int categoriaId,
    TipoPresupuesto tipo,
  );

  /// `DELETE /categorias/{id}/tipo-preferido` (204, idempotente).
  Future<void> quitarTipoPreferido(int categoriaId);
}
