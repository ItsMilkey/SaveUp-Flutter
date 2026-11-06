/// Operaciones de cuenta del usuario autenticado (F2).
///
/// La forma de cada campo viene de `docs/contrato/openapi.json`. Los errores
/// llegan ya traducidos a `AppFailure` (por `codigo`) desde la capa de datos.
abstract interface class AccountRepository {
  /// Cambia la contraseña con sesión activa (`PUT /usuarios/me/contrasena`).
  ///
  /// El backend, al aceptar el cambio, revoca **todas** las sesiones del
  /// usuario — incluida la de este dispositivo. Quien llama debe terminar la
  /// sesión local inmediatamente después del `200` (el refresh token ya no
  /// sirve, así que NO corresponde llamar `/auth/logout`).
  Future<void> cambiarContrasena({
    required String contrasenaActual,
    required String nuevaContrasena,
  });

  /// Solicita la recuperación de la contraseña sin sesión
  /// (`POST /auth/recuperar-contrasena`).
  ///
  /// El backend responde **siempre 200 genérico** (anti-enumeración): igual
  /// para correos registrados o no. Con el envío por correo desactivado
  /// (`app.mail.enabled=false`, el caso por defecto) responde igual pero no
  /// genera ni envía token; en desarrollo el token queda en los logs.
  Future<void> solicitarRecuperacion({required String email});

  /// Restablece la contraseña con el token de un solo uso
  /// (`POST /auth/restablecer-contrasena`).
  ///
  /// El token vale 1 hora y un solo uso; al éxito el backend revoca **todas**
  /// las sesiones del usuario. `400 TOKEN_VERIFICACION_INVALIDO` si el token
  /// es inválido, ya se usó o expiró.
  Future<void> restablecerContrasena({
    required String token,
    required String nuevaContrasena,
  });
}
