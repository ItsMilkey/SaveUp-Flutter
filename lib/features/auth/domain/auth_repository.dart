import 'user_profile.dart';

/// Acceso a las operaciones de cuenta y sesión.
///
/// Implementado por `DioAuthRepository`; los presentadores dependen solo de
/// esta interfaz para poder probarse sin red.
abstract interface class AuthRepository {
  /// `POST /usuarios/register`.
  ///
  /// **No inicia sesión**: el backend responde `200 { message }` y no entrega
  /// tokens. Para entrar hay que hacer [login] después.
  Future<void> register({
    required String rut,
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  });

  /// `POST /usuarios/login` + `GET /usuarios/me`.
  ///
  /// Guarda el par de tokens en el [TokenStore] y devuelve el perfil que
  /// entrega el backend (el login no lo incluye en su respuesta).
  Future<UserProfile> login({required String email, required String password});

  /// `POST /auth/logout` con el refresh token guardado y borra los tokens.
  ///
  /// Nunca falla por un problema de red: la sesión local se cierra igual.
  Future<void> logout();

  /// `GET /usuarios/me`. Devuelve `null` si no hay tokens guardados.
  Future<UserProfile?> currentUser();

  /// `true` si hay un par de tokens guardado (no comprueba su validez).
  Future<bool> hasSession();
}
