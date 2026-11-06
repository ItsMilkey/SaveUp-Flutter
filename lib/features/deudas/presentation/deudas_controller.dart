import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../movimientos/presentation/movimientos_controller.dart';
import '../data/dio_deudas_repository.dart';
import '../data/dio_simulador_repository.dart';
import '../domain/deuda.dart';
import '../domain/deudas_repository.dart';
import '../domain/pago_deuda.dart';
import '../domain/simulacion.dart';

/// Listado de deudas (todas; la pantalla separa activas/historial).
final AsyncNotifierProvider<DeudasController, List<Deuda>> deudasProvider =
    AsyncNotifierProvider<DeudasController, List<Deuda>>(
      DeudasController.new,
    );

class DeudasController extends AsyncNotifier<List<Deuda>> {
  @override
  Future<List<Deuda>> build() {
    return ref.read(deudasRepositoryProvider).listar();
  }

  Future<void> refrescar() async {
    state = const AsyncLoading<List<Deuda>>();
    state = await AsyncValue.guard(
      () => ref.read(deudasRepositoryProvider).listar(),
    );
  }
}

/// Detalle de una deuda (`GET /deudas/{id}`).
final deudaDetalleProvider = FutureProvider.family<Deuda, int>((
  Ref ref,
  int id,
) {
  return ref.watch(deudasRepositoryProvider).detalle(id);
});

/// Cronograma de una deuda (`GET /deudas/{id}/amortizacion`).
final amortizacionProvider = FutureProvider.family<List<CuotaAmortizacion>, int>((
  Ref ref,
  int id,
) {
  return ref.watch(deudasRepositoryProvider).amortizacion(id);
});

/// Estados del formulario de alta/edición de deuda.
sealed class DeudaFormUiState {
  const DeudaFormUiState();
}

class DeudaFormIdle extends DeudaFormUiState {
  const DeudaFormIdle();
}

class DeudaFormSubmitting extends DeudaFormUiState {
  const DeudaFormSubmitting();
}

/// `VALIDACION_FALLIDA`: `campo → mensaje`.
class DeudaFormFieldErrors extends DeudaFormUiState {
  const DeudaFormFieldErrors(this.errors, {this.global});

  final Map<String, String> errors;
  final String? global;
}

class DeudaFormError extends DeudaFormUiState {
  const DeudaFormError({required this.failure});

  final AppFailure failure;

  String get message => failureMessage(failure);
}

class DeudaFormSuccess extends DeudaFormUiState {
  const DeudaFormSuccess(this.deuda);

  final Deuda deuda;
}

final NotifierProvider<DeudaFormController, DeudaFormUiState>
deudaFormProvider = NotifierProvider<DeudaFormController, DeudaFormUiState>(
  DeudaFormController.new,
);

class DeudaFormController extends Notifier<DeudaFormUiState> {
  @override
  DeudaFormUiState build() => const DeudaFormIdle();

  void reset() {
    state = const DeudaFormIdle();
  }

  /// Crea (`id == null`) o edita una deuda. El backend responde 409 si la
  /// deuda ya tiene pagos y se intentan cambiar las condiciones.
  Future<void> submit({required DeudaCreacion deuda, int? id}) async {
    if (state is DeudaFormSubmitting) {
      return;
    }
    state = const DeudaFormSubmitting();
    final DeudasRepository repository = ref.read(deudasRepositoryProvider);
    try {
      final Deuda resultado = id == null
          ? await repository.crear(deuda)
          : await repository.editar(id, deuda);
      state = DeudaFormSuccess(resultado);
    } on ValidationFailure catch (failure) {
      state = _fieldErrors(failure.errors);
    } on AppFailure catch (failure) {
      state = DeudaFormError(failure: failure);
    }
  }

  DeudaFormFieldErrors _fieldErrors(List<FieldError> errors) {    const Set<String> known = <String>{
      'nombre',
      'descripcion',
      'tipoDeuda',
      'cuotasPagadasPrevias',
      'condiciones.montoCapital',
      'condiciones.cantidadCuotas',
      'condiciones.fechaPrimeraCuota',
      'condiciones.fechaUltimaCuota',
      'condiciones.tasaMensual',
      'condiciones.tasaAnualEfectiva',
      'condiciones.valorCuota',
      'condiciones.gastosIniciales',
      'condiciones.costoAdicionalPorCuota',
    };
    final Map<String, String> mapped = <String, String>{};
    final List<String> unknown = <String>[];
    for (final FieldError error in errors) {
      if (known.contains(error.field)) {
        mapped[error.field] = error.message;
      } else {
        unknown.add(error.message);
      }
    }
    return DeudaFormFieldErrors(
      mapped,
      global: unknown.isEmpty ? null : unknown.join(' '),
    );
  }
}

/// Acciones destructivas/de pago sobre una deuda.
///
/// Devuelve la falla para que el diálogo la muestre; `null` = éxito. Al pagar
/// se invalida `movimientosProvider` porque el backend crea un `PAGO_DEUDA` y
/// el home debe refrescar saldo y listado al volver.
final NotifierProvider<DeudaAccionesController, AsyncValue<void>>
deudaAccionesProvider =
    NotifierProvider<DeudaAccionesController, AsyncValue<void>>(
      DeudaAccionesController.new,
    );

class DeudaAccionesController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  void reset() {
    state = const AsyncData<void>(null);
  }

  Future<AppFailure?> pagar(
    int id, {
    Decimal? monto,
    required ModoPago modo,
    required String descripcion,
  }) async {
    state = const AsyncLoading<void>();
    try {
      await ref
          .read(deudasRepositoryProvider)
          .pagar(id, monto: monto, modo: modo, descripcion: descripcion);
      state = const AsyncData<void>(null);
      ref.invalidate(movimientosProvider);
      return null;
    } on AppFailure catch (failure, stack) {
      state = AsyncError<void>(failure, stack);
      return failure;
    }
  }

  Future<AppFailure?> cancelar(int id) async {
    state = const AsyncLoading<void>();
    try {
      await ref.read(deudasRepositoryProvider).cancelar(id);
      state = const AsyncData<void>(null);
      return null;
    } on AppFailure catch (failure, stack) {
      state = AsyncError<void>(failure, stack);
      return failure;
    }
  }
}

/// Estado del historial paginado de pagos de una deuda.
class PagosDeudaState {
  const PagosDeudaState({
    this.deudaId,
    this.items = const <PagoDeuda>[],
    this.page = 0,
    this.totalPages = 0,
    this.totalItems = 0,
    this.cargando = false,
    this.cargandoMas = false,
    this.error,
  });

  final int? deudaId;
  final List<PagoDeuda> items;
  final int page;
  final int totalPages;
  final int totalItems;
  final bool cargando;
  final bool cargandoMas;
  final AppFailure? error;

  bool get hayMas => page + 1 < totalPages;
}

final NotifierProvider<PagosDeudaController, PagosDeudaState>
pagosDeudaProvider =
    NotifierProvider<PagosDeudaController, PagosDeudaState>(
      PagosDeudaController.new,
    );

class PagosDeudaController extends Notifier<PagosDeudaState> {
  @override
  PagosDeudaState build() => const PagosDeudaState();

  /// Carga la primera página (solo si cambió la deuda o se fuerza).
  Future<void> cargar(int deudaId, {bool forzar = false}) async {
    if (!forzar && state.deudaId == deudaId && state.items.isNotEmpty) {
      return;
    }
    state = PagosDeudaState(deudaId: deudaId, cargando: true);
    await _cargarPagina(deudaId, 0, reemplazar: true);
  }

  Future<void> cargarMas() async {
    final int? deudaId = state.deudaId;
    if (deudaId == null || !state.hayMas || state.cargando || state.cargandoMas) {
      return;
    }
    await _cargarPagina(deudaId, state.page + 1, reemplazar: false);
  }

  Future<void> _cargarPagina(
    int deudaId,
    int page, {
    required bool reemplazar,
  }) async {
    state = PagosDeudaState(
      deudaId: deudaId,
      items: state.items,
      page: state.page,
      totalPages: state.totalPages,
      totalItems: state.totalItems,
      cargando: page == 0,
      cargandoMas: page > 0,
    );
    try {
      final PaginaPagos pagina = await ref
          .read(deudasRepositoryProvider)
          .pagos(deudaId, page: page);
      final List<PagoDeuda> items = reemplazar
          ? pagina.content
          : <PagoDeuda>[...state.items, ...pagina.content];
      state = PagosDeudaState(
        deudaId: deudaId,
        items: items,
        page: pagina.currentPage,
        totalPages: pagina.totalPages,
        totalItems: pagina.totalItems,
      );
    } on AppFailure catch (failure) {
      state = PagosDeudaState(
        deudaId: deudaId,
        items: state.items,
        page: state.page,
        totalPages: state.totalPages,
        totalItems: state.totalItems,
        error: failure,
      );
    }
  }
}

/// Estados del simulador.
sealed class SimulacionUiState {
  const SimulacionUiState();
}

class SimulacionIdle extends SimulacionUiState {
  const SimulacionIdle();
}

class SimulacionSubmitting extends SimulacionUiState {
  const SimulacionSubmitting();
}

class SimulacionError extends SimulacionUiState {
  const SimulacionError({required this.failure});

  final AppFailure failure;

  String get message => failureMessage(failure);
}

class SimulacionSuccess extends SimulacionUiState {
  const SimulacionSuccess(this.resultado);

  final SimulacionResultado resultado;
}

final NotifierProvider<SimulacionController, SimulacionUiState>
simulacionProvider =
    NotifierProvider<SimulacionController, SimulacionUiState>(
      SimulacionController.new,
    );

class SimulacionController extends Notifier<SimulacionUiState> {
  @override
  SimulacionUiState build() => const SimulacionIdle();

  void reset() {
    state = const SimulacionIdle();
  }

  Future<void> simular(SimulacionRequest request) async {
    if (state is SimulacionSubmitting) {
      return;
    }
    state = const SimulacionSubmitting();
    try {
      final SimulacionResultado resultado = await ref
          .read(simuladorRepositoryProvider)
          .simular(request);
      state = SimulacionSuccess(resultado);
    } on AppFailure catch (failure) {
      state = SimulacionError(failure: failure);
    }
  }
}
