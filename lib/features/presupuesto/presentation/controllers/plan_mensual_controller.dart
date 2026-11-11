import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../movimientos/data/dio_movimientos_repository.dart';
import '../../../movimientos/domain/movimiento_tipo.dart';
import '../../data/dio_plan_mensual_repository.dart';
import '../../domain/plan_calculo.dart';
import '../../domain/plan_mensual.dart';
import '../../domain/services/calculadora_plan_dart.dart';

/// Estado del plan mensual: verdad del servidor + vista local provisional.
class PlanMensualState {
  const PlanMensualState({
    this.mes = '',
    this.cargando = false,
    this.plan,
    this.errorCarga,
    this.cambiosPendientes = const <int, Decimal>{},
    this.enviandoLote = false,
    this.errorLote,
    this.incluirReferencias = false,
    this.copiando = false,
  });

  final String mes;
  final bool cargando;

  /// Plan autoritativo (o el último recalculado localmente durante el drag).
  final PlanMensual? plan;
  final AppFailure? errorCarga;

  /// Buffer local de montos aún no confirmados por el servidor.
  final Map<int, Decimal> cambiosPendientes;

  final bool enviandoLote;

  /// Error del último PATCH; la UI lo muestra inline y permite reintentar.
  final AppFailure? errorLote;

  /// Si la vista pide referencias históricas (`incluirReferencias=true`).
  final bool incluirReferencias;

  /// `true` mientras corre la copia de un mes.
  final bool copiando;

  bool get hayCambios => cambiosPendientes.isNotEmpty;

  PlanMensualState copyWith({
    String? mes,
    bool? cargando,
    PlanMensual? plan,
    AppFailure? errorCarga,
    bool limpiarErrorCarga = false,
    Map<int, Decimal>? cambiosPendientes,
    bool? enviandoLote,
    AppFailure? errorLote,
    bool limpiarErrorLote = false,
    bool? incluirReferencias,
    bool? copiando,
  }) {
    return PlanMensualState(
      mes: mes ?? this.mes,
      cargando: cargando ?? this.cargando,
      plan: plan ?? this.plan,
      errorCarga: limpiarErrorCarga ? null : (errorCarga ?? this.errorCarga),
      cambiosPendientes: cambiosPendientes ?? this.cambiosPendientes,
      enviandoLote: enviandoLote ?? this.enviandoLote,
      errorLote: limpiarErrorLote ? null : (errorLote ?? this.errorLote),
      incluirReferencias: incluirReferencias ?? this.incluirReferencias,
      copiando: copiando ?? this.copiando,
    );
  }
}

final NotifierProvider<PlanMensualController, PlanMensualState>
planMensualProvider =
    NotifierProvider<PlanMensualController, PlanMensualState>(
      PlanMensualController.new,
    );

/// Controlador del plan: recálculo local sin red durante el drag y lote
/// atómico (`PATCH /planes/{mes}/montos`) al soltar.
class PlanMensualController extends Notifier<PlanMensualState> {
  /// Máximo de cambios por lote (`CambiosMontosDTO`).
  static const int maxCambiosPorLote = 100;

  final CalculadoraPlanDart _calculadora = const CalculadoraPlanDart();

  /// Cambios ya soltados pendientes de enviar (puede crecer mientras un PATCH
  /// está en vuelo).
  final Map<int, Decimal> _colaEnvio = <int, Decimal>{};
  bool _enviando = false;

  @override
  PlanMensualState build() => const PlanMensualState();

  /// Carga el plan del mes (calendario de negocio `yyyy-MM`).
  Future<void> cargar(String mes, {bool? incluirReferencias}) async {
    final bool referencias =
        incluirReferencias ?? state.incluirReferencias;
    state = PlanMensualState(
      mes: mes,
      cargando: true,
      incluirReferencias: referencias,
    );
    try {
      final PlanMensual plan = await ref
          .read(planMensualRepositoryProvider)
          .obtener(mes, incluirReferencias: referencias);
      state = PlanMensualState(
        mes: mes,
        plan: plan,
        incluirReferencias: referencias,
      );
    } on AppFailure catch (failure) {
      state = PlanMensualState(
        mes: mes,
        errorCarga: failure,
        incluirReferencias: referencias,
      );
    }
  }

  /// Registra un gasto imputado a una partida (`POST /movimientos` con
  /// `partidaId`) y recarga el plan para reflejar el nuevo `real`.
  ///
  /// El backend toma la fecha del movimiento (ahora) y exige que la partida
  /// pertenezca a ese mes; por eso la UI solo ofrece la acción en el mes actual.
  Future<AppFailure?> registrarGastoPartida({
    required int partidaId,
    required Decimal monto,
    required String descripcion,
  }) async {
    try {
      await ref
          .read(movimientosRepositoryProvider)
          .registrar(
            monto: monto,
            descripcion: descripcion,
            tipo: MovimientoTipo.gastoGeneral,
            partidaId: partidaId,
          );
    } on AppFailure catch (failure) {
      return failure;
    }
    await cargar(state.mes);
    return null;
  }

  /// Copia el plan de [mesOrigen] al mes actual. Devuelve la falla, si hubo.
  ///
  /// Los `avisos` del 200 quedan en el plan y se muestran como información,
  /// nunca como errores.
  Future<AppFailure?> copiarDesde(String mesOrigen) async {
    if (state.plan == null) {
      return null;
    }
    state = state.copyWith(copiando: true);
    try {
      final PlanMensual copiado = await ref
          .read(planMensualRepositoryProvider)
          .copiarDesde(state.mes, mesOrigen);
      state = state.copyWith(
        plan: copiado,
        copiando: false,
        cambiosPendientes: const <int, Decimal>{},
        limpiarErrorLote: true,
      );
      return null;
    } on AppFailure catch (failure) {
      state = state.copyWith(copiando: false);
      return failure;
    }
  }

  /// Actualiza el ingreso de referencia con vista local inmediata y `PUT`.
  Future<AppFailure?> actualizarIngreso(Decimal? monto) async {
    final PlanMensual? previo = state.plan;
    if (previo == null) {
      return null;
    }
    final PlanMensual local = PlanMensual(
      mes: previo.mes,
      existe: previo.existe,
      ingresoReferencia: monto,
      calculo: _calculadora.recalcularMontos(
        base: previo.calculo,
        nuevosMontos: const <int, Decimal>{},
        ingresoReferencia: monto,
      ),
      partidas: previo.partidas,
      grupos: previo.grupos,
      avisos: previo.avisos,
    );
    state = state.copyWith(plan: local);
    try {
      final PlanMensual servidor = await ref
          .read(planMensualRepositoryProvider)
          .actualizarIngreso(state.mes, monto);
      state = state.copyWith(plan: servidor);
      return null;
    } on AppFailure catch (failure) {
      state = state.copyWith(plan: previo);
      return failure;
    }
  }

  /// Crea una partida y reemplaza el plan con la respuesta autoritativa.
  Future<AppFailure?> crearPartida({
    required String nombre,
    required int categoriaId,
    required Decimal montoPlanificado,
    int? grupoId,
  }) async {
    try {
      final PlanMensual plan = await ref
          .read(planMensualRepositoryProvider)
          .crearPartida(
            state.mes,
            nombre: nombre,
            categoriaId: categoriaId,
            montoPlanificado: montoPlanificado,
            grupoId: grupoId,
          );
      state = state.copyWith(
        plan: plan,
        cambiosPendientes: const <int, Decimal>{},
        limpiarErrorLote: true,
      );
      return null;
    } on AppFailure catch (failure) {
      return failure;
    }
  }

  /// Edita una partida (parcial) y reemplaza el plan con la respuesta.
  Future<AppFailure?> editarPartida(
    int id, {
    String? nombre,
    int? categoriaId,
    int? grupoId,
    bool quitarGrupo = false,
  }) async {
    try {
      final PlanMensual plan = await ref
          .read(planMensualRepositoryProvider)
          .editarPartida(
            state.mes,
            id,
            nombre: nombre,
            categoriaId: categoriaId,
            grupoId: grupoId,
            quitarGrupo: quitarGrupo,
          );
      state = state.copyWith(plan: plan);
      return null;
    } on AppFailure catch (failure) {
      return failure;
    }
  }

  /// Elimina una partida (204) y recarga el plan autoritativo.
  Future<AppFailure?> eliminarPartida(int id) async {
    try {
      await ref.read(planMensualRepositoryProvider).eliminarPartida(
        state.mes,
        id,
      );
      final PlanMensual plan = await ref
          .read(planMensualRepositoryProvider)
          .obtener(state.mes, incluirReferencias: state.incluirReferencias);
      state = state.copyWith(
        plan: plan,
        cambiosPendientes: const <int, Decimal>{},
        limpiarErrorLote: true,
      );
      return null;
    } on AppFailure catch (failure) {
      return failure;
    }
  }

  /// `onChange` del slider: recalcula localmente, sin red.  ///
  /// Las partidas vinculadas a una deuda se ignoran: su monto lo define la
  /// cuota y el backend responde 409 si se intenta cambiar.
  void moverPartida(int partidaId, Decimal monto) {
    final PlanMensual? plan = state.plan;
    if (plan == null) {
      return;
    }
    final PartidaPlan? partida = plan.partida(partidaId);
    if (partida == null || partida.vinculadaADeuda) {
      return;
    }
    final Decimal valor = (monto < Decimal.zero ? Decimal.zero : monto).round(
      scale: 2,
    );
    final Map<int, Decimal> buffer = <int, Decimal>{
      ...state.cambiosPendientes,
      partidaId: valor,
    };
    final PlanCalculado recalculado = _calculadora.recalcularMontos(
      base: plan.calculo,
      nuevosMontos: buffer,
      ingresoReferencia: plan.ingresoReferencia,
    );
    state = state.copyWith(
      plan: plan.conCalculo(recalculado),
      cambiosPendientes: buffer,
      enviandoLote: state.enviandoLote,
    );
  }

  /// `onChangeEnd` del slider: encola lo acumulado y envía el lote.
  Future<void> soltar() async {
    if (state.plan == null) {
      return;
    }
    if (state.cambiosPendientes.isNotEmpty) {
      _colaEnvio.addAll(state.cambiosPendientes);
    }
    await _enviarPendientes();
  }

  /// Reintento manual tras un error de red/lote.
  Future<void> reintentar() async {
    if (state.cambiosPendientes.isNotEmpty) {
      _colaEnvio.addAll(state.cambiosPendientes);
    }
    await _enviarPendientes();
  }

  Future<void> _enviarPendientes() async {
    if (_enviando || _colaEnvio.isEmpty) {
      return;
    }
    _enviando = true;
    state = state.copyWith(enviandoLote: true, limpiarErrorLote: true);
    try {
      while (_colaEnvio.isNotEmpty) {
        final List<MapEntry<int, Decimal>> lote = _colaEnvio.entries
            .take(maxCambiosPorLote)
            .toList(growable: false);
        final Map<int, Decimal> enviados = <int, Decimal>{
          for (final MapEntry<int, Decimal> e in lote) e.key: e.value,
        };

        final PlanMensual planServidor = await ref
            .read(planMensualRepositoryProvider)
            .actualizarMontos(
              state.mes,
              <CambioMonto>[
                for (final MapEntry<int, Decimal> e in lote)
                  CambioMonto(partidaId: e.key, monto: e.value),
              ],
            );

        // Limpia solo lo enviado que no cambió después; un nuevo arrastre del
        // mismo partidaId durante el vuelo se conserva para el próximo lote.
        for (final MapEntry<int, Decimal> e in enviados.entries) {
          if (_colaEnvio[e.key] == e.value) {
            _colaEnvio.remove(e.key);
          }
        }
        final Map<int, Decimal> buffer = <int, Decimal>{
          for (final MapEntry<int, Decimal> e in state.cambiosPendientes.entries)
            if (e.value != enviados[e.key]) e.key: e.value,
        };

        // Reconciliación autoritativa: el plan del servidor manda; si quedan
        // cambios locales sin confirmar, se reaplican solo como vista.
        PlanMensual plan = planServidor;
        if (buffer.isNotEmpty) {
          plan = plan.conCalculo(
            _calculadora.recalcularMontos(
              base: plan.calculo,
              nuevosMontos: buffer,
              ingresoReferencia: plan.ingresoReferencia,
            ),
          );
        }
        state = state.copyWith(
          plan: plan,
          cambiosPendientes: buffer,
          enviandoLote: _colaEnvio.isNotEmpty,
          limpiarErrorLote: true,
        );
      }
    } on AppFailure catch (failure) {
      state = state.copyWith(enviandoLote: false, errorLote: failure);
    } finally {
      _enviando = false;
      if (!state.enviandoLote) {
        state = state.copyWith(enviandoLote: false);
      }
    }
  }

  /// Tope del slider: `monto actual + max(remanenteLibre, 0)`.
  Decimal limiteSlider(int partidaId) {
    final PlanMensual? plan = state.plan;
    if (plan == null) {
      return Decimal.zero;
    }
    final PartidaPlan? partida = plan.partida(partidaId);
    if (partida == null) {
      return Decimal.zero;
    }
    final Decimal remanente =
        plan.calculo.resumen.remanenteLibre ?? Decimal.zero;
    final Decimal extra = remanente > Decimal.zero ? remanente : Decimal.zero;
    return partida.montoPlanificado + extra;
  }
}
