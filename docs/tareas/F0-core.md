# F0 — Núcleo transversal (`lib/core/`)

## Objetivo
Dejar listas las piezas compartidas que usarán todas las features: dinero, tiempo, errores
y cliente HTTP con sesión. Sin pantallas nuevas.

## Lecturas previas
`docs/CONTEXT.md` (secciones Autenticación, Errores, Dinero, Fechas) y
`docs/contrato/CLIENTE_FLUTTER.md`.

## Dependencias a agregar
- `timezone`.
- Nada más. Para las pruebas de red, usa un `HttpClientAdapter` falso escrito a mano
  (no agregar paquetes de mocking).

## Alcance

### 1. Dinero — `lib/core/money/`
- `money_json.dart`:
  - `Decimal moneyFromJson(Object? value)`: acepta `int` y `double` (JSON numérico) y
    produce `Decimal` con `Decimal.parse(value.toString())`. Rechaza `null`, `String`, `NaN`,
    infinitos y notación exponencial inesperada con `FormatException`.
  - `num moneyToJson(Decimal value)`: valida escala ≤ 2 y magnitud < 10^13 (lanza
    `ArgumentError` si no) y convierte para enviar.
- `money.dart` (ya existe): separar claramente
  - `Money.parseUserInput(String)`: tolerante (acepta `.` y `,`, y miles) — solo para texto
    que escribe la persona.
  - Eliminar de la API pública cualquier uso de `Money.parse` sobre datos del backend.
- Mantener `Money.formatClp` (sin decimales, `$1.234.567`).
- Pruebas: ida y vuelta para 0.00, 0.01, 0.10, 1234.56, 12500.00, 9999999999999.99,
  negativos; rechazos; muchos valores aleatorios de escala 2 (ida y vuelta exacta).

### 2. Tiempo — `lib/core/time/`
- `time_zones.dart`: inicializar la base de zonas (`timezone`) y exponer la ubicación
  `America/Santiago`. Se inicializa en `main()` antes de `runApp`.
- `instants.dart`: `DateTime parseInstant(String)` (ISO-8601 UTC con `Z`; lanza si no tiene
  zona) y `String formatInstant(DateTime)` para enviar.
- `calendar_date.dart`: tipo `CalendarDate(year, month, day)` inmutable, `parse('yyyy-MM-dd')`,
  `toJson()`, comparación y `toString`. No usa zonas horarias.
- `business_month.dart`: dado un instante, devolver el mes de negocio (año, mes) en
  America/Santiago, y los límites `[inicio, fin)` del mes como instantes UTC.
- Pruebas: un instante cerca de medianoche UTC que cae en meses distintos en Santiago y en
  UTC; el cambio de horario de Chile (verano/invierno); `CalendarDate` con años bisiestos;
  rechazo de formatos inválidos.

### 3. Errores — `lib/core/errors/`
- `app_failure.dart`: jerarquía sellada (`sealed class AppFailure`) con, al menos:
  `ValidationFailure(errors)`, `AuthFailure` (con subtipos para token expirado, refresh
  inválido, no autenticado, credenciales inválidas), `LoginBlockedFailure`,
  `ForbiddenFailure`, `NotFoundFailure`, `ConflictFailure(codigo, detail)` (cubre
  `CONFLICTO_REGLA_NEGOCIO`, `USUARIO_YA_REGISTRADO`, `DEUDA_SOBREPAGO`),
  `BadRequestFailure(codigo, detail)`, `ServerFailure(idError)`, `NetworkFailure`,
  `TimeoutFailure`, `UnknownFailure(status, codigo, detail)`.
- `problem_details.dart`: parseo de `application/problem+json` con `codigo`, `errores[]`,
  `idError`. Si el cuerpo no es parseable, `UnknownFailure` conservando el status.
- `failure_messages.dart`: mensajes en español para cada falla (según `codigo`). Para 500,
  incluir el `idError` para soporte. `CREDENCIALES_INVALIDAS` siempre usa el texto genérico
  "Correo o contraseña incorrectos".
- Pruebas: una por cada `codigo` de la tabla de `CONTEXT.md`, más `codigo` desconocido,
  cuerpo vacío y cuerpo no JSON.

### 4. Red y sesión — `lib/core/network/`
- `token_store.dart`: interfaz `TokenStore` (`read`, `save(token, refresh)`, `clear`) con
  implementación sobre `flutter_secure_storage` (claves `saveup_jwt`, `saveup_refresh`) y una
  implementación en memoria para pruebas.
- `api_client.dart`: provider de `Dio` con `baseUrl` de `AppConfig`, `connectTimeout` 30 s,
  `receiveTimeout` 60 s (tolera el arranque en frío del servidor), cabecera
  `Accept: application/json`. Los `DioException` se convierten a `AppFailure` en un solo lugar.
- `auth_interceptor.dart`:
  - Adjunta `Authorization: Bearer` salvo en las rutas públicas listadas en `CONTEXT.md`.
  - Ante `401 TOKEN_EXPIRADO`: refresh **single-flight** (un `Future` compartido; las demás
    peticiones esperan), con un cliente Dio aparte sin este interceptor para evitar recursión.
    Guarda el par nuevo y reintenta **una sola vez** la petición original.
  - Si el refresh falla con `REFRESH_INVALIDO` (o el reintento vuelve a dar 401): borra los
    tokens y emite un evento "sesión expirada" (un `Stream`/notifier que consumirá el router).
  - Nunca refresca ante 401 de `login`, `register` ni `refresh`.
- `session_events.dart`: el stream de eventos de sesión (`expired`).
- Logging: un interceptor opcional solo en debug que **no** imprime `Authorization` ni cuerpos
  de rutas de auth.
- Pruebas (con adaptador falso):
  1. Token válido: se adjunta el header.
  2. `TOKEN_EXPIRADO` → un refresh → reintento exitoso → par nuevo guardado.
  3. **Tres peticiones simultáneas** con `TOKEN_EXPIRADO` → exactamente **una** llamada a
     `/auth/refresh`; las tres terminan bien.
  4. `REFRESH_INVALIDO` → tokens borrados y evento `expired`.
  5. El reintento también da 401 → sin tercer intento, tokens borrados.
  6. 401 de `login` no dispara refresh.
  7. Rutas públicas no llevan `Authorization`.
  8. Timeout y falta de red → `TimeoutFailure` / `NetworkFailure`.

## Fuera de alcance
Pantallas, repositorios de features, push, generación de cliente OpenAPI, persistencia local
de datos de negocio.

## Criterios de aceptación
- `flutter analyze` sin issues y `flutter test` en verde.
- Ninguna `double` de dinero fuera de `money_json.dart` (búsqueda en el resumen final).
- Las 8 pruebas de red existen y pasan; en especial la de concurrencia (3).
- `docs/CONTEXT.md` actualizado si alguna decisión cambió (anotarlo en el resumen).

## Entrega
Commit local: `feat(core): dinero, tiempo, errores y cliente HTTP con sesión`.
Resumen: archivos creados, dependencias agregadas, pruebas y pendientes.
