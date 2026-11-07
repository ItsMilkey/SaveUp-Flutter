import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../movimientos/presentation/movimientos_controller.dart';
import '../../../presupuesto/presentation/controllers/ejecucion_presupuesto_controller.dart';
import '../../data/dio_metas_repository.dart';
import '../../domain/meta_ahorro.dart';

/// Listado de metas de ahorro (`GET /metas/me`).
final AsyncNotifierProvider<MetasController, List<MetaAhorro>> metasProvider =
    AsyncNotifierProvider<MetasController, List<MetaAhorro>>(
      MetasController.new,
    );

class MetasController extends AsyncNotifier<List<MetaAhorro>> {
  @override
  Future<List<MetaAhorro>> build() {
    return ref.read(metasRepositoryProvider).listar();
  }

  Future<void> refrescar() async {
    state = const AsyncLoading<List<MetaAhorro>>();
    state = await AsyncValue.guard(
      () => ref.read(metasRepositoryProvider).listar(),
    );
  }
}

/// Acciones sobre una meta: abonar, retirar y eliminar.
///
/// Devuelve la falla para que la pantalla muestre su `detail`; `null` = éxito.
/// Abonar/retirar/eliminar crean movimientos reales, así que se invalidan el
/// home (`movimientosProvider`) y la ejecución del presupuesto.
final NotifierProvider<MetaAccionesController, AsyncValue<void>>
metaAccionesProvider =
    NotifierProvider<MetaAccionesController, AsyncValue<void>>(
      MetaAccionesController.new,
    );

class MetaAccionesController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  void reset() {
    state = const AsyncData<void>(null);
  }

  Future<AppFailure?> abonar(
    int id, {
    required Decimal monto,
    required String descripcion,
  }) {
    return _ejecutar(
      () => ref
          .read(metasRepositoryProvider)
          .abonar(id, monto: monto, descripcion: descripcion),
    );
  }

  Future<AppFailure?> retirar(
    int id, {
    required Decimal monto,
    required String descripcion,
  }) {
    return _ejecutar(
      () => ref
          .read(metasRepositoryProvider)
          .retirar(id, monto: monto, descripcion: descripcion),
    );
  }

  Future<AppFailure?> eliminar(int id) {
    return _ejecutar(() => ref.read(metasRepositoryProvider).eliminar(id));
  }

  Future<AppFailure?> _ejecutar(Future<void> Function() accion) async {
    state = const AsyncLoading<void>();
    try {
      await accion();
      state = const AsyncData<void>(null);
      ref.invalidate(metasProvider);
      // El home no se reinicializa solo al invalidar; refrescamos saldo y
      // primera página para que el abono/retiro se refleje al volver.
      await ref.read(movimientosProvider.notifier).refrescar();
      ref.invalidate(ejecucionPresupuestoProvider);
      return null;
    } on AppFailure catch (failure, stack) {
      state = AsyncError<void>(failure, stack);
      return failure;
    }
  }
}
