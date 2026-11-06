import 'categoria.dart';
import 'sugerencia_categoria.dart';

/// Catálogo y sugeridor de categorías.
abstract interface class CategoriasRepository {
  /// `GET /categorias` (catálogo completo).
  Future<List<Categoria>> listar();

  /// `GET /categorias/sugerencia` (texto obligatorio, contexto por defecto
  /// `GASTO`). El servidor tolera menos de 3 caracteres devolviendo lista
  /// vacía; nunca asigna en silencio.
  Future<RespuestaSugerencia> sugerir({
    required String texto,
    ContextoSugerencia contexto = ContextoSugerencia.gasto,
  });
}
