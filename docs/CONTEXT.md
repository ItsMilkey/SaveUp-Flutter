# Contexto técnico — saveup_app

Documento de referencia para personas y agentes que trabajan en la app móvil de
SaveUp. Si algo no está aquí, no se asume: se deja como `TODO` y se consulta al
backend.

## Arquitectura

- **Flutter** (iOS y Android) con Material 3.
- Organización **feature-first** bajo `lib/features/<feature>/{data,domain,presentation}`.
- Capas transversales en `lib/core/`:
  - `network/`: cliente HTTP (Dio) e interceptores.
  - `errors/`: tipos de error de la app y su mapeo desde el backend.
  - `money/`: parseo y formateo de montos con `Decimal`.
  - `time/`: manejo de fechas, UTC y zona horaria de negocio.
- Arranque: `lib/main.dart` (`ProviderScope` + `MaterialApp.router`).
- Configuración: `lib/app/config.dart` (solo `--dart-define`, sin defaults).
- Navegación: `lib/app/router.dart` (`go_router`, rutas declarativas).
- Tema: `lib/app/theme.dart` (Material 3 claro/oscuro con `ColorScheme.fromSeed`).

Regla de dependencias: `presentation` puede depender de `domain`, nunca al revés;
`data` implementa contratos definidos en `domain`. Nada de lógica de negocio en
widgets.

## Convenciones

- Código y nombres de símbolos en **inglés**; documentación y mensajes de commit
  en **español**.
- Archivos en `snake_case.dart`; un widget público por archivo.
- Estado exclusivamente con **Riverpod** (`flutter_riverpod`).
- Sin generadores de código (freezed, build_runner) por ahora.
- Sin `print`; se usa logging estructurado o errores propagados.
- `flutter analyze` sin issues y `flutter test` en verde antes de cerrar
  cualquier tarea.

## Dinero

- Los montos viajan como **string decimal** desde el backend para no perder
  precisión.
- Se convierten con `Money.parse(...)` (`lib/core/money/money.dart`) a
  `Decimal` de `package:decimal`.
- **Prohibido `double`** para montos, en cualquier capa.
- Presentación en **CLP** con `Money.formatClp(...)`: sin decimales, símbolo
  delante y separador de miles (`$1.234.567`).
- TODO: confirmar con el backend el separador decimal del string y la regla de
  redondeo a peso (hoy: half-up de `decimal`).

## Fechas y zonas horarias

- Los instantes llegan del backend en **UTC**.
- El "mes" de negocio (cortes de presupuesto, resúmenes) se calcula en
  **America/Santiago**, no en la zona del dispositivo.
- TODO: definir utilidades concretas en `lib/core/time/` (parseo, conversión a
  zona de negocio, límites de mes) cuando se documente el formato exacto de
  fechas del backend (`docs/CLIENTE_FLUTTER.md`).

## Contrato de errores del backend

- TODO: completar con `docs/CLIENTE_FLUTTER.md` del backend.
- Pendiente: forma del envelope de error, códigos de error estables, mensajes
  mostrables al usuario y tratamiento de errores de validación por campo.
- No inventar códigos ni campos. Toda suposición debe quedar marcada como `TODO`.

## Autenticación

- TODO: completar con `docs/CLIENTE_FLUTTER.md` del backend.
- Pendiente: esquema de autenticación (tipo de token, expiración, refresh),
  endpoints de login/registro/refresh, y política ante `401`.
- Decidido en la app: los tokens se guardan con `flutter_secure_storage`
  (dependencia ya instalada, sin implementación todavía).

## Entornos

- `API_BASE_URL` se inyecta por `--dart-define` y es obligatoria
  (`AppConfig.ensureConfigured()` falla al arrancar si falta).
- Valores locales:
  - Android emulador: `http://10.0.2.2:8080/api/v1`
  - iOS simulador: `http://localhost:8080/api/v1`
- HTTP sin TLS permitido solo en debug (Android debug manifest e
  `NSAllowsLocalNetworking` en iOS).
- TODO: definir entornos staging/producción y si existirán flavors de Android e
  iOS.
