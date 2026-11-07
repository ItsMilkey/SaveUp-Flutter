import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../data/dio_metas_repository.dart';
import '../../domain/meta_ahorro.dart';
import '../../domain/metas_repository.dart';
import 'metas_controller.dart';

/// Estados del formulario de alta/edición de meta.
sealed class MetaFormUiState {
  const MetaFormUiState();
}

class MetaFormIdle extends MetaFormUiState {
  const MetaFormIdle();
}

class MetaFormSubmitting extends MetaFormUiState {
  const MetaFormSubmitting();
}

/// `VALIDACION_FALLIDA`: `campo → mensaje`.
class MetaFormFieldErrors extends MetaFormUiState {
  const MetaFormFieldErrors(this.errors, {this.global});

  final Map<String, String> errors;
  final String? global;
}

class MetaFormError extends MetaFormUiState {
  const MetaFormError({required this.failure});

  final AppFailure failure;

  String get message => failureMessage(failure);
}

class MetaFormSuccess extends MetaFormUiState {
  const MetaFormSuccess(this.meta);

  final MetaAhorro meta;
}

final NotifierProvider<MetaFormController, MetaFormUiState> metaFormProvider =
    NotifierProvider<MetaFormController, MetaFormUiState>(
      MetaFormController.new,
    );

class MetaFormController extends Notifier<MetaFormUiState> {
  @override
  MetaFormUiState build() => const MetaFormIdle();

  void reset() {
    state = const MetaFormIdle();
  }

  /// Crea (`id == null`) o edita una meta.
  Future<void> submit({
    required MetaAhorroDatos datos,
    int? id,
  }) async {
    if (state is MetaFormSubmitting) {
      return;
    }
    state = const MetaFormSubmitting();
    final MetasRepository repository = ref.read(metasRepositoryProvider);
    try {
      final MetaAhorro resultado = id == null
          ? await repository.crear(datos)
          : await repository.editar(id, datos);
      state = MetaFormSuccess(resultado);
      ref.invalidate(metasProvider);
    } on ValidationFailure catch (failure) {
      state = _fieldErrors(failure.errors);
    } on AppFailure catch (failure) {
      state = MetaFormError(failure: failure);
    }
  }

  MetaFormFieldErrors _fieldErrors(List<FieldError> errors) {
    const Set<String> known = <String>{
      'nombre',
      'montoObjetivo',
      'fechaLimite',
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
    return MetaFormFieldErrors(
      mapped,
      global: unknown.isEmpty ? null : unknown.join(' '),
    );
  }
}
