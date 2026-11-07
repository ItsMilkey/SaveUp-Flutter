import 'package:decimal/decimal.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/presupuesto/domain/ejecucion_presupuesto.dart';
import 'package:saveup_app/features/presupuesto/domain/limite_categoria.dart';
import 'package:saveup_app/features/presupuesto/domain/presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/regla_presupuestaria.dart';

PorcentajesRegla porcentajes({
  String necesidades = '50',
  String deseos = '30',
  String ahorro = '20',
}) {
  return PorcentajesRegla(
    necesidades: Decimal.parse(necesidades),
    deseos: Decimal.parse(deseos),
    ahorro: Decimal.parse(ahorro),
  );
}

ConfiguracionPresupuesto configuracion({
  PorcentajesRegla? valores,
  bool activo = true,
  bool automatizar = false,
}) {
  return ConfiguracionPresupuesto(
    id: 1,
    usuarioRut: '12345678-5',
    porcentajes: valores ?? porcentajes(),
    activo: activo,
    automatizarAhorroEnMetas: automatizar,
  );
}

SugerenciaRegla sugerenciaDePrueba({
  PorcentajesRegla? propuesta,
  String? motivo,
  bool gastoSuperaIngreso = false,
}) {
  return SugerenciaRegla(
    actual: porcentajes(),
    sugerencia: propuesta,
    mesesAnalizados: const <String>['2026-09', '2026-10'],
    gastoSuperaIngreso: gastoSuperaIngreso,
    igualALaGuia: false,
    motivo: motivo,
  );
}

/// Repositorio falso de presupuesto para controlador y pantalla.
class FakePresupuestoRepository implements PresupuestoRepository {
  FakePresupuestoRepository({
    this.config,
    this.sugerencia,
    this.errorConfig,
    this.errorGuardar,
  });

  ConfiguracionPresupuesto? config;
  SugerenciaRegla? sugerencia;
  AppFailure? errorConfig;
  AppFailure? errorGuardar;

  PorcentajesRegla? guardados;
  bool? activoGuardado;
  bool? automatizarGuardado;
  int intentosGuardar = 0;

  @override
  Future<ConfiguracionPresupuesto> obtenerConfiguracion() async {
    if (errorConfig != null) {
      throw errorConfig!;
    }
    if (config == null) {
      throw const NotFoundFailure();
    }
    return config!;
  }

  @override
  Future<ConfiguracionPresupuesto> guardarConfiguracion({
    required PorcentajesRegla porcentajes,
    bool activo = true,
    bool automatizarAhorroEnMetas = false,
  }) async {
    intentosGuardar += 1;
    if (errorGuardar != null) {
      throw errorGuardar!;
    }
    guardados = porcentajes;
    activoGuardado = activo;
    automatizarGuardado = automatizarAhorroEnMetas;
    config = configuracion(
      valores: porcentajes,
      activo: activo,
      automatizar: automatizarAhorroEnMetas,
    );
    return config!;
  }

  @override
  Future<SugerenciaRegla> sugerenciaRegla() async {
    return sugerencia ??
        sugerenciaDePrueba(motivo: 'DATOS_INSUFICIENTES',
        );
  }

  @override
  Future<EjecucionPresupuesto> ejecucion({int? month, int? year}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<HistorialPresupuesto>> historial({
    required String desde,
    required String hasta,
  }) async {
    return const <HistorialPresupuesto>[];
  }

  @override
  Future<List<LimiteCategoria>> listarLimites() async {
    return const <LimiteCategoria>[];
  }

  @override
  Future<List<LimiteCategoria>> reemplazarLimites(
    List<LimiteCategoriaItem> categorias,
  ) async {
    return const <LimiteCategoria>[];
  }

  @override
  Future<List<EjecucionCategoria>> ejecucionCategorias({
    int? month,
    int? year,
  }) async {
    return const <EjecucionCategoria>[];
  }
}
