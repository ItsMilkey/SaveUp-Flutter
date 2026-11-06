# F2 — Cuenta, perfil y seguridad

> **Avance (2026-11-06):** entregables 1 y 2 hechos.
> - **1. Cambio de contraseña** (`PUT /usuarios/me/contrasena`) con cierre de
>   sesión local vía `AuthSessionController.endSessionLocally()` (sin
>   `/auth/logout`: el backend ya revoca todas las sesiones).
> - **2. Recuperación y restablecimiento** (`POST /auth/recuperar-contrasena` /
>   `auth/restablecer-contrasena`): rutas públicas `/recuperar-contrasena` y
>   `/restablecer-contrasena`, aviso del envío pendiente
>   (`app.mail.enabled=false`), mensaje genérico anti-enumeración y
>   `TOKEN_VERIFICACION_INVALIDO` inline al campo token con vía de
>   re-solicitud. Checklist de política extraído a
>   `auth/presentation/password_policy_checklist.dart` (una sola copia).
> - **3. Eliminación de cuenta** (`DELETE /usuarios/me` con `{contrasena}`,
>   204 sin cuerpo): diálogo defensivo de dos pasos (advertencia de
>   irreversibilidad → confirmación por contraseña), `CREDENCIALES_INVALIDAS`
>   inline en el input con reintento, `endSessionLocally()` al éxito y aviso
>   "Tu cuenta ha sido eliminada permanentemente." en `/login`.
> - **4. Visor legal** (`/legales`, público y accesible también con sesión):
>   pestañas Términos/Privacidad alimentadas por `legalVersionsProvider`,
>   texto provisional marcado (contenido oficial pendiente de fuente) y pie
>   con las versiones del servidor. Corrección de redirect: `/legales` debe
>   permitirse tanto sin como con sesión (antes el `isAuthRoute` la rebotaba
>   a home cuando había sesión).
> - `flutter analyze` sin issues; 189 tests en verde. Alcance de código
>   completo.
> **Verificación manual integral (2026-11-06, emulador `emulator-5554`,
> backend local real, protocolo `adb` + capturas): PASÓ COMPLETA.**
> 1. Visor legal con sesión activa (`ana.demo1`): pestañas Términos/
>    Privacidad, versiones del backend y texto provisional ✓. Accesible
>    también desde login ✓.
> 2. Registro de `ana.demo2` (RUT `13580246-8`): checklist 4/4, aviso
>    "Cuenta creada" y correo precargado en login ✓.
> 3. Login `Demo1234` → home ✓.
> 4. Cambio de contraseña `Demo1234` → `NuevaClave1`: aviso del cierre de
>    sesión, redirección a `/login` con "Contraseña actualizada
>    correctamente…" y correo precargado; refresh token revocado en BD ✓;
>    re-login con la nueva clave → home ✓.
> 5. Recuperación: banner del envío pendiente visible ✓; solicitud 200
>    genérica → formulario del token; token obtenido del correo log-only
>    del backend (`CorreoService`) ✓.
> 6. Restablecimiento con token → `ClaveRestablecida1`: "Contraseña
>    restablecida con éxito…", login con la nueva clave → home ✓.
> 7. Eliminación de cuenta: diálogo 2 pasos; `CREDENCIALES_INVALIDAS` con
>    la clave vieja quedó inline en el input con el diálogo abierto ✓;
>    éxito con la clave correcta → "Tu cuenta ha sido eliminada
>    permanentemente." + `/login` con correo precargado; usuario borrado
>    de BD (3 → 2 filas) ✓; login posterior rechazado ("Correo o
>    contraseña incorrectos.") ✓.
> 8. Estado final restaurado: sesión activa de `ana.demo1` en home.

## Objetivo
Que una persona autenticada pueda cambiar su contraseña, eliminar su cuenta; y que sin
sesión pueda recuperar el acceso con un token de restablecimiento. Además, un visor de
Términos y Política de Privacidad alimentado por las versiones legales que F1 ya guarda.

## Prerrequisito
F1 terminada y commiteada (`ddbb0b0` + fix `802aca4`).

## Lecturas previas
`docs/CONTEXT.md` (Autenticación y sesión, Errores), `docs/contrato/CLIENTE_FLUTTER.md`
(secciones 2 y 3: contraseñas, recuperación y forzado de versión) y
`docs/contrato/openapi.json` (únicos endpoints válidos: ver abajo).

## Endpoints del contrato (no inventar otros)
- `PUT /usuarios/me/contrasena` — cuerpo `{contrasenaActual, nuevaContrasena}` → `200 {message}`.
- `DELETE /usuarios/me` — cuerpo `{contrasena}` → `204 Cuenta eliminada de forma permanente`.
- `POST /auth/recuperar-contrasena` — cuerpo `{email}` → `200 {message}` (público).
- `POST /auth/restablecer-contrasena` — cuerpo `{token, nuevaContrasena}` → `200 {message}` (público).

> Nota: el endpoint de solicitud de recuperación es `POST /auth/recuperar-contrasena`
> (no existe `solicitar-restablecimiento` en el contrato).

## Dependencias a agregar
Ninguna.

## Alcance — `lib/features/account/`

### 1. Dominio — `lib/features/account/domain/`
- `AccountRepository`: `cambiarContrasena(actual, nueva)`, `eliminarCuenta(contrasena)`,
  `solicitarRecuperacion(email)`, `restablecerContrasena(token, nueva)`.
- Reutilizar el validador de contraseña de F1 (`lib/features/auth/domain/validators.dart`):
  8–64 caracteres, al menos una letra y un número, máximo 72 bytes UTF-8. **No duplicarlo**;
  si hay que generalizarlo, moverlo a `core/` y actualizar sus usos.

### 2. Datos — `lib/features/account/data/`
DTOs escritos a mano según `openapi.json`:
- `PUT /usuarios/me/contrasena` con `{contrasenaActual, nuevaContrasena}`.
- `DELETE /usuarios/me` con `{contrasena}` (sí lleva cuerpo).
- `POST /auth/recuperar-contrasena` con `{email}`.
- `POST /auth/restablecer-contrasena` con `{token, nuevaContrasena}`.
- Todas las llamadas por el cliente de `core/network`; errores ya traducidos a `AppFailure`
  por `codigo`. Respuestas 200 son `{message}`; `204` no lleva cuerpo.

### 3. Cambio de contraseña (con sesión)
- Formulario: contraseña actual, nueva (con indicador de requisitos) y repetir nueva.
  Validar igualdad local antes de enviar.
- `CREDENCIALES_INVALIDAS` (401) → "La contraseña actual no es correcta".
- `VALIDACION_FALLIDA` (400) → mostrar `errores[]` junto a cada campo.
- **IMPORTANTE (comportamiento del backend): el cambio revoca TODAS las sesiones del
  usuario, incluida la de este dispositivo.** Al recibir 200: borrar los tokens locales,
  marcar la sesión `unauthenticated` y volver a `/login` con el aviso "Contraseña
  cambiada. Inicia sesión de nuevo." (no llamar `/auth/logout`: el refresh ya está
  revocado server-side).

### 4. Recuperación y restablecimiento (sin sesión)
- Pantalla "Olvidé mi contraseña" accesible desde `/login`:
  1. Formulario de correo → `POST /auth/recuperar-contrasena`.
  2. La respuesta es **siempre 200 genérico** (anti-enumeración): mostrar mensaje fijo
     "Si el correo está registrado, recibirás instrucciones." sin depender del resultado.
- **Banner permanente en esa pantalla** (exigido por la guía de consumo): el envío por
  email está **pendiente de activación** (`app.mail.enabled=false` por defecto). En modo
  desarrollo el token aparece en el texto del correo/logs del backend; en producción la
  solicitud responde igual pero no genera ni envía token. Redacción sugerida: "El envío
  por email aún no está activo; en desarrollo el token se registra en los logs del
  servidor." No prometer un comportamiento que el backend no tiene.
- Pantalla de restablecimiento: campo token (pegado por el usuario; vale 1 hora, un solo
  uso) + nueva contraseña con indicador de requisitos → `POST /auth/restablecer-contrasena`.
- `TOKEN_VERIFICACION_INVALIDO` (400) → "El token no es válido o ya expiró. Solicita uno
  nuevo", con botón para volver al paso 1.
- Éxito (200) → ir a `/login` con aviso "Contraseña restablecida" (el backend también
  revocó todas las sesiones). Precargar el correo si lo tenemos.

### 5. Eliminación de cuenta (con sesión)
- Entrada en la pantalla de cuenta (`/cuenta`, pantalla mínima propia de F2) y/o menú de
  home. **Modal defensivo de dos pasos**: advertencia del borrado permanente (sin
  recuperación) + campo de contraseña para confirmar → `DELETE /usuarios/me` con
  `{contrasena}`.
- `CREDENCIALES_INVALIDAS` → "La contraseña no es correcta". Cualquier otro error no
  cierra la cuenta y se muestra el fallo traducido.
- Éxito (204): **vaciar el `TokenStore` incondicionalmente** (aunque la pantalla se
  cierre antes), marcar sesión `unauthenticated` y redirigir a `/login` con aviso
  "Cuenta eliminada". El backend además invalida los refresh por cuenta eliminada.

### 6. Documentos legales
- Visor accesible desde login y home (registro y "¿Olvidaste tu contraseña?" no
  necesitan ser aún). Alimenta la pantalla con `legalVersionsProvider`
  (`features/app_version/presentation/app_version_controller.dart`), que F1 ya llena con
  `versionTerminos`/`versionPrivacidad` de `GET /app/version`.
- **Open (consultar antes de implementar): la fuente del contenido.** El contrato solo
  entrega números de versión; no existe endpoint ni URL de documentos. Decidir con el
  usuario: ¿texto fijo provisional en la app, asset local o contenido del backend a
  futuro? Mientras tanto, el visor muestra versión vigente y texto provisional marcado.

## Seguridad
- Nada de contraseñas ni tokens en logs o `print`; la contraseña vive solo en memoria
  durante el envío. Campos de contraseña con ocultar/mostrar.
- `legalVersionsProvider` solo transporta strings de versión, no contenido sensible.

## Pruebas
- DTOs con adaptador falso: cuerpos exactos; `204` sin cuerpo se maneja sin excepción.
- Cambio de contraseña: éxito cierra sesión y avisa; `CREDENCIALES_INVALIDAS` y
  `VALIDACION_FALLIDA` muestreados por campo; contraseñas distintas detectadas localmente.
- Recuperación: respuesta genérica igual aunque el backend devuelva lo que devuelva;
  banner visible; reenvío desde `TOKEN_VERIFICACION_INVALIDO`.
- Eliminación: modal exige contraseña; éxito limpia tokens (verificar `TokenStore`
  vacío), incluso si la pantalla se desmonta antes del 204.
- Router: `/cuenta/*` privadas (rebote a login sin sesión); `/recuperar` y
  `/restablecer` públicas; visor de legales accesible sin sesión y con sesión.

## Fuera de alcance
Perfil editable (nombre/apellido/email), correo real (`app.mail.enabled=true`), deep link
`url-restablecer`, notificaciones, biometría, pantallas F3 (dashboard).

## Criterios de aceptación
- `flutter analyze` sin issues y `flutter test` en verde.
- Flujo manual en emulador: cambio de contraseña → vuelta a login → login con la nueva;
  recuperación → restablecimiento con token del log del backend → login con la nueva;
  eliminación de cuenta (con un usuario desechable, no `ana.demo1`) → vuelta a login y
  login rechazado. Si algo no se pudo ejecutar en dispositivo, **decirlo explícitamente**.
- No existen `print`, ni logs de credenciales, ni `double` de dinero.

## Entrega
Commits locales: `feat(account): cambio de contrasena y eliminacion de cuenta` y
`feat(account): recuperacion de contrasena y legales` (o uno solo si el lote es pequeño).
Resumen: archivos, decisiones (fuente del contenido legal), pruebas y TODOs abiertos.
