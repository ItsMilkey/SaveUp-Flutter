import 'package:decimal/decimal.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/time/calendar_date.dart';
import 'package:saveup_app/features/metas/domain/meta_ahorro.dart';
import 'package:saveup_app/features/metas/domain/metas_repository.dart';
import 'package:saveup_app/features/movimientos/presentation/movimientos_controller.dart';

MetaAhorro metaDePrueba({
  int id = 3,
  String nombre = 'Viaje a Japón',
  String? objetivo = '1500000',
  String? fechaLimite = '2027-06-30',
  String actual = '250000',
}) {
  return MetaAhorro(
    id: id,
    nombre: nombre,
    montoObjetivo: objetivo == null ? null : Decimal.parse(objetivo),
    fechaLimite:
        fechaLimite == null ? null : CalendarDate.parse(fechaLimite),
    montoActual: Decimal.parse(actual),
  );
}

MetaAhorro metaPorDefecto({String actual = '50000'}) {
  return metaDePrueba(
    id: 1,
    nombre: 'Ahorros',
    objetivo: null,
    fechaLimite: null,
    actual: actual,
  );
}

/// Repositorio falso de metas para controladores y pantallas.
class FakeMetasRepository implements MetasRepository {
  FakeMetasRepository({
    List<MetaAhorro>? metas,
    this.errorListar,
    this.errorCrear,
    this.errorEditar,
    this.errorEliminar,
    this.errorAbono,
    this.errorRetiro,
  }) : metas = metas ?? <MetaAhorro>[metaDePrueba()];

  List<MetaAhorro> metas;
  AppFailure? errorListar;
  AppFailure? errorCrear;
  AppFailure? errorEditar;
  AppFailure? errorEliminar;
  AppFailure? errorAbono;
  AppFailure? errorRetiro;

  int llamadasListar = 0;
  MetaAhorroDatos? creado;
  int? editadoId;
  MetaAhorroDatos? editado;
  int? eliminadoId;
  int? abonoId;
  Decimal? abonoMonto;
  String? abonoDescripcion;
  int? retiroId;
  Decimal? retiroMonto;
  String? retiroDescripcion;

  int _nextId = 100;

  @override
  Future<List<MetaAhorro>> listar() async {
    llamadasListar += 1;
    if (errorListar != null) {
      throw errorListar!;
    }
    return metas;
  }

  @override
  Future<MetaAhorro> crear(MetaAhorroDatos datos) async {
    creado = datos;
    if (errorCrear != null) {
      throw errorCrear!;
    }
    final MetaAhorro nueva = MetaAhorro(
      id: _nextId++,
      nombre: datos.nombre,
      montoObjetivo: datos.montoObjetivo,
      fechaLimite: datos.fechaLimite,
      montoActual: Decimal.zero,
    );
    metas = <MetaAhorro>[...metas, nueva];
    return nueva;
  }

  @override
  Future<MetaAhorro> editar(int id, MetaAhorroDatos datos) async {
    editadoId = id;
    editado = datos;
    if (errorEditar != null) {
      throw errorEditar!;
    }
    final MetaAhorro actual = _buscar(id);
    final MetaAhorro actualizada = MetaAhorro(
      id: actual.id,
      nombre: datos.nombre,
      montoObjetivo: datos.montoObjetivo,
      fechaLimite: datos.fechaLimite,
      montoActual: actual.montoActual,
    );
    _reemplazar(actualizada);
    return actualizada;
  }

  @override
  Future<void> eliminar(int id) async {
    eliminadoId = id;
    if (errorEliminar != null) {
      throw errorEliminar!;
    }
    metas = <MetaAhorro>[
      for (final MetaAhorro meta in metas)
        if (meta.id != id) meta,
    ];
  }

  @override
  Future<MetaAhorro> abonar(
    int id, {
    required Decimal monto,
    required String descripcion,
  }) async {
    abonoId = id;
    abonoMonto = monto;
    abonoDescripcion = descripcion;
    if (errorAbono != null) {
      throw errorAbono!;
    }
    return _sumar(id, monto);
  }

  @override
  Future<MetaAhorro> retirar(
    int id, {
    required Decimal monto,
    required String descripcion,
  }) async {
    retiroId = id;
    retiroMonto = monto;
    retiroDescripcion = descripcion;
    if (errorRetiro != null) {
      throw errorRetiro!;
    }
    return _sumar(id, Decimal.zero - monto);
  }

  MetaAhorro _sumar(int id, Decimal delta) {
    final MetaAhorro actual = _buscar(id);
    final MetaAhorro actualizada = MetaAhorro(
      id: actual.id,
      nombre: actual.nombre,
      montoObjetivo: actual.montoObjetivo,
      fechaLimite: actual.fechaLimite,
      montoActual: actual.montoActual + delta,
    );
    _reemplazar(actualizada);
    return actualizada;
  }

  MetaAhorro _buscar(int id) =>
      metas.firstWhere((MetaAhorro meta) => meta.id == id);

  void _reemplazar(MetaAhorro actualizada) {
    metas = <MetaAhorro>[
      for (final MetaAhorro meta in metas)
        if (meta.id == actualizada.id) actualizada else meta,
    ];
  }
}

/// Home falso: registra los refrescos sin tocar red.
class FakeMovimientosController extends MovimientosController {
  int refrescos = 0;

  @override
  Future<void> refrescar() async {
    refrescos += 1;
  }
}
