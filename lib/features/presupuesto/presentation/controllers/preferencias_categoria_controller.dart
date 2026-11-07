import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/dio_categorias_preferencias_repository.dart';
import '../../domain/plan_calculo.dart';
import '../../domain/preferencia_categoria.dart';
import 'ejecucion_presupuesto_controller.dart';
import 'limites_categorias_controller.dart';

/// Estado de las preferencias de tipo de categoría.
class PreferenciasCategoriaState {
  const PreferenciasCategoriaState({
    this.cargando = false,
    this.preferencias = const <PreferenciaCategoria>[],
    this.guardando = const <int>{},
    this.errorCarga,
    this.error,
  });

  final bool cargando;
  final List<PreferenciaCategoria> preferencias;

  /// Ids con una operación en curso (`PUT`/`DELETE`).
  final Set<int> guardando;
  final AppFailure? errorCarga;
  final AppFailure? error;
}

final NotifierProvider<
  PreferenciasCategoriaController,
  PreferenciasCategoriaState
>
preferenciasCategoriaProvider =
    NotifierProvider<
      PreferenciasCategoriaController,
      PreferenciasCategoriaState
    >(PreferenciasCategoriaController.new);

/// Cambia o quita el tipo preferido de una categoría.
///
/// Solo se ofrecen `NECESIDAD`/`DESEO` y solo para categorías cuyo tipo por
/// defecto sea reclasificable; el `DELETE` vuelve al tipo por defecto.
class PreferenciasCategoriaController
    extends Notifier<PreferenciasCategoriaState> {
  @override
  PreferenciasCategoriaState build() => const PreferenciasCategoriaState();

  Future<void> cargar() async {
    state = const PreferenciasCategoriaState(cargando: true);
    try {
      final List<PreferenciaCategoria> lista = await ref
          .read(categoriasPreferenciasRepositoryProvider)
          .listar();
      state = PreferenciasCategoriaState(preferencias: lista);
    } on AppFailure catch (failure) {
      state = PreferenciasCategoriaState(errorCarga: failure);
    }
  }

  Future<void> establecer(int categoriaId, TipoPresupuesto tipo) async {
    if (tipo != TipoPresupuesto.necesidad && tipo != TipoPresupuesto.deseo) {
      return;
    }
    if (state.guardando.contains(categoriaId)) {
      return;
    }
    _marcarGuardando(categoriaId, true);
    try {
      final PreferenciaCategoria actualizada = await ref
          .read(categoriasPreferenciasRepositoryProvider)
          .establecerTipoPreferido(categoriaId, tipo);
      _reemplazar(actualizada);
      _marcarGuardando(categoriaId, false);
      _invalidarDependientes();
    } on AppFailure catch (failure) {
      _marcarGuardando(categoriaId, false, error: failure);
    }
  }

  Future<void> quitar(int categoriaId) async {
    if (state.guardando.contains(categoriaId)) {
      return;
    }
    _marcarGuardando(categoriaId, true);
    try {
      await ref
          .read(categoriasPreferenciasRepositoryProvider)
          .quitarTipoPreferido(categoriaId);
      final PreferenciaCategoria? actual = _buscar(categoriaId);
      if (actual != null) {
        _reemplazar(
          PreferenciaCategoria(
            id: actual.id,
            nombre: actual.nombre,
            codigo: actual.codigo,
            iconId: actual.iconId,
            colorHex: actual.colorHex,
            tipoPorDefecto: actual.tipoPorDefecto,
            tipoEfectivo: actual.tipoPorDefecto,
            tipoPreferido: null,
          ),
        );
      }
      _marcarGuardando(categoriaId, false);
      _invalidarDependientes();
    } on AppFailure catch (failure) {
      _marcarGuardando(categoriaId, false, error: failure);
    }
  }

  void limpiarError() {
    if (state.error != null) {
      state = PreferenciasCategoriaState(
        preferencias: state.preferencias,
        guardando: state.guardando,
      );
    }
  }

  PreferenciaCategoria? _buscar(int categoriaId) {
    for (final PreferenciaCategoria item in state.preferencias) {
      if (item.id == categoriaId) {
        return item;
      }
    }
    return null;
  }

  void _reemplazar(PreferenciaCategoria actualizada) {
    state = PreferenciasCategoriaState(
      preferencias: <PreferenciaCategoria>[
        for (final PreferenciaCategoria item in state.preferencias)
          if (item.id == actualizada.id) actualizada else item,
      ],
      guardando: state.guardando,
    );
  }

  void _marcarGuardando(int categoriaId, bool activo, {AppFailure? error}) {
    final Set<int> guardando = <int>{...state.guardando};
    if (activo) {
      guardando.add(categoriaId);
    } else {
      guardando.remove(categoriaId);
    }
    state = PreferenciasCategoriaState(
      preferencias: state.preferencias,
      guardando: guardando,
      error: error,
    );
  }

  void _invalidarDependientes() {
    ref.invalidate(ejecucionPresupuestoProvider);
    ref.invalidate(ejecucionCategoriasProvider);
  }
}
