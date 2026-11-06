import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../data/dio_movimientos_repository.dart';
import '../domain/movimiento.dart';
import '../domain/movimiento_tipo.dart';
import '../domain/movimientos_repository.dart';

/// Estados de la alta mínima de movimiento.
sealed class NuevoMovimientoUiState {
  const NuevoMovimientoUiState();
}

class NuevoMovimientoIdle extends NuevoMovimientoUiState {
  const NuevoMovimientoIdle();
}

class NuevoMovimientoSubmitting extends NuevoMovimientoUiState {
  const NuevoMovimientoSubmitting();
}

/// `VALIDACION_FALLIDA`: errores por campo (`descripcion`, `monto`,
/// `categoriaId`).
class NuevoMovimientoFieldErrors extends NuevoMovimientoUiState {
  const NuevoMovimientoFieldErrors(this.errors, {this.global});

  final Map<String, String> errors;
  final String? global;
}

class NuevoMovimientoError extends NuevoMovimientoUiState {
  const NuevoMovimientoError({required this.failure});

  final AppFailure failure;

  String get message => failureMessage(failure);
}

/// Éxito: [actualizado] viene de un `PUT` (edición); `null` significa alta.
class NuevoMovimientoSuccess extends NuevoMovimientoUiState {
  const NuevoMovimientoSuccess({this.actualizado});

  final Movimiento? actualizado;
}

final NotifierProvider<NuevoMovimientoController, NuevoMovimientoUiState>
nuevoMovimientoProvider =
    NotifierProvider<NuevoMovimientoController, NuevoMovimientoUiState>(
      NuevoMovimientoController.new,
    );

class NuevoMovimientoController extends Notifier<NuevoMovimientoUiState> {
  @override
  NuevoMovimientoUiState build() => const NuevoMovimientoIdle();

  void reset() {
    state = const NuevoMovimientoIdle();
  }

  /// `POST /movimientos`. El backend no recibe fecha: usa el instante actual.
  Future<void> submit({
    required Decimal monto,
    required String descripcion,
    required MovimientoTipo tipo,
    int? categoriaId,
  }) async {
    if (state is NuevoMovimientoSubmitting) {
      return;
    }
    state = const NuevoMovimientoSubmitting();
    final MovimientosRepository repository = ref.read(
      movimientosRepositoryProvider,
    );
    try {
      await repository.registrar(
        monto: monto,
        descripcion: descripcion.trim(),
        tipo: tipo,
        categoriaId: categoriaId,
      );
      state = const NuevoMovimientoSuccess();
    } on ValidationFailure catch (failure) {
      state = _fieldErrors(failure.errors);
    } on AppFailure catch (failure) {
      state = NuevoMovimientoError(failure: failure);
    }
  }

  /// `PUT /movimientos/{id}` (edición parcial). El tipo no viaja: el contrato
  /// no lo permite cambiar.
  Future<void> editar({
    required int id,
    Decimal? monto,
    String? descripcion,
    int? categoriaId,
  }) async {
    if (state is NuevoMovimientoSubmitting) {
      return;
    }
    state = const NuevoMovimientoSubmitting();
    final MovimientosRepository repository = ref.read(
      movimientosRepositoryProvider,
    );
    try {
      final Movimiento actualizado = await repository.editar(
        id: id,
        monto: monto,
        descripcion: descripcion?.trim(),
        categoriaId: categoriaId,
      );
      state = NuevoMovimientoSuccess(actualizado: actualizado);
    } on ValidationFailure catch (failure) {
      state = _fieldErrors(failure.errors);
    } on AppFailure catch (failure) {
      state = NuevoMovimientoError(failure: failure);
    }
  }

  NuevoMovimientoFieldErrors _fieldErrors(List<FieldError> errors) {
    const Set<String> known = <String>{'descripcion', 'monto', 'categoriaId'};
    final Map<String, String> mapped = <String, String>{};
    final List<String> unknown = <String>[];
    for (final FieldError error in errors) {
      if (known.contains(error.field)) {
        mapped[error.field] = error.message;
      } else {
        unknown.add(error.message);
      }
    }
    return NuevoMovimientoFieldErrors(
      mapped,
      global: unknown.isEmpty ? null : unknown.join(' '),
    );
  }
}
