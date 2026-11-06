import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_mensual.dart';
import 'package:saveup_app/features/presupuesto/domain/services/calculadora_plan_dart.dart';

class PartidaSpec {
  const PartidaSpec({
    required this.id,
    required this.nombre,
    required this.categoriaId,
    required this.codigo,
    required this.tipo,
    required this.monto,
    this.grupoId,
    this.deudaId,
  });

  final int id;
  final String nombre;
  final int categoriaId;
  final String codigo;
  final TipoPresupuesto tipo;
  final Decimal monto;
  final int? grupoId;
  final int? deudaId;
}

/// Construye un plan consistente con el motor (sin movimientos reales).
PlanMensual planDePrueba({
  String mes = '2026-11',
  Decimal? ingresoReferencia,
  List<PartidaSpec> partidas = const <PartidaSpec>[],
  List<GrupoCalculo> grupos = const <GrupoCalculo>[],
  GuiaCalculo? guia,
  List<AvisoPlan> avisos = const <AvisoPlan>[],
}) {
  final calculadora = const CalculadoraPlanDart();
  final PlanCalculado calculo = calculadora.calcular(
    ingresoReferencia: ingresoReferencia,
    guia: guia,
    grupos: grupos,
    partidas: <PartidaCalculo>[
      for (final PartidaSpec p in partidas)
        PartidaCalculo(
          id: p.id,
          nombre: p.nombre,
          categoria: CategoriaRef(
            id: p.categoriaId,
            codigo: p.codigo,
            tipo: p.tipo,
          ),
          montoPlanificado: p.monto,
          orden: p.id,
          grupoId: p.grupoId,
          deudaId: p.deudaId,
        ),
    ],
    movimientos: const <MovimientoCalculo>[],
  );

  return PlanMensual(
    mes: mes,
    existe: true,
    ingresoReferencia: ingresoReferencia,
    calculo: calculo,
    partidas: <PartidaPlan>[
      for (int i = 0; i < partidas.length; i++)
        PartidaPlan(
          id: partidas[i].id,
          nombre: partidas[i].nombre,
          categoriaId: partidas[i].categoriaId,
          categoriaCodigo: partidas[i].codigo,
          montoPlanificado: calculo.partidas[i].montoPlanificado,
          real: calculo.partidas[i].real,
          diferencia: calculo.partidas[i].diferencia,
          porcentajeUsado: calculo.partidas[i].porcentajeUsado,
          estado: calculo.partidas[i].estado,
          estadoCuota: calculo.partidas[i].estadoCuota,
          grupoId: partidas[i].grupoId,
          deudaId: partidas[i].deudaId,
          orden: partidas[i].id,
          actualizadoEn: DateTime.utc(2026, 11, 1),
        ),
    ],
    grupos: calculo.grupos,
    avisos: avisos,
  );
}

/// Repositorio falso para controlador y widget tests.
class FakePlanMensualRepository implements PlanMensualRepository {
  FakePlanMensualRepository({required this.plan});

  PlanMensual plan;
  final List<List<CambioMonto>> lotes = <List<CambioMonto>>[];
  final List<String> consultas = <String>[];
  final List<bool> consultasReferencias = <bool>[];
  final List<(String destino, String origen)> copias =
      <(String destino, String origen)>[];
  final List<GrupoPlan> grupos = <GrupoPlan>[];
  int siguienteGrupoId = 1;
  List<AvisoPlan> avisosCopia = const <AvisoPlan>[];
  AppFailure? errorGrupos;
  AppFailure? errorCopia;

  /// Si no es null, la próxima llamada espera a que este completer se complete.
  Completer<PlanMensual>? pendiente;

  /// Si no es null, la próxima llamada lanza esta falla.
  AppFailure? error;

  final CalculadoraPlanDart _calculadora = const CalculadoraPlanDart();

  @override
  Future<PlanMensual> obtener(
    String mes, {
    bool incluirReferencias = false,
  }) async {
    consultas.add(mes);
    consultasReferencias.add(incluirReferencias);
    return plan;
  }

  @override
  Future<PlanMensual> actualizarMontos(
    String mes,
    List<CambioMonto> cambios,
  ) async {
    lotes.add(cambios);
    if (error != null) {
      throw error!;
    }
    if (pendiente != null) {
      final Completer<PlanMensual> actual = pendiente!;
      return actual.future;
    }
    return aplicar(cambios);
  }

  PlanMensual aplicar(List<CambioMonto> cambios) {
    final Map<int, Decimal> montos = <int, Decimal>{
      for (final CambioMonto cambio in cambios) cambio.partidaId: cambio.monto,
    };
    final PlanCalculado recalculado = _calculadora.recalcularMontos(
      base: plan.calculo,
      nuevosMontos: montos,
      ingresoReferencia: plan.ingresoReferencia,
    );
    plan = plan.conCalculo(recalculado);
    return plan;
  }

  @override
  Future<PlanMensual> copiarDesde(String mes, String mesOrigen) async {
    if (errorCopia != null) {
      throw errorCopia!;
    }
    copias.add((mes, mesOrigen));
    plan = PlanMensual(
      mes: plan.mes,
      existe: true,
      ingresoReferencia: plan.ingresoReferencia,
      calculo: plan.calculo,
      partidas: plan.partidas,
      grupos: plan.grupos,
      avisos: avisosCopia,
    );
    return plan;
  }

  @override
  Future<List<GrupoPlan>> listarGrupos() async {
    if (errorGrupos != null) {
      throw errorGrupos!;
    }
    return List<GrupoPlan>.of(grupos);
  }

  @override
  Future<GrupoPlan> crearGrupo({required String nombre, int? orden}) async {
    if (errorGrupos != null) {
      throw errorGrupos!;
    }
    final GrupoPlan grupo = GrupoPlan(
      id: siguienteGrupoId++,
      nombre: nombre,
      orden: orden ?? 0,
    );
    grupos.add(grupo);
    return grupo;
  }

  @override
  Future<GrupoPlan> editarGrupo(
    int id, {
    String? nombre,
    int? orden,
  }) async {
    if (errorGrupos != null) {
      throw errorGrupos!;
    }
    final int index = grupos.indexWhere((GrupoPlan g) => g.id == id);
    final GrupoPlan actual = grupos[index];
    final GrupoPlan editado = GrupoPlan(
      id: id,
      nombre: nombre ?? actual.nombre,
      orden: orden ?? actual.orden,
    );
    grupos[index] = editado;
    return editado;
  }

  @override
  Future<void> eliminarGrupo(int id) async {
    if (errorGrupos != null) {
      throw errorGrupos!;
    }
    grupos.removeWhere((GrupoPlan g) => g.id == id);
  }
}

Decimal d(String valor) => Decimal.parse(valor);
