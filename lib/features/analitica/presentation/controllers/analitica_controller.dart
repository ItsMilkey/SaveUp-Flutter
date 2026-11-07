import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/time/business_month.dart';
import '../../../movimientos/data/dio_categorias_repository.dart';
import '../../../movimientos/domain/categoria.dart';
import '../../../presupuesto/data/dio_plan_mensual_repository.dart';
import '../../../presupuesto/data/dio_presupuesto_repository.dart';
import '../../../presupuesto/domain/ejecucion_presupuesto.dart';
import '../../../presupuesto/domain/plan_mensual.dart';
import '../../domain/analitica.dart';

/// Estado de la pantalla de analítica.
class AnaliticaState {
  const AnaliticaState({
    required this.mes,
    this.cargando = false,
    this.resumen,
    this.error,
    this.errorHistorial,
  });

  final BusinessMonth mes;
  final bool cargando;
  final ResumenAnalitica? resumen;

  /// Falla del plan del mes (sin plan no hay resumen).
  final AppFailure? error;

  /// Falla solo del historial: el resumen del mes sigue disponible.
  final AppFailure? errorHistorial;
}

final NotifierProvider<AnaliticaController, AnaliticaState> analiticaProvider =
    NotifierProvider<AnaliticaController, AnaliticaState>(
      AnaliticaController.new,
    );

/// Carga el plan del mes, el historial de 6 meses y el catálogo.
///
/// Reutiliza los repositorios existentes: no hay endpoints nuevos.
class AnaliticaController extends Notifier<AnaliticaState> {
  int _generacion = 0;

  @override
  AnaliticaState build() {
    return AnaliticaState(mes: BusinessMonth.fromInstant(DateTime.now()));
  }

  Future<void> cargar({BusinessMonth? mes}) async {
    final BusinessMonth objetivo = mes ?? state.mes;
    final int generacion = ++_generacion;
    state = AnaliticaState(mes: objetivo, cargando: true);

    final PlanMensual plan;
    try {
      plan = await ref
          .read(planMensualRepositoryProvider)
          .obtener(objetivo.toString());
    } on AppFailure catch (failure) {
      if (generacion != _generacion) {
        return;
      }
      state = AnaliticaState(mes: objetivo, error: failure);
      return;
    }
    if (generacion != _generacion) {
      return;
    }

    final DateTime inicio = DateTime(objetivo.year, objetivo.month - 5);
    List<HistorialPresupuesto> historial = const <HistorialPresupuesto>[];
    AppFailure? errorHistorial;
    try {
      historial = await ref
          .read(presupuestoRepositoryProvider)
          .historial(
            desde: _mes(inicio.year, inicio.month),
            hasta: objetivo.toString(),
          );
    } on AppFailure catch (failure) {
      errorHistorial = failure;
    }
    if (generacion != _generacion) {
      return;
    }

    // El catálogo es cosmético (nombre/color): si falla, se usa el código.
    List<Categoria> catalogo = const <Categoria>[];
    try {
      catalogo = await ref.read(categoriasRepositoryProvider).listar();
    } on AppFailure {
      catalogo = const <Categoria>[];
    }
    if (generacion != _generacion) {
      return;
    }

    state = AnaliticaState(
      mes: objetivo,
      resumen: construirResumenAnalitica(
        mes: objetivo,
        plan: plan,
        historial: historial,
        catalogo: catalogo,
      ),
      errorHistorial: errorHistorial,
    );
  }

  Future<void> cambiarMes(int delta) async {
    final DateTime siguiente = DateTime(
      state.mes.year,
      state.mes.month + delta,
    );
    await cargar(mes: BusinessMonth(siguiente.year, siguiente.month));
  }

  Future<void> reintentar() => cargar();

  static String _mes(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';
}
