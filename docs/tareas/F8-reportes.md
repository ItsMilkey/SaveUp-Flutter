# F8 — Exportación de movimientos (CSV/PDF)

> **Estado (2026-11-07): redactada contra el contrato real.** Se implementa en
> dos bloques: (1) descarga binaria, dominio/repositorio y sharer; (2) pantalla,
> ruta/entrada, tests y verificación manual.
>
> **Avance Bloque 1 (2026-11-07): descarga binaria y datos.**
> `ApiClient.getBytes` (`ResponseType.bytes`), `problem_details` decodifica un
> `problem+json` recibido como bytes, dominio `ReporteAlcance`/`ReporteFormato`/
> `ReporteSolicitud`/`ReporteArchivo`, repositorio Dio con query exacta, nombre
> desde `Content-Disposition` (con fallback) y content type limpio, y sharer con
> `share_plus` (`XFile.fromData` + `fileNameOverrides`). Tests: 5 de repositorio
> y 1 del mapeo en bytes. Total 375 verdes.

## Objetivo
Que la persona exporte sus movimientos a **CSV** o **PDF**, de todo el historial o de un mes
concreto, y comparta/guarde el archivo desde el móvil. No se persiste nada en el servidor: el
backend genera el archivo y la app lo descarga.

## Prerrequisito
F7 cerrada (`ee3f424`) e i18n cerrada (`58eb43f`).

## Lecturas previas
`docs/CONTEXT.md`, `docs/contrato/CLIENTE_FLUTTER.md` y `docs/contrato/openapi.json` (tag
"Reportes"). Backend: `ReporteController` y `ReporteService`.

## Endpoint del contrato (no inventar otros)

| Endpoint | Método | Entrada | Salida / errores |
|---|---|---|---|
| `/reportes/movimientos/exportar` | GET | `alcance` (`COMPLETO`/`MENSUAL`, default `COMPLETO`), `formato` (`CSV`/`PDF`, default `CSV`), `mes` (1–12), `anio` (2000–2100) | `200` binario (`text/csv` o `application/pdf`) con `Content-Disposition: attachment; filename="..."`; `400` `problem+json` |

### Reglas del contrato
- `mensual` **requiere** `mes` y `anio`; `completo` los omite. El backend valida rangos y responde
  `400 DATOS_INVALIDOS` con `detail` si se salen.
- Un `formato` desconocido cae a CSV en el backend; la app solo ofrece `CSV` y `PDF`.
- El nombre del archivo viene en `Content-Disposition` (`reporte_saveup_completo.csv`,
  `reporte_saveup_11-2026.pdf`, etc.); si falta, se usa un fallback local.
- Los errores del endpoint pueden llegar como **bytes JSON** (`application/problem+json`) porque
  la petición pide `ResponseType.bytes`; el mapeo global debe decodificar bytes a JSON antes de
  elegir el `codigo`.
- **No hay endpoints de analítica global ni dashboards**: el alcance de F8 es solo exportación.

## UX
- Entrada desde el home con un icono de descarga (`file_download_outlined`) → `/reportes`.
  Para no saturar la barra (ya tiene deudas, plan, presupuesto y metas), «Cerrar sesión» se mueve
  al menú de cuenta.
- Pantalla `/reportes`:
  - Alcance: `Completo` / `Mensual`.
  - Si es mensual: selector de mes/año (BusinessMonth con chevrons, por defecto el mes actual).
  - Formato: `CSV` / `PDF`.
  - Botón «Exportar». Al terminar, se abre la hoja de compartir y se muestra un SnackBar con el
    nombre del archivo. Mientras descarga: progreso y botón bloqueado.
  - Error inline con `failureMessage` (incluye el `detail` de `DATOS_INVALIDOS`).
  - Texto breve: CSV para planillas; PDF para compartir o imprimir.
- El archivo se escribe en el directorio temporal y se comparte con `share_plus`; iOS/Android
  ofrecen «Guardar en Archivos»/«Guardar en Drive» dentro de la hoja.

## Estructura
- `core/network/api_client.dart`: nuevo `getBytes` (`ResponseType.bytes`, `Accept` binario).
- `core/errors/problem_details.dart`: tolerar `List<int>` (bytes) en el cuerpo de error.
- `features/reportes/domain/`: `reporte_movimientos.dart` (`ReporteAlcance`, `ReporteFormato`,
  `ReporteSolicitud` con `BusinessMonth?`, `ReporteArchivo` con `Uint8List`), y
  `reportes_repository.dart`.
- `features/reportes/data/`: `dio_reportes_repository.dart`,
  `reporte_sharer.dart` (interfaz + implementación con `share_plus` y `XFile.fromData`).
- `features/reportes/presentation/`: `reporte_export_controller.dart`, `reportes_screen.dart`.
- Dependencia nueva: `share_plus`.

## Plan de ejecución (2 bloques)
1. **Datos**: `getBytes`, bytes en `problem_details`, dominio, repositorio y sharer; tests con
   `FakeHttpAdapter` (query exacta, binario, `Content-Disposition`, error 400 en bytes).
2. **UI**: controlador, pantalla, ruta y entrada del home; tests de controlador y widget;
   verificación manual con CSV y PDF, alcance completo y mensual.

## Pruebas
- `ApiClient.getBytes`: query y `responseType` bytes.
- Repositorio: URL, parámetros, contenido binario, nombre desde `Content-Disposition` y fallback;
  `400 DATOS_INVALIDOS` en bytes se traduce a `BadRequestFailure` con `detail`.
- Controlador: éxito (descarga + sharer), error de red, sharer con el archivo correcto.
- Widget: alternar alcance/formato, selector mensual, botón bloqueado mientras exporta y error.
- `flutter analyze` sin issues y `flutter test` en verde.

## Fuera de alcance
- Dashboards/analítica global (no existen en el contrato).
- Exportar deudas, presupuesto o metas.
- Programar reportes o enviarlos por correo.
- Persistir el archivo en el servidor.

## Criterios de aceptación
- Exportar CSV completo y PDF mensual y verificar el archivo descargado (nombre, tipo y contenido).
- La hoja de compartir se abre con el archivo correcto y el SnackBar muestra su nombre.
- Un error de red/validación se muestra con `failureMessage` sin bloquear la app.
- Verificación manual en emulador con backend real.
