import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/presentation/auth_controllers.dart';
import '../data/dio_account_repository.dart';
import '../domain/account_repository.dart';

/// Estados de la UI del formulario de cambio de contraseña.
sealed class CambiarContrasenaUiState {
  const CambiarContrasenaUiState();
}

class CambiarContrasenaIdle extends CambiarContrasenaUiState {
  const CambiarContrasenaIdle();
}

class CambiarContrasenaSubmitting extends CambiarContrasenaUiState {
  const CambiarContrasenaSubmitting();
}

/// `VALIDACION_FALLIDA`: errores por campo `campo → mensaje`.
class CambiarContrasenaFieldErrors extends CambiarContrasenaUiState {
  const CambiarContrasenaFieldErrors(this.errors, {this.global});

  final Map<String, String> errors;

  /// Mensaje para campos que el formulario no conoce.
  final String? global;
}

/// `CREDENCIALES_INVALIDAS`: la contraseña actual no coincide. Se muestra
/// inline en el campo "Contraseña actual", no como banner.
class CambiarContrasenaCurrentPasswordWrong extends CambiarContrasenaUiState {
  const CambiarContrasenaCurrentPasswordWrong();

  String get message => 'La contraseña actual no es correcta.';
}

/// Cualquier otra falla, con mensaje listo para mostrar (por `codigo`).
class CambiarContrasenaError extends CambiarContrasenaUiState {
  const CambiarContrasenaError({required this.failure});

  final AppFailure failure;

  String get message => failureMessage(failure);
}

/// Éxito: el backend ya revocó todas las sesiones; el controlador cierra la
/// sesión local y precarga el aviso en el login (el router redirige).
class CambiarContrasenaSuccess extends CambiarContrasenaUiState {
  const CambiarContrasenaSuccess();
}

/// Aviso que verá la persona en `/login` tras el cambio.
const String avisoContrasenaActualizada =
    'Contraseña actualizada correctamente. Por seguridad, inicia sesión '
    'nuevamente.';

final NotifierProvider<CambiarContrasenaController, CambiarContrasenaUiState>
cambiarContrasenaProvider =
    NotifierProvider<CambiarContrasenaController, CambiarContrasenaUiState>(
      CambiarContrasenaController.new,
    );

class CambiarContrasenaController
    extends Notifier<CambiarContrasenaUiState> {
  @override
  CambiarContrasenaUiState build() => const CambiarContrasenaIdle();

  /// Envía `PUT /usuarios/me/contrasena`.
  ///
  /// La igualdad entre la nueva contraseña y su repetición, y la política de
  /// contraseña, las valida el formulario: aquí solo viaja el par de campos.
  Future<void> submit({
    required String contrasenaActual,
    required String nuevaContrasena,
  }) async {
    if (state is CambiarContrasenaSubmitting) {
      return;
    }
    state = const CambiarContrasenaSubmitting();
    final AccountRepository repository = ref.read(accountRepositoryProvider);
    try {
      await repository.cambiarContrasena(
        contrasenaActual: contrasenaActual,
        nuevaContrasena: nuevaContrasena,
      );

      // El backend ya revocó todas las sesiones con el cambio: cerrar la
      // local (borra el TokenStore) y avisar en el login. No va
      // `/auth/logout`; el refresh token ya no existe server-side.
      state = const CambiarContrasenaSuccess();
      final String correo = switch (ref.read(authSessionProvider)) {
        SessionAuthenticated(:final user) => user.email,
        _ => '',
      };
      await ref.read(authSessionProvider.notifier).endSessionLocally();
      ref
          .read(loginProvider.notifier)
          .preload(correo: correo, message: avisoContrasenaActualizada);
    } on ValidationFailure catch (failure) {
      state = _fieldErrors(failure.errors);
    } on CredentialsInvalidFailure {
      state = const CambiarContrasenaCurrentPasswordWrong();
    } on AppFailure catch (failure) {
      state = CambiarContrasenaError(failure: failure);
    }
  }

  CambiarContrasenaFieldErrors _fieldErrors(List<FieldError> errors) {
    const Set<String> known = <String>{'contrasenaActual', 'nuevaContrasena'};
    final Map<String, String> mapped = <String, String>{};
    final List<String> unknown = <String>[];
    for (final FieldError error in errors) {
      if (known.contains(error.field)) {
        mapped[error.field] = error.message;
      } else {
        unknown.add(error.message);
      }
    }
    return CambiarContrasenaFieldErrors(
      mapped,
      global: unknown.isEmpty ? null : unknown.join(' '),
    );
  }
}
