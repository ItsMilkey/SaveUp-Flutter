# Contexto técnico — saveup_app

Documento de referencia para personas y agentes que trabajan en la app móvil de SaveUp
(Flutter, iOS y Android). Si algo no está aquí ni en el contrato del backend, no se asume:
se deja como `TODO` y se consulta.

> Este documento describe el estado objetivo. El avance real está en `docs/tareas/README.md`
> (casillas marcadas). Lo que aún no está implementado pertenece a la tarea pendiente
> correspondiente; no se reporta como discrepancia ni se adelanta.
## Fuente de verdad del backend

Copiar al repo (solo lectura, no editar a mano):

- `docs/contrato/openapi.json` — contrato de la API v1 (SaveUp Lite API 1.0.0).
- `docs/contrato/CLIENTE_FLUTTER.md` — guía de consumo escrita por el backend.

Si el backend cambia, se reemplazan esos dos archivos y se actualiza este documento.
Ante contradicción entre este documento y el contrato, manda el contrato.

## Arquitectura

- **Flutter** (iOS y Android) con Material 3.
- Organización **feature-first**: `lib/features/<feature>/{data,domain,presentation}`.
- Capas transversales en `lib/core/`:
  - `network/`: cliente HTTP (Dio), interceptores, almacenamiento de tokens.
  - `errors/`: fallas de la app y su mapeo desde `application/problem+json`.
  - `money/`: dinero con `Decimal` y su (de)serialización JSON.
  - `time/`: instantes UTC, fechas de calendario y zona de negocio.
- Arranque: `lib/main.dart` (`ProviderScope` + `MaterialApp.router`).
- Configuración: `lib/app/config.dart` (solo `--dart-define`, sin defaults).
- Navegación: `lib/app/router.dart` (`go_router`, con redirección según sesión).
- Tema: `lib/app/theme.dart` (Material 3 claro/oscuro con `ColorScheme.fromSeed`).

Regla de dependencias: `presentation` → `domain` ← `data`. `domain` no conoce Flutter ni
Dio. Nada de lógica de negocio en widgets. El backend es la única fuente de aritmética
financiera (saldos, intereses, cuotas, CAE): la app **muestra**, no recalcula.

## Convenciones

- Código y nombres de símbolos en **inglés**; documentación, textos de UI y commits en
  **español**.
- Archivos `snake_case.dart`; un widget público por archivo.
- Estado exclusivamente con **Riverpod**.
- Sin generadores de código (freezed, build_runner, openapi-generator) por ahora (ver D1).
- Sin `print`; errores propagados como `AppFailure`.
- `flutter analyze` sin issues y `flutter test` en verde antes de cerrar cualquier tarea.
- Los textos mostrables al usuario se deciden por `codigo` del error, nunca por `detail`.

## Entornos

| Entorno | `API_BASE_URL` |
|---|---|
| Android emulador | `http://10.0.2.2:8080/api/v1` |
| iOS simulador / local | `http://localhost:8080/api/v1` |
| Producción | `https://lite-backend-1wn9.onrender.com/api/v1` |

- `API_BASE_URL` es obligatoria (`AppConfig.ensureConfigured()` falla al arrancar si falta).
- HTTP sin TLS solo en debug (manifest debug de Android; `NSAllowsLocalNetworking` en iOS).
  Producción siempre HTTPS.
- Swagger UI y `/v3/api-docs` solo existen en dev: la app no los usa.
- Si el backend de producción está en un plan que se duerme por inactividad, la primera
  petición puede tardar decenas de segundos: los timeouts y la UI de carga deben tolerarlo
  (ver F0).
- TODO: staging y flavors (no se necesitan para el MVP).

## Autenticación y sesión

- Públicos: `POST /usuarios/register`, `POST /usuarios/login`, `POST /auth/refresh`,
  `POST /auth/logout`, `POST /auth/recuperar-contrasena`, `POST /auth/restablecer-contrasena`,
  `GET /app/version`. El resto exige `Authorization: Bearer <token>`.
- `login` y `refresh` devuelven `{ token, refreshToken, expiraEn }` (`expiraEn` es un instante UTC).
- **`register` NO inicia sesión**: responde `200 { message }`. Después hay que hacer login.
- Almacenamiento: `flutter_secure_storage` con las claves `saveup_jwt` y `saveup_refresh`.
  Nunca en `SharedPreferences`, logs ni código.
- Access token: 15 minutos. Refresh token: 90 días y **rotativo**: cada refresh entrega uno
  nuevo y revoca el anterior; reusar uno viejo se interpreta como robo y revoca la sesión.
- **Refresh en vuelo único (single-flight)**: si varias peticiones reciben `401 TOKEN_EXPIRADO`
  a la vez, solo una llama a `POST /auth/refresh`; las demás esperan ese resultado y reintentan
  con el token nuevo. Dos refresh simultáneos con el mismo token provocarían detección de
  reuso y cierre de sesión.
- `401 TOKEN_EXPIRADO` → refresh una sola vez y reintento una sola vez. Si el reintento vuelve
  a fallar, no hay más intentos.
- `401 REFRESH_INVALIDO` (o refresh que falla) → borrar ambos tokens y volver al login.
- Si el refresh falla por **red o timeout** (no es un 401), se conservan los tokens y se propaga
  `NetworkFailure`/`TimeoutFailure`: no se cierra la sesión por un problema de conectividad.
- No reintentar el login automáticamente con credenciales guardadas (no se guardan).
- Logout: `POST /auth/logout` con `{ refreshToken }`; se borran los tokens locales aunque la
  llamada falle. (Cuando exista push: antes, `DELETE /notificaciones/dispositivos`.)
- Login bloqueado: tras 5 fallos del par correo+IP → `429 INTENTOS_LOGIN_EXCEDIDOS` durante
  15 minutos, incluso con la contraseña correcta. Mensaje "Demasiados intentos; espera unos
  minutos" y reintento **manual**.
- Cambiar contraseña, restablecerla o eliminar la cuenta revoca todas las sesiones: la app
  borra tokens y pide login.
- Versión mínima: al arrancar, antes de cualquier login, `GET /app/version?plataforma=ANDROID|IOS&version=X.Y.Z`.
  Si falla por red, se degrada y se continúa (nunca bloquear por no poder consultar).

### Datos de usuario

- Registro: `rut` (`^\d{7,8}-[\dkK]$`, sin puntos, con guion), `nombre` y `apellido`
  (2–50), `email`, `contrasena`.
- **Política de contraseña** (registro, cambio y restablecimiento; el login NO la valida):
  8–64 caracteres, al menos una letra y un número, máximo 72 bytes en UTF-8 (tildes y 'ñ'
  pesan 2 bytes).

## Errores

Todo error llega como `application/problem+json`:
`{ type, title, status, detail, instance, codigo, errores?[{campo, mensaje}], idError? }`.

La app define `AppFailure` y mapea por `codigo`:

| `codigo` | HTTP | Comportamiento |
|---|---|---|
| `VALIDACION_FALLIDA` | 400 | Mostrar `errores[]` junto a cada campo. |
| `SOLICITUD_INVALIDA` | 400/405/415 | Error de integración: mensaje genérico, registrar. |
| `PARAMETRO_INVALIDO` | 400 | Parámetro/filtro mal enviado. |
| `DATOS_INVALIDOS` | 400 | Regla de negocio o monto inválido: mostrar `detail`. |
| `NO_AUTENTICADO` | 401 | Borrar tokens e ir al login. |
| `TOKEN_EXPIRADO` | 401 | Refresh único + reintento. |
| `REFRESH_INVALIDO` | 401 | Borrar tokens e ir al login. |
| `TOKEN_VERIFICACION_INVALIDO` | 400 | Token de restablecimiento inservible: pedir uno nuevo. |
| `CREDENCIALES_INVALIDAS` | 401 | "Correo o contraseña incorrectos" (genérico). |
| `INTENTOS_LOGIN_EXCEDIDOS` | 429 | Bloqueo de 15 min; reintento manual. |
| `PROHIBIDO` | 403 | Recurso de otro usuario: volver atrás. |
| `NO_ENCONTRADO` | 404 | Estado vacío o refrescar. |
| `CONFLICTO_REGLA_NEGOCIO` | 409 | Mostrar `detail`; no reintentar solo. |
| `USUARIO_YA_REGISTRADO` | 409 | Sugerir iniciar sesión o recuperar cuenta. |
| `DEUDA_SOBREPAGO` | 409 | Ajustar el monto del pago. |
| `ERROR_INTERNO` | 500 | Mensaje genérico + `idError` para soporte. |

Además: fallas locales (sin conexión, timeout, respuesta no parseable) tienen su propio tipo.
Un `codigo` desconocido cae en una falla genérica conservando status y `detail`.

## Dinero y porcentajes

- Los montos viajan como **número JSON con escala 2** (`12500.00`), no como string.
  Entrada: máximo 13 enteros + 2 decimales.
- En el dominio, el dinero es **siempre `Decimal`** (`package:decimal`). Prohibido `double`
  en dominio, estado y UI.
- El único lugar donde puede aparecer `num`/`double` es el borde de serialización
  (`lib/core/money/money_json.dart`): al leer, `Decimal.parse(n.toString())`; al enviar,
  validar escala ≤ 2 y magnitud < 10^13 y convertir. Ese archivo tiene pruebas de ida y vuelta.
- Los movimientos se envían con monto **positivo**: el signo lo impone el backend según el
  `tipoMovimiento`.
- Porcentajes y tasas llegan **en porcentaje** (`1.5` = 1,5 %). No dividir ni multiplicar por 100.
- Presentación en CLP sin decimales: `$1.234.567`. Es solo formato; el valor interno conserva
  sus decimales. TODO: confirmar con producto si se muestran centavos en algún caso.

## Fechas y zonas horarias

- **Instantes** (`fecha`, `fechaCreacion`, `fechaRegistro`, `expiraEn`): ISO-8601 UTC con `Z`.
  Se convierten a hora local solo para mostrar.
- **Fechas de calendario** (`fechaLimite`, `fechaPrimeraCuota`, filtros `desde`/`hasta`):
  `yyyy-MM-dd`. No son UTC ni llevan zona: nunca pasar por `DateTime` con zona.
- El **mes de negocio** (presupuesto, resúmenes) se calcula en **America/Santiago**, no en la
  zona del dispositivo. Se usa el paquete `timezone` (Chile cambia de horario).
- Filtros `desde`/`hasta` en movimientos son ISO inclusivos; 400 si `desde > hasta`.

## Paginación

`page` desde 0; `size` entre 1 y 100 (50 por defecto en movimientos, 20 en pagos).

## Endpoints disponibles (v1)

- **Usuarios/Auth:** register, login, auth/refresh, auth/logout, auth/recuperar-contrasena,
  auth/restablecer-contrasena, `GET/DELETE /usuarios/me`, `PUT /usuarios/me/contrasena`.
- **Versión:** `GET /app/version`.
- **Movimientos:** `POST /movimientos`, `GET /movimientos/me`, `GET /movimientos/paginados/me`
  (filtros: desde, hasta, tipoMovimiento, categoriaId, montoMin, montoMax, q),
  `PUT/DELETE /movimientos/{id}`. Tipos: `INGRESO_GENERAL`, `GASTO_GENERAL`, `PAGO_DEUDA`,
  `ABONO_META`, `RETIRO_META`. Solo ingresos y gastos generales se editan/eliminan desde acá.
- **Saldos:** `GET /saldos/me` (`/saldos` también existe).
- **Categorías:** `GET /categorias`.
- **Deudas:** `POST /deudas`, `GET /deudas/me`, `GET/PUT /deudas/{id}`, `POST /deudas/{id}/pagar`,
  `GET /deudas/{id}/pagos`, `GET /deudas/{id}/amortizacion`, `PATCH /deudas/{id}/cancelar`.
- **Simulador:** `POST /simulaciones/credito` (no persiste).
- **Presupuesto:** `GET/POST /presupuestos/me`, `GET/PUT /presupuestos/categorias/me`,
  `GET /presupuestos/{ejecucion,historial}/me`, `GET /presupuestos/categorias/ejecucion/me`.
- **Metas:** `POST /metas`, `GET /metas/me`, `PUT/DELETE /metas/{id}`, `POST /metas/{id}/{abonar,retirar}`.
- **Reportes:** `GET /reportes/movimientos/exportar` (bytes + `Content-Disposition`).
- **Push:** `GET/POST/DELETE /notificaciones/dispositivos`. (`/notificaciones/recordatorios/ejecutar`
  es del cron del backend: la app no lo usa.)

## Decisiones tomadas

- **D1 — Sin generador OpenAPI por ahora.** La guía del backend propone `dart-dio` +
  `build_runner`, pero los modelos generados tipan el dinero como `num`/`double` (choca con la
  regla de dinero) y no resuelven el refresh ni los errores. Se escriben DTOs a mano, pequeños
  y por feature. Se reevalúa cuando haya más de ~15 DTOs.
- **D2 — Dinero:** `Decimal` en dominio; `num` solo en el borde JSON (ver arriba).
- **D3 — Refresh single-flight** en el interceptor de autenticación.
- **D4 — `register` no inicia sesión:** al terminar el registro se lleva al login con el correo
  precargado (un solo intento de login, sin automatismos).
- **D5 — Zona de negocio** con el paquete `timezone`, inicializado al arrancar.

## Pendientes / fuera del alcance actual

- Push (FCM): requiere proyecto Firebase y, para iOS, cuenta de Apple Developer de pago (APNs).
  En producción el backend lo tiene desactivado; el registro de dispositivos sí funciona.
- Recuperación de contraseña por correo: en producción el envío está pendiente de activación
  en el backend. La UI debe decir que el envío aún no está disponible.
- Textos legales: el backend entrega `versionTerminos` y `versionPrivacidad`; la pantalla
  depende de la tarea T9.7 del backend (pendiente).
- Publicación en tiendas: fuera del MVP. Para iOS requerirá build en CI con el SDK vigente.
