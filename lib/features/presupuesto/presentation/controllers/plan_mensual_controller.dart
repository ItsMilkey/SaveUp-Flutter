import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
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
  }) {
    return PlanMensualState(
      mes: mes ?? this.mes,
      cargando: cargando ?? this.cargando,
      plan: plan ?? this.plan,
      errorCarga: limpiarErrorCarga ? null : (errorCarga ?? this.errorCarga),
      cambiosPendientes: cambiosPendientes ?? this.cambiosPendientes,
      enviandoLote: enviandoLote ?? this.enviandoLote,
      errorLote: limpiarErrorLote ? null : (errorLote ?? this.errorLote),
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
  Future<void> cargar(String mes, {bool incluirReferencias = false}) async {
    state = PlanMensualState(mes: mes, cargando: true);
    try {
      final PlanMensual plan = await ref
          .read(planMensualRepositoryProvider)
          .obtener(mes, incluirReferencias: incluirReferencias);
      state = PlanMensualState(mes: mes, plan: plan);
    } on AppFailure catch (failure) {
      state = PlanMensualState(mes: mes, errorCarga: failure);
    }
  }

  /// `onChange` del slider: recalcula localmente, sin red.
  ///
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
