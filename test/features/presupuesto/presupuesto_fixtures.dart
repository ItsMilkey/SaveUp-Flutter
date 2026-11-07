import 'package:decimal/decimal.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/movimientos/domain/categoria.dart';
import 'package:saveup_app/features/movimientos/domain/categorias_repository.dart';
import 'package:saveup_app/features/movimientos/domain/sugerencia_categoria.dart';
import 'package:saveup_app/features/presupuesto/domain/categorias_preferencias_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/ejecucion_presupuesto.dart';
import 'package:saveup_app/features/presupuesto/domain/limite_categoria.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/preferencia_categoria.dart';
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

EjecucionPresupuesto ejecucionDePrueba({
  String ingresos = '1000000',
  String pn = '500000',
  String gn = '400000',
  String pd = '300000',
  String gd = '250000',
  String pa = '200000',
  String ar = '150000',
  bool automatizar = false,
}) {
  return EjecucionPresupuesto(
    presupuestoNecesidades: Decimal.parse(pn),
    gastoNecesidades: Decimal.parse(gn),
    presupuestoDeseos: Decimal.parse(pd),
    gastoDeseos: Decimal.parse(gd),
    presupuestoAhorro: Decimal.parse(pa),
    ahorroRealizado: Decimal.parse(ar),
    totalIngresos: Decimal.parse(ingresos),
    porcentajeNecesidadesConfigurado: Decimal.fromInt(50),
    porcentajeDeseosConfigurado: Decimal.fromInt(30),
    porcentajeAhorroConfigurado: Decimal.fromInt(20),
    automatizarAhorroEnMetas: automatizar,
  );
}

HistorialPresupuesto historialDePrueba({
  int anio = 2026,
  int mes = 10,
  EjecucionPresupuesto? ejecucion,
}) {
  return HistorialPresupuesto(
    anio: anio,
    mes: mes,
    ejecucion: ejecucion ?? ejecucionDePrueba(),
  );
}

LimiteCategoria limiteDePrueba({
  int categoriaId = 2,
  String categoria = 'Alimentación Básica',
  String monto = '100000',
}) {
  return LimiteCategoria(
    categoriaId: categoriaId,
    categoria: categoria,
    limiteMensual: Decimal.parse(monto),
  );
}

EjecucionCategoria ejecucionCategoriaDePrueba({
  int categoriaId = 2,
  String categoria = 'Alimentación Básica',
  String limite = '100000',
  String gastado = '60000',
  String porcentajeUsado = '60',
  EstadoEjecucion estado = EstadoEjecucion.bajoElPlan,
}) {
  return EjecucionCategoria(
    categoriaId: categoriaId,
    categoria: categoria,
    limite: Decimal.parse(limite),
    gastado: Decimal.parse(gastado),
    porcentajeUsado: Decimal.parse(porcentajeUsado),
    estado: estado,
  );
}

Categoria categoriaDePrueba({
  int id = 2,
  String codigo = 'ALIMENTACION_BASE',
  String nombre = 'Alimentación Básica',
  String? tipo = 'NECESIDAD',
}) {
  return Categoria(
    id: id,
    codigo: codigo,
    nombre: nombre,
    tipoPresupuesto: tipo,
  );
}

PreferenciaCategoria preferenciaDePrueba({
  int id = 2,
  String codigo = 'ALIMENTACION_BASE',
  String nombre = 'Alimentación Básica',
  TipoPresupuesto porDefecto = TipoPresupuesto.necesidad,
  TipoPresupuesto? preferido,
  TipoPresupuesto? efectivo,
}) {
  return PreferenciaCategoria(
    id: id,
    nombre: nombre,
    codigo: codigo,
    tipoPorDefecto: porDefecto,
    tipoEfectivo: efectivo ?? preferido ?? porDefecto,
    tipoPreferido: preferido,
  );
}

/// Repositorio falso de presupuesto para controlador y pantalla.
class FakePresupuestoRepository implements PresupuestoRepository {
  FakePresupuestoRepository({
    this.config,
    this.sugerencia,
    this.errorConfig,
    this.errorGuardar,
    EjecucionPresupuesto? ejecucion,
    this.errorEjecucion,
    List<HistorialPresupuesto>? historial,
    this.errorHistorial,
    List<LimiteCategoria>? limites,
    this.errorLimites,
    List<EjecucionCategoria>? ejecucionCategorias,
    this.errorEjecucionCategorias,
    this.errorGuardarLimites,
  }) : ejecucionRespuesta = ejecucion ?? ejecucionDePrueba(),
       historialRespuesta = historial ?? const <HistorialPresupuesto>[],
       limitesRespuesta = limites ?? const <LimiteCategoria>[],
       ejecucionCategoriasRespuesta =
           ejecucionCategorias ?? const <EjecucionCategoria>[];

  ConfiguracionPresupuesto? config;
  SugerenciaRegla? sugerencia;
  AppFailure? errorConfig;
  AppFailure? errorGuardar;

  EjecucionPresupuesto ejecucionRespuesta;
  AppFailure? errorEjecucion;
  List<HistorialPresupuesto> historialRespuesta;
  AppFailure? errorHistorial;
  List<LimiteCategoria> limitesRespuesta;
  AppFailure? errorLimites;
  List<EjecucionCategoria> ejecucionCategoriasRespuesta;
  AppFailure? errorEjecucionCategorias;
  AppFailure? errorGuardarLimites;

  PorcentajesRegla? guardados;
  bool? activoGuardado;
  bool? automatizarGuardado;
  int intentosGuardar = 0;

  int? monthSolicitado;
  int? yearSolicitado;
  String? desdeSolicitado;
  String? hastaSolicitado;
  List<LimiteCategoriaItem>? limitesEnviados;
  int llamadasEjecucion = 0;
  int llamadasEjecucionCategorias = 0;

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
    return sugerencia ?? sugerenciaDePrueba(motivo: 'DATOS_INSUFICIENTES');
  }

  @override
  Future<EjecucionPresupuesto> ejecucion({int? month, int? year}) async {
    llamadasEjecucion += 1;
    monthSolicitado = month;
    yearSolicitado = year;
    if (errorEjecucion != null) {
      throw errorEjecucion!;
    }
    return ejecucionRespuesta;
  }

  @override
  Future<List<HistorialPresupuesto>> historial({
    required String desde,
    required String hasta,
  }) async {
    desdeSolicitado = desde;
    hastaSolicitado = hasta;
    if (errorHistorial != null) {
      throw errorHistorial!;
    }
    return historialRespuesta;
  }

  @override
  Future<List<LimiteCategoria>> listarLimites() async {
    if (errorLimites != null) {
      throw errorLimites!;
    }
    return limitesRespuesta;
  }

  @override
  Future<List<LimiteCategoria>> reemplazarLimites(
    List<LimiteCategoriaItem> categorias,
  ) async {
    limitesEnviados = categorias;
    if (errorGuardarLimites != null) {
      throw errorGuardarLimites!;
    }
    final List<LimiteCategoria> resultado = <LimiteCategoria>[
      for (final LimiteCategoriaItem item in categorias)
        LimiteCategoria(
          categoriaId: item.categoriaId,
          categoria: _nombreDe(item.categoriaId),
          limiteMensual: item.limiteMensual,
        ),
    ];
    limitesRespuesta = resultado;
    return resultado;
  }

  @override
  Future<List<EjecucionCategoria>> ejecucionCategorias({
    int? month,
    int? year,
  }) async {
    llamadasEjecucionCategorias += 1;
    if (errorEjecucionCategorias != null) {
      throw errorEjecucionCategorias!;
    }
    return ejecucionCategoriasRespuesta;
  }

  String _nombreDe(int categoriaId) {
    for (final LimiteCategoria limite in limitesRespuesta) {
      if (limite.categoriaId == categoriaId) {
        return limite.categoria;
      }
    }
    return 'Categoría $categoriaId';
  }
}

/// Catálogo falso de categorías.
class FakeCategoriasRepository implements CategoriasRepository {
  FakeCategoriasRepository({List<Categoria>? categorias, this.error})
    : categorias = categorias ?? <Categoria>[
        categoriaDePrueba(),
        categoriaDePrueba(id: 3, codigo: 'OCIO', nombre: 'Ocio', tipo: 'DESEO'),
      ];

  List<Categoria> categorias;
  AppFailure? error;

  @override
  Future<List<Categoria>> listar() async {
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

/// Preferencias falsas de tipo de categoría.
class FakePreferenciasRepository implements CategoriasPreferenciasRepository {
  FakePreferenciasRepository({
    List<PreferenciaCategoria>? preferencias,
    this.errorListar,
    this.errorEstablecer,
    this.errorQuitar,
  }) : preferencias = preferencias ?? <PreferenciaCategoria>[
         preferenciaDePrueba(),
         preferenciaDePrueba(
           id: 3,
           codigo: 'OCIO',
           nombre: 'Ocio',
           porDefecto: TipoPresupuesto.deseo,
         ),
         preferenciaDePrueba(
           id: 8,
           codigo: 'AHORRO',
           nombre: 'Ahorro',
           porDefecto: TipoPresupuesto.ahorro,
         ),
       ];

  List<PreferenciaCategoria> preferencias;
  AppFailure? errorListar;
  AppFailure? errorEstablecer;
  AppFailure? errorQuitar;

  int? ultimoIdEstablecido;
  TipoPresupuesto? ultimoTipoEstablecido;
  int? ultimoIdQuitado;

  @override
  Future<List<PreferenciaCategoria>> listar() async {
    if (errorListar != null) {
      throw errorListar!;
    }
    return preferencias;
  }

  @override
  Future<PreferenciaCategoria> establecerTipoPreferido(
    int categoriaId,
    TipoPresupuesto tipo,
  ) async {
    ultimoIdEstablecido = categoriaId;
    ultimoTipoEstablecido = tipo;
    if (errorEstablecer != null) {
      throw errorEstablecer!;
    }
    final PreferenciaCategoria actualizada = _reemplazar(
      categoriaId,
      tipoPreferido: tipo,
      tipoEfectivo: tipo,
    );
    return actualizada;
  }

  @override
  Future<void> quitarTipoPreferido(int categoriaId) async {
    ultimoIdQuitado = categoriaId;
    if (errorQuitar != null) {
      throw errorQuitar!;
    }
    _reemplazar(categoriaId);
  }

  PreferenciaCategoria _reemplazar(
    int categoriaId, {
    TipoPresupuesto? tipoPreferido,
    TipoPresupuesto? tipoEfectivo,
  }) {
    final PreferenciaCategoria actual = preferencias.firstWhere(
      (PreferenciaCategoria item) => item.id == categoriaId,
    );
    final PreferenciaCategoria actualizada = PreferenciaCategoria(
      id: actual.id,
      nombre: actual.nombre,
      codigo: actual.codigo,
      iconId: actual.iconId,
      colorHex: actual.colorHex,
      tipoPorDefecto: actual.tipoPorDefecto,
      tipoEfectivo: tipoEfectivo ?? actual.tipoPorDefecto,
      tipoPreferido: tipoPreferido,
    );
    preferencias = <PreferenciaCategoria>[
      for (final PreferenciaCategoria item in preferencias)
        if (item.id == categoriaId) actualizada else item,
    ];
    return actualizada;
  }
}
