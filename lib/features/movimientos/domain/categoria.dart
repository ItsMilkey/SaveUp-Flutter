/// Categoría del catálogo del backend (`CategoriaDTO`).
class Categoria {
  const Categoria({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.iconId,
    this.colorHex,
    this.tipoPresupuesto,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String? iconId;
  final String? colorHex;
  final String? tipoPresupuesto;
}
