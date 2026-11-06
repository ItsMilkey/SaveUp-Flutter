import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/dio_plan_mensual_repository.dart';
import '../../domain/plan_mensual.dart';

/// Gestión de grupos del plan (`/planes/grupos`; máximo 20 por usuario).
final AsyncNotifierProvider<GruposPlanController, List<GrupoPlan>>
gruposPlanProvider =
    AsyncNotifierProvider<GruposPlanController, List<GrupoPlan>>(
      GruposPlanController.new,
    );

class GruposPlanController extends AsyncNotifier<List<GrupoPlan>> {
  @override
  Future<List<GrupoPlan>> build() {
    return ref.read(planMensualRepositoryProvider).listarGrupos();
  }

  Future<void> refrescar() async {
    state = const AsyncLoading<List<GrupoPlan>>();
    state = await AsyncValue.guard(
      () => ref.read(planMensualRepositoryProvider).listarGrupos(),
    );
  }

  /// Devuelve la falla (p. ej. 409 al superar 20 grupos) para mostrarla.
  Future<AppFailure?> crear(String nombre, {int? orden}) async {
    try {
      await ref
          .read(planMensualRepositoryProvider)
          .crearGrupo(nombre: nombre, orden: orden);
      await refrescar();
      return null;
    } on AppFailure catch (failure) {
      return failure;
    }
  }

  Future<AppFailure?> editar(int id, {String? nombre, int? orden}) async {
    try {
      await ref
          .read(planMensualRepositoryProvider)
          .editarGrupo(id, nombre: nombre, orden: orden);
      await refrescar();
      return null;
    } on AppFailure catch (failure) {
      return failure;
    }
  }

  Future<AppFailure?> eliminar(int id) async {
    try {
      await ref.read(planMensualRepositoryProvider).eliminarGrupo(id);
      await refrescar();
      return null;
    } on AppFailure catch (failure) {
      return failure;
    }
  }
}
