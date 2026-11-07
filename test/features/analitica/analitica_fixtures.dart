import 'package:decimal/decimal.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/movimientos/domain/categoria.dart';
import 'package:saveup_app/features/movimientos/domain/categorias_repository.dart';
import 'package:saveup_app/features/movimientos/domain/sugerencia_categoria.dart';
import 'package:saveup_app/features/presupuesto/domain/ejecucion_presupuesto.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_mensual.dart';

Decimal _d(String value) => Decimal.parse(value);

ResumenCalculado resumenAnalitica({
  String ingresos = '0',
  String gastos = '0',
  String ahorro = '0',
  String disponible = '0',
}) {
  return ResumenCalculado(
    planificadoTotal: Decimal.zero,
    remanenteLibre: null,
    margenSeguridadPct: null,
    excedeIngreso: false,
    ingresoReal: _d(ingresos),
    gastoRealTotal: _d(gastos),
    disponibleReal: _d(disponible),
    ahorroRegistrado: _d(ahorro),
    sinPlanificar: SinPlanificarCalculado(
      monto: Decimal.zero,
      movimientos: 0,
      porMotivo: const <MotivoCalculado>[],
    ),
  );
}

CategoriaResultado categoriaResultado(
  String codigo,
  String real, {
  TipoPresupuesto tipo = TipoPresupuesto.necesidad,
  int categoriaId = 0,
}) {
  return CategoriaResultado(
    categoriaId: categoriaId,
    codigo: codigo,
    tipo: tipo,
    planificado: Decimal.zero,
    real: _d(real),
    diferencia: Decimal.zero,
    porcentajeUsado: null,
    estado: EstadoEjecucion.bajoElPlan,
  );
}

RepartoTipoResultado tipoResultado(
  TipoPresupuesto tipo,
  String real,
) {
  return RepartoTipoResultado(
    tipo: tipo,
    planificado: Decimal.zero,
    porcentajeDelIngreso: null,
    real: _d(real),
    porcentajeRealDelIngresoReal: null,
    diferenciaPuntos: null,
  );
}

PlanMensual planAnalitica({
  String mes = '2026-11',
  String ingresos = '0',
  String gastos = '0',
  String ahorro = '0',
  String disponible = '0',
  List<CategoriaResultado> categorias = const <CategoriaResultado>[],
  List<RepartoTipoResultado> tipos = const <RepartoTipoResultado>[],
}) {
  return PlanMensual(
    mes: mes,
    existe: false,
    ingresoReferencia: null,
    calculo: PlanCalculado(
      resumen: resumenAnalitica(
        ingresos: ingresos,
        gastos: gastos,
        ahorro: ahorro,
        disponible: disponible,
      ),
      partidas: const <PartidaResultado>[],
      porCategoria: categorias,
      repartoPorTipo: tipos,
      guia: null,
      grupos: const <GrupoResultado>[],
    ),
    partidas: const <PartidaPlan>[],
    grupos: const <GrupoResultado>[],
    avisos: const <AvisoPlan>[],
  );
}

HistorialPresupuesto historialAnalitica({
  int anio = 2026,
  int mes = 11,
  String ingresos = '0',
  String gastoNecesidades = '0',
  String gastoDeseos = '0',
  String ahorro = '0',
}) {
  return HistorialPresupuesto(
    anio: anio,
    mes: mes,
    ejecucion: EjecucionPresupuesto(
      presupuestoNecesidades: Decimal.zero,
      gastoNecesidades: _d(gastoNecesidades),
      presupuestoDeseos: Decimal.zero,
      gastoDeseos: _d(gastoDeseos),
      presupuestoAhorro: Decimal.zero,
      ahorroRealizado: _d(ahorro),
      totalIngresos: _d(ingresos),
      porcentajeNecesidadesConfigurado: Decimal.zero,
      porcentajeDeseosConfigurado: Decimal.zero,
      porcentajeAhorroConfigurado: Decimal.zero,
      automatizarAhorroEnMetas: false,
    ),
  );
}

Categoria categoriaAnalitica({
  int id = 1,
  String codigo = 'ALIMENTACION_BASE',
  String nombre = 'Alimentación Básica',
  String? colorHex = '#FFAA00',
}) {
  return Categoria(
    id: id,
    codigo: codigo,
    nombre: nombre,
    colorHex: colorHex,
    tipoPresupuesto: 'NECESIDAD',
  );
}

/// Plan falso: solo `obtener` se usa en analítica.
class FakePlanAnaliticaRepository implements PlanMensualRepository {
  FakePlanAnaliticaRepository({this.plan, this.error});

  PlanMensual? plan;
  AppFailure? error;
  String? mesSolicitado;
  bool? incluirReferenciasSolicitado;

  @override
  Future<PlanMensual> obtener(
    String mes, {
    bool incluirReferencias = false,
  }) async {
    mesSolicitado = mes;
    incluirReferenciasSolicitado = incluirReferencias;
    if (error != null) {
      throw error!;
    }
    return plan ?? planAnalitica(mes: mes);
  }

  @override
  Future<PlanMensual> actualizarMontos(
    String mes,
    List<CambioMonto> cambios,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PlanMensual> copiarDesde(String mes, String mesOrigen) {
    throw UnimplementedError();
  }

  @override
  Future<List<GrupoPlan>> listarGrupos() {
    throw UnimplementedError();
  }

  @override
  Future<GrupoPlan> crearGrupo({required String nombre, int? orden}) {
    throw UnimplementedError();
  }

  @override
  Future<GrupoPlan> editarGrupo(int id, {String? nombre, int? orden}) {
    throw UnimplementedError();
  }

  @override
  Future<void> eliminarGrupo(int id) {
    throw UnimplementedError();
  }

  @override
  Future<PlanMensual> actualizarIngreso(String mes, Decimal? monto) {
    throw UnimplementedError();
  }

  @override
  Future<PlanMensual> crearPartida(
    String mes, {
    required String nombre,
    int? categoriaId,
    Decimal? montoPlanificado,
    int? grupoId,
    int? deudaId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanMensual> editarPartida(
    String mes,
    int id, {
    String? nombre,
    int? categoriaId,
    int? grupoId,
    bool quitarGrupo = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> eliminarPartida(String mes, int id) {
    throw UnimplementedError();
  }
}

class FakeCategoriasAnaliticaRepository implements CategoriasRepository {
  FakeCategoriasAnaliticaRepository({
    List<Categoria>? categorias,
    this.error,
  }) : categorias = categorias ?? const <Categoria>[];

  List<Categoria> categorias;
  AppFailure? error;
  int llamadas = 0;

  @override
  Future<List<Categoria>> listar() async {
    llamadas += 1;
    if (error != null) {
      throw error!;
    }
    return categorias;
  }

  @override
  Future<RespuestaSugerencia> sugerir({
    required String texto,
    ContextoSugerencia contexto = ContextoSugerencia.gasto,
  }) {
    throw UnimplementedError();
  }
}
