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

/// Aviso que verá la persona en `/login` tras restablecer la contraseña.
const String avisoContrasenaRestablecida =
    'Contraseña restablecida con éxito. Ingresa con tu nueva clave.';

/// Mensaje genérico anti-enumeración de la solicitud de recuperación.
const String mensajeInstruccionesRestablecimiento =
    'Si la cuenta existe, se generó la instrucción de restablecimiento.';

/// Aviso fijo del envío pendiente (contrato: `app.mail.enabled=false`).
const String avisoEnvioCorreoPendiente =
    'La entrega del token por correo está pendiente de activación en el '
    'servidor. Durante pruebas, el token queda en los registros (logs) del '
    'backend y en el correo de desarrollo.';

/// Aviso del login tras eliminar la cuenta.
const String avisoCuentaEliminada =
    'Tu cuenta ha sido eliminada permanentemente.';

/// Estados de la UI del diálogo de eliminación de cuenta.
sealed class EliminarCuentaUiState {
  const EliminarCuentaUiState();
}

class EliminarCuentaIdle extends EliminarCuentaUiState {
  const EliminarCuentaIdle();
}

class EliminarCuentaSubmitting extends EliminarCuentaUiState {
  const EliminarCuentaSubmitting();
}

/// Contraseña rechazada (`CREDENCIALES_INVALIDAS` o `VALIDACION_FALLIDA` del
/// campo `contrasena`): va inline en el input del diálogo, que sigue abierto.
class EliminarCuentaContrasenaInvalida extends EliminarCuentaUiState {
  const EliminarCuentaContrasenaInvalida(this.message);

  final String message;
}

/// Otras fallas (red, servidor…): el diálogo también sigue abierto y la
/// persona puede reintentar o cancelar.
class EliminarCuentaError extends EliminarCuentaUiState {
  const EliminarCuentaError({required this.failure});

  final AppFailure failure;

  String get message => failureMessage(failure);
}

/// Éxito (204): sesión cerrada localmente; el router lleva a `/login` con el
/// aviso precargado.
class EliminarCuentaSuccess extends EliminarCuentaUiState {
  const EliminarCuentaSuccess();
}

final NotifierProvider<EliminarCuentaController, EliminarCuentaUiState>
eliminarCuentaProvider =
    NotifierProvider<EliminarCuentaController, EliminarCuentaUiState>(
      EliminarCuentaController.new,
    );

class EliminarCuentaController extends Notifier<EliminarCuentaUiState> {
  @override
  EliminarCuentaUiState build() => const EliminarCuentaIdle();

  /// Vuelve a `idle` al abrir el diálogo, para no heredar errores de una
  /// apertura anterior.
  void reset() {
    state = const EliminarCuentaIdle();
  }

  /// Envía `DELETE /usuarios/me` con la contraseña de confirmación.
  Future<void> submit({required String contrasena}) async {
    if (state is EliminarCuentaSubmitting) {
      return;
    }
    state = const EliminarCuentaSubmitting();
    final AccountRepository repository = ref.read(accountRepositoryProvider);
    try {
      await repository.eliminarCuenta(contrasena: contrasena);

      // La cuenta ya no existe: cerrar la sesión local por completo y
      // avisar en el login. No va `/auth/logout`; los refresh quedaron
      // inválidos por cuenta eliminada.
      final String correo = switch (ref.read(authSessionProvider)) {
        SessionAuthenticated(:final user) => user.email,
        _ => '',
      };
      await ref.read(authSessionProvider.notifier).endSessionLocally();
      ref
          .read(loginProvider.notifier)
          .preload(correo: correo, message: avisoCuentaEliminada);
      state = const EliminarCuentaSuccess();
    } on CredentialsInvalidFailure {
      state = const EliminarCuentaContrasenaInvalida(
        'La contraseña no es correcta.',
      );
    } on ValidationFailure catch (failure) {
      final String? mensaje = failure.errors
          .where((FieldError e) => e.field == 'contrasena')
          .map((FieldError e) => e.message)
          .firstOrNull;
      state = mensaje == null
          ? EliminarCuentaError(failure: failure)
          : EliminarCuentaContrasenaInvalida(mensaje);
    } on AppFailure catch (failure) {
      state = EliminarCuentaError(failure: failure);
    }
  }
}

/// Estados de la UI de solicitud de recuperación de contraseña.
sealed class SolicitudRecuperacionUiState {
  const SolicitudRecuperacionUiState();
}

class SolicitudRecuperacionIdle extends SolicitudRecuperacionUiState {
  const SolicitudRecuperacionIdle();
}

class SolicitudRecuperacionSubmitting extends SolicitudRecuperacionUiState {
  const SolicitudRecuperacionSubmitting();
}

/// Cualquier falla, con mensaje listo para mostrar (por `codigo`).
class SolicitudRecuperacionError extends SolicitudRecuperacionUiState {
  const SolicitudRecuperacionError({required this.failure});

  final AppFailure failure;

  String get message => failureMessage(failure);
}

/// Éxito (siempre 200 genérico): la pantalla navega al formulario del token
/// llevándose [correo] para precargarlo en el login final.
class SolicitudRecuperacionSuccess extends SolicitudRecuperacionUiState {
  const SolicitudRecuperacionSuccess(this.correo);

  final String correo;
}

final NotifierProvider<SolicitudRecuperacionController, SolicitudRecuperacionUiState>
solicitudRecuperacionProvider =
    NotifierProvider<SolicitudRecuperacionController, SolicitudRecuperacionUiState>(
      SolicitudRecuperacionController.new,
    );

class SolicitudRecuperacionController
    extends Notifier<SolicitudRecuperacionUiState> {
  @override
  SolicitudRecuperacionUiState build() => const SolicitudRecuperacionIdle();

  /// Envía `POST /auth/recuperar-contrasena`. La respuesta es genérica: no
  /// se informa si el correo existe o no (anti-enumeración del contrato).
  Future<void> submit({required String email}) async {
    if (state is SolicitudRecuperacionSubmitting) {
      return;
    }
    state = const SolicitudRecuperacionSubmitting();
    final AccountRepository repository = ref.read(accountRepositoryProvider);
    try {
      await repository.solicitarRecuperacion(email: email);
      state = SolicitudRecuperacionSuccess(email.trim());
    } on AppFailure catch (failure) {
      state = SolicitudRecuperacionError(failure: failure);
    }
  }
}

/// Estados de la UI del restablecimiento con token.
sealed class RestablecerContrasenaUiState {
  const RestablecerContrasenaUiState();
}

class RestablecerContrasenaIdle extends RestablecerContrasenaUiState {
  const RestablecerContrasenaIdle();
}

class RestablecerContrasenaSubmitting extends RestablecerContrasenaUiState {
  const RestablecerContrasenaSubmitting();
}

/// `VALIDACION_FALLIDA`: errores por campo `campo → mensaje`.
class RestablecerContrasenaFieldErrors extends RestablecerContrasenaUiState {
  const RestablecerContrasenaFieldErrors(this.errors, {this.global});

  final Map<String, String> errors;

  /// Mensaje para campos que el formulario no conoce.
  final String? global;
}

/// `TOKEN_VERIFICACION_INVALIDO` (400): token inválido, ya usado o expirado.
/// Va inline sobre el campo "Token", con vía de re-solicitud.
class RestablecerContrasenaTokenInvalido
    extends RestablecerContrasenaUiState {
  const RestablecerContrasenaTokenInvalido();

  String get message =>
      'El token no es válido o ya expiró. Solicita uno nuevo.';
}

/// Cualquier otra falla, con mensaje listo para mostrar (por `codigo`).
class RestablecerContrasenaError extends RestablecerContrasenaUiState {
  const RestablecerContrasenaError({required this.failure});

  final AppFailure failure;

  String get message => failureMessage(failure);
}

/// Éxito: el backend revocó todas las sesiones; se cierra la sesión local
/// (si existía) y se llega al login con el aviso precargado.
class RestablecerContrasenaSuccess extends RestablecerContrasenaUiState {
  const RestablecerContrasenaSuccess();
}

final NotifierProvider<RestablecerContrasenaController, RestablecerContrasenaUiState>
restablecerContrasenaProvider =
    NotifierProvider<RestablecerContrasenaController, RestablecerContrasenaUiState>(
      RestablecerContrasenaController.new,
    );

class RestablecerContrasenaController
    extends Notifier<RestablecerContrasenaUiState> {
  @override
  RestablecerContrasenaUiState build() => const RestablecerContrasenaIdle();

  /// Envía `POST /auth/restablecer-contrasena`.
  ///
  /// La política de contraseña y la igualdad de la repetición las valida el
  /// formulario; [correo] (opcional) precarga el login final.
  Future<void> submit({
    required String token,
    required String nuevaContrasena,
    String correo = '',
  }) async {
    if (state is RestablecerContrasenaSubmitting) {
      return;
    }
    state = const RestablecerContrasenaSubmitting();
    final AccountRepository repository = ref.read(accountRepositoryProvider);
    try {
      await repository.restablecerContrasena(
        token: token,
        nuevaContrasena: nuevaContrasena,
      );

      // El backend revocó todas las sesiones: cerrar la local por si la
      // persona estaba autenticada y avisar en el login.
      await ref.read(authSessionProvider.notifier).endSessionLocally();
      ref
          .read(loginProvider.notifier)
          .preload(correo: correo, message: avisoContrasenaRestablecida);
      state = const RestablecerContrasenaSuccess();
    } on ValidationFailure catch (failure) {
      state = _fieldErrors(failure.errors);
    } on BadRequestFailure catch (failure) {
      // Solo este `codigo` significa token inválido/usado/expirado; los
      // demás 400 con código estable van como error genérico.
      if (failure.codigo == 'TOKEN_VERIFICACION_INVALIDO') {
        state = const RestablecerContrasenaTokenInvalido();
      } else {
        state = RestablecerContrasenaError(failure: failure);
      }
    } on AppFailure catch (failure) {
      state = RestablecerContrasenaError(failure: failure);
    }
  }

  RestablecerContrasenaFieldErrors _fieldErrors(List<FieldError> errors) {
    const Set<String> known = <String>{'token', 'nuevaContrasena'};
    final Map<String, String> mapped = <String, String>{};
    final List<String> unknown = <String>[];
    for (final FieldError error in errors) {
      if (known.contains(error.field)) {
        mapped[error.field] = error.message;
      } else {
        unknown.add(error.message);
      }
    }
    return RestablecerContrasenaFieldErrors(
      mapped,
      global: unknown.isEmpty ? null : unknown.join(' '),
    );
  }
}

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
