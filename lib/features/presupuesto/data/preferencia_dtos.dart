/// DTOs de preferencias de tipo de categoría.
library;

import '../domain/plan_calculo.dart';
import '../domain/preferencia_categoria.dart';

/// `PreferenciaCategoriaDTO`.
class PreferenciaCategoriaDto {
  const PreferenciaCategoriaDto._();

  static PreferenciaCategoria fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? nombre = json['nombre'];
    final Object? codigo = json['codigo'];
    final Object? porDefecto = json['tipoPorDefecto'];
    final Object? efectivo = json['tipoEfectivo'];
    if (id is! int ||
        nombre is! String ||
        codigo is! String ||
        porDefecto is! String ||
        efectivo is! String) {
      throw const FormatException('Preferencia de categoría incompleta.');
    }
    final Object? preferido = json['tipoPreferido'];
    return PreferenciaCategoria(
      id: id,
      nombre: nombre,
      codigo: codigo,
      iconId: json['iconId'] as String?,
      colorHex: json['colorHex'] as String?,
      tipoPorDefecto: TipoPresupuesto.parse(porDefecto),
      tipoEfectivo: TipoPresupuesto.parse(efectivo),
      tipoPreferido: preferido is String
          ? TipoPresupuesto.parse(preferido)
          : null,
    );
  }
}

/// Cuerpo de `PUT /categorias/{id}/tipo-preferido` (`tipo` obligatorio).
class TipoPreferidoRequestDto {
  const TipoPreferidoRequestDto({required this.tipo});

  final TipoPresupuesto tipo;

  Map<String, Object?> toJson() => <String, Object?>{'tipo': tipo.codigo};
}
