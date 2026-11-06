import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/network/token_store.dart';
import '../data/dio_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/user_profile.dart';
import '../domain/validators.dart';

/// Estado global de sesión de la app.
///
/// Arranca en `unknown`; el splash lo resuelve con [bootstrap]. El router
/// escucha este estado para decidir la ruta.
final NotifierProvider<AuthSessionController, AuthSession> authSessionProvider =
    NotifierProvider<AuthSessionController, AuthSession>(
      AuthSessionController.new,
    );

class AuthSessionController extends Notifier<AuthSession> {
  @override
  AuthSession build() => const SessionUnknown();

  /// Resuelve la sesión guardada al arrancar (splash).
  ///
  /// - Sin tokens → unauthenticated.
  /// - Con tokens y `/usuarios/me` válido → authenticated con perfil.
  /// - `REFRESH_INVALIDO` u otra falla de autenticación (el interceptor ya
  ///   borró los tokens) → unauthenticated.
  /// - Red o timeout → conserva la sesión posible y devuelve la falla para
  ///   que el splash ofrezca reintentar (no se cierra sesión por conectividad).
  Future<AppFailure?> bootstrap() async {
    final AuthRepository repository = ref.read(authRepositoryProvider);
    try {
      final UserProfile? profile = await repository.currentUser();
      state = profile == null
          ? const SessionUnauthenticated()
          : SessionAuthenticated(profile);
      return null;
    } on NetworkFailure catch (failure) {
      return failure;
    } on TimeoutFailure catch (failure) {
      return failure;
    } on AppFailure {
      state = const SessionUnauthenticated();
      return null;
    }
  }

  /// Incorpora la sesión recién autenticada (login exitoso): el router
  /// reacciona a este cambio y desaloja las rutas de acceso.
  void adoptSession(UserProfile user) {
    state = SessionAuthenticated(user);
  }

  /// El evento viene de `core/network` (refresh rechazado): volver al login
  /// con aviso, sea cual sea el estado previo.
  void markSessionExpired() {
    state = const SessionUnauthenticated(sessionExpired: true);
  }

  /// Quita la marca de aviso (lo muestra la pantalla de login una sola vez).
  void clearExpiredNotice() {
    final AuthSession current = state;
    if (current is SessionUnauthenticated && current.sessionExpired) {
      state = const SessionUnauthenticated();
    }
  }

  /// Cerrar sesión: `POST /auth/logout` + borrado local de tokens aunque la
  /// llamada falle (el repositorio nunca lanza por red).
  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      state = const SessionUnauthenticated();
    }
  }

  /// Termina la sesión **sin llamar a `/auth/logout`**: el backend ya revocó
  /// todos los tokens del usuario (cambio o restablecimiento de contraseña,
  /// cuenta eliminada). Solo vacía el `TokenStore` y desaloja las rutas
  /// privadas vía el router.
  Future<void> endSessionLocally() async {
    await ref.read(tokenStoreProvider).clear();
    state = const SessionUnauthenticated();
  }
}

/// UI del formulario de login.
sealed class LoginUiState {
  const LoginUiState();
}

class LoginIdle extends LoginUiState {
  const LoginIdle({this.correo = ''});

  /// Correo precargado (p. ej. al volver desde el registro).
  final String correo;
}

class LoginSubmitting extends LoginUiState {
  const LoginSubmitting({required this.correo, required this.contrasena});

  final String correo;

  /// Contraseña en memoria solo mientras viaja la petición.
  final String contrasena;
}

/// Falla con mensaje listo para mostrar (por `codigo`).
class LoginError extends LoginUiState {
  const LoginError({required this.correo, required this.failure});

  final String correo;
  final AppFailure failure;

  String get message => failureMessage(failure);
}

/// `429 INTENTOS_LOGIN_EXCEDIDOS`: bloqueo de 15 minutos.
class LoginBlocked extends LoginUiState {
  const LoginBlocked();
}

/// Éxito: el router redirige a `/home`.
class LoginSuccess extends LoginUiState {
  const LoginSuccess();
}

/// Mensaje descartable recibido de otra pantalla (p. ej. cuenta creada).
class LoginNotice extends LoginUiState {
  const LoginNotice({required this.correo, required this.message});

  final String correo;
  final String message;
}

final NotifierProvider<LoginController, LoginUiState> loginProvider =
    NotifierProvider<LoginController, LoginUiState>(LoginController.new);

class LoginController extends Notifier<LoginUiState> {
  @override
  LoginUiState build() {
    return const LoginIdle();
  }

  /// Precarga la pantalla de login (correo conocido, aviso).
  void preload({required String correo, required String message}) {
    state = LoginNotice(correo: correo, message: message);
  }

  /// Limpia el aviso, conservando el correo precargado.
  void consumeNotice() {
    final LoginUiState current = state;
    if (current is LoginNotice) {
      state = LoginIdle(correo: current.correo);
    }
  }

  /// Reintento manual después de un bloqueo: vuelve a habilitar el formulario.
  void retryAfterBlock({required String correo}) {
    if (state is LoginBlocked) {
      state = LoginIdle(correo: correo);
    }
  }

  /// Envía `POST /usuarios/login`. La sesión es global: el router decidirá.
  Future<void> submit({
    required String correo,
    required String contrasena,
  }) async {
    if (state is LoginSubmitting) {
      return;
    }
    state = LoginSubmitting(correo: correo, contrasena: contrasena);
    try {
      final UserProfile profile = await ref
          .read(authRepositoryProvider)
          .login(email: correo.trim(), password: contrasena);
      ref.read(authSessionProvider.notifier).adoptSession(profile);
      state = const LoginSuccess();
    } on AppFailure catch (failure) {
      // Volver a idle luego de failure evita remitir con el mismo error;
      // la contraseña no se conserva.
      if (failure is LoginBlockedFailure) {
        state = const LoginBlocked();
        return;
      }
      state = LoginError(correo: correo, failure: failure);
    }
  }
}

/// UI del formulario de registro.
sealed class RegisterUiState {
  const RegisterUiState();
}

class RegisterIdle extends RegisterUiState {
  const RegisterIdle();
}

class RegisterSubmitting extends RegisterUiState {
  const RegisterSubmitting();
}

/// `VALIDACION_FALLIDA`: errores por campo `campo → mensaje`.
class RegisterFieldErrors extends RegisterUiState {
  const RegisterFieldErrors(this.errors, {this.global});

  final Map<String, String> errors;

  /// Mensaje para campos que el formulario no conoce.
  final String? global;
}

/// Falla con mensaje único (p. ej. `USUARIO_YA_REGISTRADO`).
class RegisterError extends RegisterUiState {
  const RegisterError({required this.failure});

  final AppFailure failure;

  String get message => failureMessage(failure);
}

/// Éxito: se lleva a login con el correo precargado (register no inicia
/// sesión); la persona ejecuta el único intento de login.
class RegisterSuccess extends RegisterUiState {
  const RegisterSuccess(this.correo);

  final String correo;
}

final NotifierProvider<RegisterController, RegisterUiState> registerProvider =
    NotifierProvider<RegisterController, RegisterUiState>(
      RegisterController.new,
    );

class RegisterController extends Notifier<RegisterUiState> {
  @override
  RegisterUiState build() => const RegisterIdle();

  Future<void> submit({
    required String rut,
    required String nombre,
    required String apellido,
    required String email,
    required String contrasena,
  }) async {
    if (state is RegisterSubmitting) {
      return;
    }
    state = const RegisterSubmitting();
    final AuthRepository repository = ref.read(authRepositoryProvider);
    try {
      await repository.register(
        rut: normalizeRut(rut),
        nombre: nombre.trim(),
        apellido: apellido.trim(),
        email: email.trim(),
        password: contrasena,
      );
      ref
          .read(loginProvider.notifier)
          .preload(
            correo: email.trim(),
            message: 'Cuenta creada. Ahora inicia sesión.',
          );
      state = RegisterSuccess(email.trim());
    } on ValidationFailure catch (failure) {
      state = _fieldErrors(failure.errors);
    } on AppFailure catch (failure) {
      state = RegisterError(failure: failure);
    }
  }

  RegisterFieldErrors _fieldErrors(List<FieldError> errors) {
    const Set<String> known = <String>{
      'rut',
      'nombre',
      'apellido',
      'email',
      'contrasena',
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
    return RegisterFieldErrors(
      mapped,
      global: unknown.isEmpty ? null : unknown.join(' '),
    );
  }
}
