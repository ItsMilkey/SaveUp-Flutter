import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../data/dio_deudas_repository.dart';
import '../domain/deuda.dart';
import '../domain/deudas_repository.dart';

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

  DeudaFormFieldErrors _fieldErrors(List<FieldError> errors) {
    const Set<String> known = <String>{
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
