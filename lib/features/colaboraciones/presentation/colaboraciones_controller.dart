import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../features/auth/presentation/auth_controllers.dart';
import '../../../features/movimientos/presentation/movimientos_controller.dart';
import '../../../features/presupuesto/presentation/controllers/ejecucion_presupuesto_controller.dart';
import '../../metas/presentation/controllers/metas_controller.dart';
import '../data/dio_colaboraciones_repository.dart';
import '../domain/colaboracion.dart';

final AsyncNotifierProvider<ColaboracionesController, SnapshotColaboraciones>
colaboracionesProvider =
    AsyncNotifierProvider<ColaboracionesController, SnapshotColaboraciones>(
      ColaboracionesController.new,
    );

class ColaboracionesController extends AsyncNotifier<SnapshotColaboraciones> {
  @override
  Future<SnapshotColaboraciones> build() {
    // La bandeja depende de quién está autenticado: al cambiar de cuenta el
    // provider se reconstruye y vuelve a pedir el snapshot al backend.
    ref.watch(authSessionProvider);
    return ref.read(colaboracionesRepositoryProvider).cargar();
  }

  Future<void> refrescar() async {
    state = await AsyncValue.guard(
      () => ref.read(colaboracionesRepositoryProvider).cargar(),
    );
  }
}

class ColaboracionActionResult<T> {
  const ColaboracionActionResult.success(this.value) : failure = null;
  const ColaboracionActionResult.failure(this.failure) : value = null;

  final T? value;
  final AppFailure? failure;
}

final NotifierProvider<ColaboracionesAccionesController, AsyncValue<void>>
colaboracionesAccionesProvider =
    NotifierProvider<ColaboracionesAccionesController, AsyncValue<void>>(
      ColaboracionesAccionesController.new,
    );

class ColaboracionesAccionesController extends Notifier<AsyncValue<void>> {
  bool _enCurso = false;

  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<ColaboracionActionResult<T>> ejecutar<T>(
    Future<T> Function() action, {
    bool afectaSaldos = false,
  }) async {
    if (_enCurso) {
      return ColaboracionActionResult<T>.failure(
        UnknownFailure(detail: 'Espera a que termine la acción actual.'),
      );
    }
    _enCurso = true;
    state = const AsyncLoading<void>();
    try {
      final T value = await action();
      state = const AsyncData<void>(null);
      await ref.read(colaboracionesProvider.notifier).refrescar();
      if (afectaSaldos) {
        await ref.read(movimientosProvider.notifier).refrescar();
        ref.invalidate(metasProvider);
        ref.invalidate(ejecucionPresupuestoProvider);
      }
      return ColaboracionActionResult<T>.success(value);
    } on AppFailure catch (failure, stack) {
      state = AsyncError<void>(failure, stack);
      return ColaboracionActionResult<T>.failure(failure);
    } finally {
      _enCurso = false;
    }
  }

  Future<ColaboracionActionResult<List<InvitacionColaborativa>>> crearMeta(
    MetaCompartidaDatos datos,
  ) => ejecutar(
    () => ref.read(colaboracionesRepositoryProvider).crearMeta(datos),
  );

  Future<ColaboracionActionResult<InvitacionColaborativa>> crearDeuda(
    DeudaDirectaDatos datos,
  ) => ejecutar(
    () => ref.read(colaboracionesRepositoryProvider).crearDeuda(datos),
  );

  Future<ColaboracionActionResult<bool>> aceptarInvitacion(int id) =>
      ejecutar(() async {
        await ref.read(colaboracionesRepositoryProvider).aceptarInvitacion(id);
        return true;
      });

  Future<ColaboracionActionResult<bool>> aceptarCodigoInvitacion(
    String codigo,
  ) => ejecutar(() async {
    await ref
        .read(colaboracionesRepositoryProvider)
        .aceptarCodigoInvitacion(codigo);
    return true;
  });

  Future<ColaboracionActionResult<bool>> rechazarInvitacion(int id) =>
      ejecutar(() async {
        await ref.read(colaboracionesRepositoryProvider).rechazarInvitacion(id);
        return true;
      });

  Future<ColaboracionActionResult<bool>> revocarInvitacion(int id) =>
      ejecutar(() async {
        await ref.read(colaboracionesRepositoryProvider).revocarInvitacion(id);
        return true;
      });

  Future<ColaboracionActionResult<bool>> marcarActividadLeida(int id) =>
      ejecutar(() async {
        await ref.read(colaboracionesRepositoryProvider).marcarActividadLeida(id);
        return true;
      });

  Future<ColaboracionActionResult<OperacionColaborativa>> registrarAporte(
    int metaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  }) => ejecutar(
    () => ref.read(colaboracionesRepositoryProvider).registrarAporte(
      metaId,
      monto: monto,
      descripcion: descripcion,
      emailAtribucion: emailAtribucion,
    ),
    afectaSaldos: true,
  );

  Future<ColaboracionActionResult<OperacionColaborativa>> registrarGastoMeta(
    int metaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  }) => ejecutar(
    () => ref.read(colaboracionesRepositoryProvider).registrarGastoMeta(
      metaId,
      monto: monto,
      descripcion: descripcion,
      emailAtribucion: emailAtribucion,
    ),
  );

  Future<ColaboracionActionResult<OperacionColaborativa>> registrarRetiroMeta(
    int metaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  }) => ejecutar(
    () => ref.read(colaboracionesRepositoryProvider).registrarRetiroMeta(
      metaId,
      monto: monto,
      descripcion: descripcion,
      emailAtribucion: emailAtribucion,
    ),
    afectaSaldos: true,
  );

  Future<ColaboracionActionResult<OperacionColaborativa>> registrarPagoDeuda(
    int deudaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  }) => ejecutar(
    () => ref.read(colaboracionesRepositoryProvider).registrarPagoDeuda(
      deudaId,
      monto: monto,
      descripcion: descripcion,
      emailAtribucion: emailAtribucion,
    ),
    afectaSaldos: true,
  );

  Future<ColaboracionActionResult<OperacionColaborativa>> condonarDeuda(
    int deudaId, {
    required Decimal monto,
    required String descripcion,
  }) => ejecutar(
    () => ref.read(colaboracionesRepositoryProvider).proponerCondonacion(
      deudaId,
      monto: monto,
      descripcion: descripcion,
    ),
  );

  Future<ColaboracionActionResult<OperacionColaborativa>> proponerCambioMeta(
    int id, {
    Decimal? montoObjetivo,
    CalendarDate? fechaLimite,
  }) => ejecutar(
    () => ref.read(colaboracionesRepositoryProvider).proponerCambioMeta(
      id,
      montoObjetivo: montoObjetivo,
      fechaLimite: fechaLimite,
    ),
  );

  Future<ColaboracionActionResult<OperacionColaborativa>> proponerCambioDeuda(
    int id, {
    required Decimal saldoPendiente,
  }) => ejecutar(
    () => ref.read(colaboracionesRepositoryProvider).proponerCambioDeuda(
      id,
      saldoPendiente: saldoPendiente,
    ),
  );

  Future<ColaboracionActionResult<OperacionColaborativa>> decidirOperacion(
    int id, {
    required bool aceptar,
  }) => ejecutar(
    () => ref.read(colaboracionesRepositoryProvider).decidirOperacion(
      id,
      aceptar: aceptar,
    ),
    afectaSaldos: true,
  );

  Future<ColaboracionActionResult<bool>> salirMeta(int id) =>
      ejecutar(() async {
        await ref.read(colaboracionesRepositoryProvider).salirMeta(id);
        return true;
      });

  Future<ColaboracionActionResult<OperacionColaborativa>> cancelarMeta(int id) =>
      ejecutar(() => ref.read(colaboracionesRepositoryProvider).cancelarMeta(id));

  Future<List<OperacionColaborativa>> obtenerHistorialMeta(int id) =>
      ref.read(colaboracionesRepositoryProvider).historialMeta(id);

  Future<List<OperacionColaborativa>> obtenerHistorialDeuda(int id) =>
      ref.read(colaboracionesRepositoryProvider).historialDeuda(id);
}
