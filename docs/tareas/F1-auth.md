# F1 — Autenticación, sesión y versión mínima

## Objetivo
Que una persona pueda registrarse, iniciar sesión, mantener la sesión entre aperturas de la
app y cerrar sesión; y que la app consulte la versión mínima al arrancar.

## Prerrequisito
F0 terminada y commiteada.

## Lecturas previas
`docs/CONTEXT.md` (Autenticación y sesión, Errores) y `docs/contrato/CLIENTE_FLUTTER.md`
(sección 2).

## Dependencias a agregar
- `package_info_plus` (versión de la app compilada).
- `url_launcher` (abrir `urlTienda`).

## Alcance

### 1. Dominio — `lib/features/auth/domain/`
- `AuthRepository`: `register(...)`, `login(email, password)`, `logout()`,
  `currentUser()`, `hasSession()`.
- `Session`/estado de autenticación: `unknown`, `unauthenticated`, `authenticated(user)`.
- `UserProfile` (rut, nombre, apellido, email, fechaRegistro).
- Validadores puros (con pruebas):
  - Contraseña: 8–64 caracteres, al menos una letra y un número, máximo 72 bytes UTF-8.
  - RUT: formato `^\d{7,8}-[\dkK]$` y dígito verificador (módulo 11). Normaliza entrada
    (quita puntos, mayúscula en K).
  - Email: formato básico.
  - Nombre y apellido: 2–50 caracteres.

### 2. Datos — `lib/features/auth/data/`
DTOs escritos a mano según `docs/contrato/openapi.json`:
- `POST /usuarios/register` con `{rut, nombre, apellido, email, contrasena}` → `200 {message}`.
  **No devuelve tokens.**
- `POST /usuarios/login` con `{email, contrasena}` → `{token, refreshToken, expiraEn}`;
  guardar ambos en `TokenStore`.
- `POST /auth/logout` con `{refreshToken}`: **siempre** borrar los tokens locales, aunque la
  llamada falle.
- `GET /usuarios/me` → perfil.
- Todas las llamadas por el cliente de `core/network`. Errores como `AppFailure`.

### 3. Versión mínima — `lib/features/app_version/`
- Al arrancar, **antes de cualquier login**:
  `GET /app/version?plataforma=ANDROID|IOS&version=MAJOR.MINOR.PATCH` (la versión sale de
  `package_info_plus`; la plataforma de `defaultTargetPlatform`).
- `actualizacionObligatoria=true`: pantalla bloqueante con `mensaje` y botón "Actualizar" que
  abre `urlTienda`. No se hacen más peticiones de casos de uso.
- `actualizacionSugerida=true`: aviso descartable no intrusivo y sigue la app.
- Ambos en `false`: no se muestra nada.
- Si la consulta falla por red o timeout: se degrada y se continúa (no bloquear).
- Guardar `versionTerminos`/`versionPrivacidad` en memoria para la tarea de legales (F2); aún
  no hay pantalla.

### 4. Presentación — `lib/features/auth/presentation/`
- **Arranque (splash):** consulta de versión → si hay tokens, `GET /usuarios/me` para validar y
  cargar el perfil (si responde `REFRESH_INVALIDO`, el interceptor ya limpió: ir al login);
  si no hay tokens, ir al login.
- **Login:** correo y contraseña. `CREDENCIALES_INVALIDAS` → "Correo o contraseña incorrectos".
  `INTENTOS_LOGIN_EXCEDIDOS` → "Demasiados intentos; espera unos minutos" con botón de
  reintento manual, sin reenvío automático. Mostrar indicador de carga y un texto si la
  respuesta tarda (el servidor puede estar despertando).
- **Registro:** RUT, nombre, apellido, correo, contraseña (con indicador de requisitos).
  `VALIDACION_FALLIDA` → mostrar `errores[]` junto a cada campo. `USUARIO_YA_REGISTRADO` →
  ofrecer ir al login. Éxito → ir al login con el correo precargado y un mensaje de cuenta
  creada (**un solo intento de login, hecho por la persona**).
- **Home (provisorio):** nombre del usuario y botón "Cerrar sesión". Se reemplaza en F3.
- **Router:** `go_router` con redirección según el estado de sesión, y suscripción al evento
  "sesión expirada" de `core/network` (lleva al login con un aviso).

### 5. Seguridad
- Ninguna contraseña ni token se imprime ni se guarda fuera de `flutter_secure_storage`
  (los tokens) o memoria (la contraseña, solo durante el envío).
- Campos de contraseña con ocultar/mostrar y sin autocompletado de sugerencias de texto.

## Pruebas
- Validadores (contraseña con tildes y 72 bytes, RUT válido/inválido/con K, email).
- Repositorio con adaptador falso: login guarda tokens; logout borra aunque falle; register no
  guarda tokens.
- Versión mínima: obligatoria, sugerida, al día, fallo de red.
- Widget tests: login con error genérico, login bloqueado (429), registro con errores por campo.
- Redirección del router: sin sesión → login; con sesión → home; evento `expired` → login.

## Fuera de alcance
Recuperar/cambiar contraseña, eliminar cuenta, legales, push, biometría, "recordarme".
(Van en F2 y posteriores.)

## Criterios de aceptación
- `flutter analyze` sin issues y `flutter test` en verde.
- Flujo manual descrito en el resumen: registro → login → cerrar y reabrir la app → sesión
  mantenida → cerrar sesión. Si no se pudo ejecutar en dispositivo, **decirlo explícitamente**.
- No existen `print`, ni logs de credenciales, ni `double` de dinero.

## Entrega
Commit local: `feat(auth): registro, login, sesión persistente y versión mínima`.
Resumen: archivos, dependencias, pruebas, lo que no se pudo verificar y TODOs abiertos.
