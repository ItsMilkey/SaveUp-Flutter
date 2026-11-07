import 'ejecucion_presupuesto.dart';
import 'limite_categoria.dart';
import 'regla_presupuestaria.dart';

/// Contrato de datos del presupuesto (regla, ejecución, historial y límites).
abstract interface class PresupuestoRepository {
  /// `GET /presupuestos/me`.
  Future<ConfiguracionPresupuesto> obtenerConfiguracion();

  /// `POST /presupuestos/me`.
  Future<ConfiguracionPresupuesto> guardarConfiguracion({
    required PorcentajesRegla porcentajes,
    bool activo = true,
    bool automatizarAhorroEnMetas = false,
  });

  /// `GET /presupuestos/sugerencia-regla`.
  Future<SugerenciaRegla> sugerenciaRegla();

  /// `GET /presupuestos/ejecucion/me?month&year`.
  Future<EjecucionPresupuesto> ejecucion({int? month, int? year});

  /// `GET /presupuestos/historial/me?desde&hasta` (`yyyy-MM`, obligatorios).
  Future<List<HistorialPresupuesto>> historial({
    required String desde,
    required String hasta,
  });

  /// `GET /presupuestos/categorias/me`.
  Future<List<LimiteCategoria>> listarLimites();

  /// `PUT /presupuestos/categorias/me` (reemplaza el conjunto completo).
  Future<List<LimiteCategoria>> reemplazarLimites(
    List<LimiteCategoriaItem> categorias,
  );

  /// `GET /presupuestos/categorias/ejecucion/me?month&year`.
  Future<List<EjecucionCategoria>> ejecucionCategorias({
    int? month,
    int? year,
  });
}
