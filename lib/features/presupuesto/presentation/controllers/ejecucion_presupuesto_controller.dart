import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/time/business_month.dart';
import '../../data/dio_presupuesto_repository.dart';
import '../../domain/ejecucion_presupuesto.dart';
import '../../domain/presupuesto_repository.dart';

/// Estado de la ejecución mensual y su historial (últimos 6 meses).
class EjecucionPresupuestoState {
  const EjecucionPresupuestoState({
    required this.mes,
    this.cargando = false,
    this.ejecucion,
    this.historial = const <HistorialPresupuesto>[],
    this.error,
  });

  final BusinessMonth mes;
  final bool cargando;
  final EjecucionPresupuesto? ejecucion;
  final List<HistorialPresupuesto> historial;
  final AppFailure? error;
}

final NotifierProvider<
  EjecucionPresupuestoController,
  EjecucionPresupuestoState
>
ejecucionPresupuestoProvider =
    NotifierProvider<
      EjecucionPresupuestoController,
      EjecucionPresupuestoState
    >(EjecucionPresupuestoController.new);

class EjecucionPresupuestoController
    extends Notifier<EjecucionPresupuestoState> {
  @override
  EjecucionPresupuestoState build() {
    final BusinessMonth mes = BusinessMonth.fromInstant(DateTime.now());
    return EjecucionPresupuestoState(mes: mes);
  }

  Future<void> cargar({BusinessMonth? mes}) async {
    final BusinessMonth objetivo = mes ?? state.mes;
    final EjecucionPresupuesto? anterior = state.ejecucion;
    final List<HistorialPresupuesto> historialAnterior = state.historial;
    state = EjecucionPresupuestoState(mes: objetivo, cargando: true);
    final PresupuestoRepository repository = ref.read(
      presupuestoRepositoryProvider,
    );
    try {
      final EjecucionPresupuesto ejecucion = await repository.ejecucion(
        month: objetivo.month,
        year: objetivo.year,
      );
      final DateTime inicio = DateTime(objetivo.year, objetivo.month - 5);
      List<HistorialPresupuesto> historial = historialAnterior;
      AppFailure? errorHistorial;
      try {
        historial = await repository.historial(
          desde: _mes(inicio.year, inicio.month),
          hasta: _mes(objetivo.year, objetivo.month),
        );
      } on AppFailure catch (failure) {
        errorHistorial = failure;
      }
      state = EjecucionPresupuestoState(
        mes: objetivo,
        ejecucion: ejecucion,
        historial: historial,
        error: errorHistorial,
      );
    } on AppFailure catch (failure) {
      state = EjecucionPresupuestoState(
        mes: objetivo,
        ejecucion: anterior,
        historial: historialAnterior,
        error: failure,
      );
    }
  }

  Future<void> cambiarMes(int delta) async {
    final DateTime siguiente = DateTime(state.mes.year, state.mes.month + delta);
    await cargar(
      mes: BusinessMonth(siguiente.year, siguiente.month),
    );
  }

  static String _mes(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';
}
