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
}
