import 'package:decimal/decimal.dart';

/// Límite mensual configurado para una categoría (`PresupuestoCategoriaDTO`).
class LimiteCategoria {
  const LimiteCategoria({
    required this.categoriaId,
    required this.categoria,
    required this.limiteMensual,
  });

  final int categoriaId;
  final String categoria;
  final Decimal limiteMensual;
}

/// Item del `PUT /presupuestos/categorias/me` (conjunto completo).
class LimiteCategoriaItem {
  const LimiteCategoriaItem({
    required this.categoriaId,
    required this.limiteMensual,
  });

  final int categoriaId;
  final Decimal limiteMensual;
}
