# SaveUp — App móvil (Flutter)

Aplicación móvil de **SaveUp** (finanzas personales) para iOS y Android. Consume
un backend RESTful ya existente, versionado en `/api/v1`.

Este repositorio contiene la app completa de SaveUp: autenticación y cuenta,
movimientos, deudas, presupuesto/regla 50/30/20, plan mensual, metas de ahorro y
exportación de reportes (CSV/PDF).

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
| Producción | `https://lite-backend-1wn9.onrender.com/api/v1` |

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

## Release

### Android

```sh
flutter build apk --release \
  --dart-define=API_BASE_URL=https://lite-backend-1wn9.onrender.com/api/v1

# Formato preferido para Play Store
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://lite-backend-1wn9.onrender.com/api/v1
```

El manifest principal declara `INTERNET` para que release tenga red (debug/profile
lo heredan de sus propios manifests). El label visible es **SaveUp**.

### Firma Android

`android/app/build.gradle.kts` lee `android/key.properties` (no commiteado). Si el
archivo no existe, la build release cae a la firma **debug** para no romper builds
locales: ese APK **no** se publica.

```
# android/key.properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=upload-keystore.jks
```

El keystore se guarda en `android/app/upload-keystore.jks` (ignorado por Git).
Crear uno nuevo:

```sh
keytool -genkeypair -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Verificar la firma:

```sh
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

### iOS

`CFBundleDisplayName` es **SaveUp**. La build de distribución se genera en macOS
con la cuenta de Apple Developer:

```sh
flutter build ipa --dart-define=API_BASE_URL=https://lite-backend-1wn9.onrender.com/api/v1
```

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
│   ├── design_system/   # tokens, tema y componentes Neo (átomos, moléculas, navegación)
│   ├── errors/          # tipos de error de la app
│   ├── money/           # dinero con Decimal, JSON y formato de entrada
│   ├── network/         # cliente HTTP / interceptores
│   └── time/            # fechas y zonas horarias
├── features/
│   ├── auth/            # {data, domain, presentation}
│   ├── movimientos/
│   ├── deudas/
│   ├── presupuesto/
│   ├── metas/
│   ├── reportes/
│   └── analitica/
└── main.dart
```

Organización *feature-first*: cada feature se divide en `data` (fuentes de
datos y DTOs), `domain` (entidades y casos de uso) y `presentation` (widgets y
estado).

## Documentación

- [`docs/CONTEXT.md`](docs/CONTEXT.md): contexto técnico y convenciones del
  proyecto. Léelo antes de implementar cualquier tarea.
- [`docs/Design_System/DESIGN_SYSTEM_PLAN.md`](docs/Design_System/DESIGN_SYSTEM_PLAN.md):
  contrato del design system Neo (tokens, componentes y patrones de UI).
- [`docs/tareas/README.md`](docs/tareas/README.md): formato de tareas y estado
  de las fases F0–F11.
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
