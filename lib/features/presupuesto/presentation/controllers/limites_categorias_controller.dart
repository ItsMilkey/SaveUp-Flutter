import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/time/business_month.dart';
import '../../../movimientos/data/dio_categorias_repository.dart';
import '../../../movimientos/domain/categoria.dart';
import '../../data/dio_presupuesto_repository.dart';
import '../../domain/ejecucion_presupuesto.dart';
import '../../domain/limite_categoria.dart';

/// Editor de límites por categoría (el guardado reemplaza el conjunto).
class LimitesCategoriasState {
  const LimitesCategoriasState({
    this.cargando = false,
    this.categorias = const <Categoria>[],
    this.guardados = const <LimiteCategoria>[],
    this.valores = const <int, Decimal>{},
    this.guardando = false,
    this.guardado = false,
    this.errorCarga,
    this.error,
    this.mensajeValidacion,
  });

  final bool cargando;
  final List<Categoria> categorias;
  final List<LimiteCategoria> guardados;

  /// Límites editables por `categoriaId` (lo que se enviará en el PUT).
  final Map<int, Decimal> valores;
  final bool guardando;
  final bool guardado;
  final AppFailure? errorCarga;
  final AppFailure? error;

  /// Aviso local cuando el conjunto no es enviable (límite ≤ 0).
  final String? mensajeValidacion;
}

final NotifierProvider<LimitesCategoriasController, LimitesCategoriasState>
limitesCategoriasProvider =
    NotifierProvider<LimitesCategoriasController, LimitesCategoriasState>(
      LimitesCategoriasController.new,
    );

class LimitesCategoriasController extends Notifier<LimitesCategoriasState> {
  @override
  LimitesCategoriasState build() => const LimitesCategoriasState();

  Future<void> cargar() async {
    state = const LimitesCategoriasState(cargando: true);
    try {
      final List<Categoria> categorias = await ref
          .read(categoriasRepositoryProvider)
          .listar();
      final List<LimiteCategoria> limites = await ref
          .read(presupuestoRepositoryProvider)
          .listarLimites();
      state = LimitesCategoriasState(
        categorias: categorias,
        guardados: limites,
        valores: <int, Decimal>{
          for (final LimiteCategoria limite in limites)
            limite.categoriaId: limite.limiteMensual,
        },
      );
    } on AppFailure catch (failure) {
      state = LimitesCategoriasState(errorCarga: failure);
    }
  }

  /// Agrega o actualiza un límite local (aún sin guardar).
  void setLimite(int categoriaId, Decimal limite) {
    final Map<int, Decimal> valores = <int, Decimal>{
      ...state.valores,
      categoriaId: limite.round(scale: 2),
    };
    state = _conValores(valores);
  }

  void quitar(int categoriaId) {
    final Map<int, Decimal> valores = <int, Decimal>{...state.valores}
      ..remove(categoriaId);
    state = _conValores(valores);
  }

  LimitesCategoriasState _conValores(Map<int, Decimal> valores) {
    return LimitesCategoriasState(
      categorias: state.categorias,
      guardados: state.guardados,
      valores: valores,
      guardado: false,
      errorCarga: state.errorCarga,
    );
  }

  Future<void> guardar() async {
    if (state.guardando) {
      return;
    }
    final Decimal cero = Decimal.zero;
    if (state.valores.values.any((Decimal v) => v <= cero)) {
      state = LimitesCategoriasState(
        categorias: state.categorias,
        guardados: state.guardados,
        valores: state.valores,
        mensajeValidacion: 'Cada límite debe ser mayor a 0.',
      );
      return;
    }

    final List<LimiteCategoriaItem> items = <LimiteCategoriaItem>[
      for (final MapEntry<int, Decimal> e in state.valores.entries)
        LimiteCategoriaItem(categoriaId: e.key, limiteMensual: e.value),
    ];
    state = LimitesCategoriasState(
      categorias: state.categorias,
      guardados: state.guardados,
      valores: state.valores,
      guardando: true,
    );
    try {
      final List<LimiteCategoria> resultado = await ref
          .read(presupuestoRepositoryProvider)
          .reemplazarLimites(items);
      state = LimitesCategoriasState(
        categorias: state.categorias,
        guardados: resultado,
        valores: <int, Decimal>{
          for (final LimiteCategoria limite in resultado)
            limite.categoriaId: limite.limiteMensual,
        },
        guardado: true,
      );
      ref.invalidate(ejecucionCategoriasProvider);
    } on AppFailure catch (failure) {
      state = LimitesCategoriasState(
        categorias: state.categorias,
        guardados: state.guardados,
        valores: state.valores,
        error: failure,
      );
    }
  }

  /// Limpia el aviso de guardado tras mostrarlo.
  void limpiarGuardado() {
    if (!state.guardado) {
      return;
    }
    state = LimitesCategoriasState(
      categorias: state.categorias,
      guardados: state.guardados,
      valores: state.valores,
    );
  }
}

/// Ejecución por categoría del mes actual (se refresca al guardar límites).
final FutureProvider<List<EjecucionCategoria>> ejecucionCategoriasProvider =
    FutureProvider<List<EjecucionCategoria>>((Ref ref) {
      final BusinessMonth mes = BusinessMonth.fromInstant(DateTime.now());
      return ref
          .read(presupuestoRepositoryProvider)
          .ejecucionCategorias(month: mes.month, year: mes.year);
    });
