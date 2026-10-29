# SaveUp — App móvil (Flutter)

Aplicación móvil de **SaveUp** (finanzas personales) para iOS y Android. Consume
un backend RESTful ya existente, versionado en `/api/v1`.

Este repositorio contiene **solo el proyecto base**: estructura, configuración,
tema, router y utilidades transversales. No hay funcionalidades de negocio
implementadas todavía.

## Requisitos

- Flutter 3.47 o superior (Dart 3.13 o superior).
- Xcode con un simulador iOS y/o Android Studio con un emulador Android.
- Backend de SaveUp corriendo con el prefijo `/api/v1`.

Verifica el entorno con:

```sh
flutter doctor
```

## Instalación

```sh
git clone <url-del-repo> saveup_app
cd saveup_app
flutter pub get
```

## Configuración: `API_BASE_URL`

La URL del backend **no** está hardcodeada ni tiene valor por defecto. Se inyecta
en tiempo de compilación con `--dart-define` y es obligatoria: si falta, la app
falla al arrancar con un mensaje explícito (`AppConfig.ensureConfigured()`).

| Entorno | Valor |
| --- | --- |
| Emulador Android | `http://10.0.2.2:8080/api/v1` |
| Simulador iOS | `http://localhost:8080/api/v1` |

Ejemplos:

```sh
# Android (el host de la máquina se ve como 10.0.2.2 desde el emulador)
flutter run -d <device-id> --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1

# iOS
flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

En VS Code están las configuraciones **Android emulador** e **iOS simulador** en
`.vscode/launch.json`, ya con el `--dart-define` correspondiente.

### HTTP en desarrollo

- Android: `android:usesCleartextTraffic="true"` solo en
  `android/app/src/debug/AndroidManifest.xml` (debug).
- iOS: `NSAllowsLocalNetworking = true` en `ios/Runner/Info.plist`.

Ninguno de los dos habilita tráfico inseguro en producción.

## Pruebas

```sh
flutter analyze   # análisis estático, debe salir sin issues
flutter test      # pruebas unitarias y de widgets
```

## Estructura

```
lib/
├── app/                 # configuración, tema, router, pantalla raíz
├── core/
│   ├── errors/          # tipos de error de la app (pendiente)
│   ├── money/           # manejo de dinero con Decimal
│   ├── network/         # cliente HTTP / interceptores (pendiente)
│   └── time/            # fechas y zonas horarias (pendiente)
├── features/
│   ├── auth/            # {data, domain, presentation}
│   ├── movimientos/
│   ├── deudas/
│   └── presupuesto/
└── main.dart
```

Organización *feature-first*: cada feature se divide en `data` (fuentes de
datos y DTOs), `domain` (entidades y casos de uso) y `presentation` (widgets y
estado).

## Documentación

- [`docs/CONTEXT.md`](docs/CONTEXT.md): contexto técnico y convenciones del
  proyecto. Léelo antes de implementar cualquier tarea.
- [`docs/tareas/README.md`](docs/tareas/README.md): formato de tareas y estado
  de los bloques F0/F1.
- [`.agents/rules/flutter-dart.md`](.agents/rules/flutter-dart.md): reglas
  siempre activas para agentes y personas.
- [`.agents/workflows/nueva-feature.md`](.agents/workflows/nueva-feature.md):
  flujo de trabajo para implementar una feature.

## Reglas clave

- Dinero siempre con `package:decimal`; **nunca** `double`.
- Riverpod es el único gestor de estado.
- Código y símbolos en inglés; documentación en español.
- Los contratos del backend (endpoints, campos, códigos de error) no se
  inventan: se documentan como `TODO` hasta confirmarlos contra
  `docs/CLIENTE_FLUTTER.md` del backend.
