import 'user_profile.dart';

/// Estado de autenticación de la app.
///
/// Arranca en [SessionUnknown]: todavía no se sabe si hay una sesión guardada
/// ni si sus tokens sirven. El arranque (splash) lo resuelve.
sealed class AuthSession {
  const AuthSession();
}

/// Aún no se resolvió si hay sesión (splash en curso o reintento pendiente).
class SessionUnknown extends AuthSession {
  const SessionUnknown();
}

/// No hay sesión válida: la app muestra el login.
class SessionUnauthenticated extends AuthSession {
  const SessionUnauthenticated({this.sessionExpired = false});

  /// `true` si la sesión existía y dejó de ser válida (refresh rechazado).
  ///
  /// La pantalla de login lo usa para avisar "Tu sesión expiró".
  final bool sessionExpired;
}

/// Hay sesión válida con el perfil del usuario.
class SessionAuthenticated extends AuthSession {
  const SessionAuthenticated(this.user);

  /// Perfil cargado desde `GET /usuarios/me`.
  final UserProfile user;
}
