import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/time/calendar_date.dart';
import '../data/dio_movimientos_repository.dart';
import '../data/dio_saldos_repository.dart';
import '../domain/movimiento.dart';
import '../domain/movimiento_filtro.dart';
import '../domain/movimiento_tipo.dart';
import '../domain/movimientos_repository.dart';
import '../domain/saldos_repository.dart';

/// Estado del home: saldo, filtros y listado paginado.
class MovimientosState {
  const MovimientosState({
    this.saldo,
    this.cargandoSaldo = false,
    this.saldoError,
    this.filtro = const MovimientoFiltro(),
    this.items = const <Movimiento>[],
    this.page = 0,
    this.totalPages = 0,
    this.totalItems = 0,
    this.cargandoPagina = false,
    this.cargandoMas = false,
    this.errorPagina,
    this.inicializado = false,
  });

  final Decimal? saldo;
  final bool cargandoSaldo;
  final AppFailure? saldoError;

  final MovimientoFiltro filtro;
  final List<Movimiento> items;

  /// Última página cargada (base 0).
  final int page;
  final int totalPages;
  final int totalItems;

  final bool cargandoPagina;
  final bool cargandoMas;
  final AppFailure? errorPagina;

  /// `true` cuando ya se intentó la primera carga.
  final bool inicializado;

  bool get hayMas => page + 1 < totalPages;

  bool get vacio =>
      inicializado && !cargandoPagina && items.isEmpty && errorPagina == null;

  bool get filtrosActivos => !filtro.vacio;
}

final NotifierProvider<MovimientosController, MovimientosState>
movimientosProvider =
    NotifierProvider<MovimientosController, MovimientosState>(
      MovimientosController.new,
    );

class MovimientosController extends Notifier<MovimientosState> {
  @override
  MovimientosState build() => const MovimientosState();

  /// Carga inicial al montar el home (y al volver a entrar tras un login).
  Future<void> inicializar() async {
    if (state.inicializado && state.cargandoPagina) {
      return;
    }
    state = MovimientosState(filtro: state.filtro, cargandoSaldo: true);
    await Future.wait<void>(<Future<void>>[_cargarSaldo(), _cargarPagina(0)]);
  }

  /// Pull-to-refresh / volver de registrar: recarga saldo y primera página.
  Future<void> refrescar() async {
    state = MovimientosState(
      filtro: state.filtro,
      saldo: state.saldo,
      cargandoSaldo: true,
      cargandoPagina: true,
    );
    await Future.wait<void>(<Future<void>>[_cargarSaldo(), _cargarPagina(0)]);
  }

  void setDesde(CalendarDate? desde) {
    _aplicarFiltro(
      MovimientoFiltro(
        desde: desde,
        hasta: state.filtro.hasta,
        tipo: state.filtro.tipo,
      ),
    );
  }

  void setHasta(CalendarDate? hasta) {
    _aplicarFiltro(
      MovimientoFiltro(
        desde: state.filtro.desde,
        hasta: hasta,
        tipo: state.filtro.tipo,
      ),
    );
  }

  void setTipo(MovimientoTipo? tipo) {
    _aplicarFiltro(
      MovimientoFiltro(
        desde: state.filtro.desde,
        hasta: state.filtro.hasta,
        tipo: tipo,
      ),
    );
  }

  void limpiarFiltros() => _aplicarFiltro(const MovimientoFiltro());

  void _aplicarFiltro(MovimientoFiltro filtro) {
    state = MovimientosState(
      filtro: filtro,
      saldo: state.saldo,
      saldoError: state.saldoError,
    );
    unawaited(_cargarPagina(0));
  }

  /// Scroll cerca del final: pide la página siguiente si corresponde.
  Future<void> cargarMas() async {
    if (!state.hayMas || state.cargandoPagina || state.cargandoMas) {
      return;
    }
    await _cargarPagina(state.page + 1);
  }

  Future<void> _cargarSaldo() async {
    final SaldosRepository repository = ref.read(saldosRepositoryProvider);
    try {
      final Decimal saldo = await repository.saldoActual();
      state = _copy(saldo: saldo, saldoError: null, cargandoSaldo: false);
    } on AppFailure catch (failure) {
      state = _copy(saldoError: failure, cargandoSaldo: false);
    }
  }

  Future<void> _cargarPagina(int page) async {
    final MovimientosRepository repository = ref.read(
      movimientosRepositoryProvider,
    );
    state = _copy(
      cargandoPagina: page == 0,
      cargandoMas: page > 0,
      errorPagina: null,
    );
    try {
      final PaginaMovimientos resultado = await repository.pagina(
        filtro: state.filtro,
        page: page,
      );
      final Set<int> ids = <int>{
        for (final Movimiento item in state.items) item.id,
      };
      final List<Movimiento> nuevos = <Movimiento>[
        if (page == 0) ...resultado.content
        else
          ...resultado.content.where(
            (Movimiento m) => !ids.contains(m.id),
          ),
      ];
      state = _copy(
        items: nuevos,
        page: resultado.currentPage,
        totalPages: resultado.totalPages,
        totalItems: resultado.totalItems,
        cargandoPagina: false,
        cargandoMas: false,
        inicializado: true,
        errorPagina: null,
      );
    } on AppFailure catch (failure) {
      state = _copy(
        cargandoPagina: false,
        cargandoMas: false,
        inicializado: true,
        errorPagina: failure,
      );
    }
  }

  /// Reemplaza campos conservando el resto del estado.
  ///
  /// Los campos de error usan un centinela para distinguir "no tocar" de
  /// "limpiar a null".
  MovimientosState _copy({
    Object? saldo = _sinCambio,
    Object? saldoError = _sinCambio,
    bool? cargandoSaldo,
    List<Movimiento>? items,
    int? page,
    int? totalPages,
    int? totalItems,
    bool? cargandoPagina,
    bool? cargandoMas,
    Object? errorPagina = _sinCambio,
    bool? inicializado,
  }) {
    return MovimientosState(
      saldo: identical(saldo, _sinCambio) ? state.saldo : saldo as Decimal?,
      saldoError: identical(saldoError, _sinCambio)
          ? state.saldoError
          : saldoError as AppFailure?,
      cargandoSaldo: cargandoSaldo ?? state.cargandoSaldo,
      filtro: state.filtro,
      items: items ?? state.items,
      page: page ?? state.page,
      totalPages: totalPages ?? state.totalPages,
      totalItems: totalItems ?? state.totalItems,
      cargandoPagina: cargandoPagina ?? state.cargandoPagina,
      cargandoMas: cargandoMas ?? state.cargandoMas,
      errorPagina: identical(errorPagina, _sinCambio)
          ? state.errorPagina
          : errorPagina as AppFailure?,
      inicializado: inicializado ?? state.inicializado,
    );
  }

  static const Object _sinCambio = Object();
}
