import 'package:decimal/decimal.dart';

/// Sugerencia de categoría devuelta por `GET /categorias/sugerencia`.
class SugerenciaCategoria {
  const SugerenciaCategoria({
    required this.categoriaId,
    required this.codigo,
    required this.nombre,
    required this.confianza,
    required this.motivo,
  });

  final int categoriaId;
  final String codigo;
  final String nombre;

  /// Confianza entre 0.00 y 1.00 (escala 2, `Decimal`).
  final Decimal confianza;

  /// `PALABRA_CLAVE`, `PREFIJO`, `APROXIMADA` o `HISTORIAL`.
  final String motivo;
}

/// Respuesta completa del sugeridor.
///
/// [texto] es el **eco exacto** del texto enviado (incluidos espacios y
/// mayúsculas): la app lo compara con el valor actual del formulario para
/// descartar respuestas atrasadas.
class RespuestaSugerencia {
  const RespuestaSugerencia({
    required this.texto,
    required this.sugerencias,
    required this.ambigua,
  });

  final String texto;
  final List<SugerenciaCategoria> sugerencias;

  /// `true`: hay al menos 2 sugerencias y la diferencia entre la primera y la
  /// segunda es menor que 0.10; hay que pedir confirmación visible.
  final bool ambigua;
}

/// Contexto del sugeridor (por defecto `GASTO` en el backend).
enum ContextoSugerencia {
  gasto('GASTO'),
  ingreso('INGRESO');

  const ContextoSugerencia(this.codigo);

  final String codigo;
}
