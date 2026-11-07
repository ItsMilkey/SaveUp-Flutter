import 'plan_calculo.dart';

/// Categoría con su tipo por defecto, preferido y efectivo
/// (`PreferenciaCategoriaDTO`).
class PreferenciaCategoria {
  const PreferenciaCategoria({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.tipoPorDefecto,
    required this.tipoEfectivo,
    this.iconId,
    this.colorHex,
    this.tipoPreferido,
  });

  final int id;
  final String nombre;
  final String codigo;
  final String? iconId;
  final String? colorHex;
  final TipoPresupuesto tipoPorDefecto;
  final TipoPresupuesto tipoEfectivo;

  /// `null` si el usuario no definió preferencia.
  final TipoPresupuesto? tipoPreferido;

  /// Solo se puede reclasificar si el tipo por defecto es NECESIDAD o DESEO.
  bool get reclasificable =>
      tipoPorDefecto == TipoPresupuesto.necesidad ||
      tipoPorDefecto == TipoPresupuesto.deseo;
}
