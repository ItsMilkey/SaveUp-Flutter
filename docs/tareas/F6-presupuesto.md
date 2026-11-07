# F6 — Presupuesto: regla, ejecución y límites

> **Avance Bloque 1 (2026-11-07): dominio, DTOs y repositorios.**
> Modelos con `Decimal` para porcentajes/límites/consumos: regla y sugerencia,
> ejecución global/historial/por categoría, límites y preferencias. DTOs a mano
> fieles al contrato (`porcentajeAhorro`, `limiteMensual`, `month/year`,
> `desde/hasta`, `DELETE` de preferencia) y repositorios Dio con query params
> exactos. Tests de contrato: 14 (URLs, cuerpos, query, parseo y `detail` de
> `400 DATOS_INVALIDOS`). Suite total 314 verdes, `flutter analyze` limpio.
>
> **Avance Bloque 2 (2026-11-07): configuración de la regla.**
> `ReglaPresupuestariaController` con autobalanceo exacto a 100.00 en `Decimal`
> (mueve uno y reparte el resto proporcionalmente; clamp 0–100; suma siempre
> exacta), carga tolerante a `404 NO_ENCONTRADO` (usa sugerencia/50-30-20),
> sugerencia opcional con `DATOS_INSUFICIENTES`, toggles `activo` y
> `automatizarAhorroEnMetas`, guardado y `detail` de `DATOS_INVALIDOS`.
> Pantalla `/presupuestos/configuracion` con sugerencia aplicable, tres sliders
> coordinados, suma visible y aviso de guardado; entrada desde el home.
> Tests: 7 del controlador y 3 de pantalla. Total 324 verdes.
>
> **Avance Bloque 3 (2026-11-07): ejecución, historial, límites y preferencias.**
> `EjecucionPresupuestoController` pide `month`/`year` del mes de negocio y
> arma el historial de 6 meses (`desde`/`hasta` en `yyyy-MM`), conserva la
> ejecución previa ante errores y separa la falla de historial de la global.
> Pantalla `/presupuestos/ejecucion` con navegación de mes, bloques
> necesidades/deseos/ahorro, ingresos y porcentajes, avance visual y
> último historial. `LimitesCategoriasController` carga catálogo + límites,
> edita el conjunto en memoria, valida `> 0`, hace el `PUT` completo e
> invalida la ejecución por categoría. `PreferenciasCategoriaController`
> cambia (`PUT`, solo NECESIDAD/DESEO) y quita (`DELETE`) la preferencia,
> restringido a categorías reclasificables. Pantalla
> `/presupuestos/categorias` con pestañas Límites (alta/edición/quitado,
> guardado completo y ejecución por categoría) y Tipos (chips + quitar).
> Accesos desde la AppBar de la configuración de la regla. Tras guardar la
> regla se invalidan ejecución global y por categoría.
> Tests: 4 de ejecución, 5 de límites, 5 de preferencias, 3 de pantalla de
> ejecución y 3 de pantalla de categorías. Total 344 verdes.
>
> **Verificación manual (emulador, backend real): PASÓ.** Regla 50/30/20
> guardada y visible como `Guía: 50 / 30 / 20` en el plan mensual. Ejecución
> de noviembre: ingresos `$1.000.000`, necesidades `$120.000` de `$500.000`
> (incluye Ocio reclasificado), deseos `$0` de `$300.000`, ahorro `$0` de
> `$200.000` e historial de 6 meses. Límites `$100.000` / `$60.000`; edición
> de Ocio a `$70.000` con aviso «Límites guardados.» y ejecución por categoría
> refrescada (`$40.000` / `$70.000`, BAJO). Quitar la preferencia devolvió Ocio
> a `DESEO`. Se detectó y corrigió un `409` del backend al reemplazar un
> conjunto de límites ya existente (faltaba flush entre el `DELETE` y los
> `INSERT`); ver el commit del backend y su test de regresión.

## Objetivo
Configurar la regla 50/30/20 (o personalizada) del usuario, seguir su ejecución mensual frente
al gasto real, definir límites por categoría y personalizar el tipo de una categoría
(`NECESIDAD`/`DESEO`). La regla alimenta la `guia` que ya muestra el plan mensual (F6a).

## Prerrequisito
F6a cerrada (commit `95b5340`).

## Lecturas previas
`docs/CONTEXT.md`, `docs/contrato/CLIENTE_FLUTTER.md` y `docs/contrato/openapi.json` (tag
"Presupuestos" y preferencias de categoría).

## Endpoints del contrato (corregidos contra `openapi.json`)

| Endpoint | Método | Entrada | Salida / errores |
|---|---|---|---|
| `/presupuestos/me` | GET | — | `ConfiguracionPresupuestoResponseDTO` (config actual) |
| `/presupuestos/me` | POST | `ConfiguracionPresupuestoRequestDTO` | `ConfiguracionPresupuestoResponseDTO`; `400 DATOS_INVALIDOS` |
| `/presupuestos/sugerencia-regla` | GET | — | `SugerenciaReglaResponseDTO` |
| `/presupuestos/ejecucion/me` | GET | `month` y `year` (**enteros**, opcionales) | `EjecucionPresupuestoDTO` |
| `/presupuestos/historial/me` | GET | `desde` y `hasta` (**obligatorios**, `yyyy-MM`) | `List<HistorialPresupuestoDTO>` |
| `/presupuestos/categorias/me` | GET | — | `List<PresupuestoCategoriaDTO>` |
| `/presupuestos/categorias/me` | PUT | `PresupuestoCategoriaRequestDTO` | `List<PresupuestoCategoriaDTO>`; `400 DATOS_INVALIDOS` |
| `/presupuestos/categorias/ejecucion/me` | GET | `month` y `year` (**enteros**, opcionales) | `List<EjecucionCategoriaDTO>` |
| `/categorias/preferencias` | GET | — | `List<PreferenciaCategoriaDTO>` |
| `/categorias/{id}/tipo-preferido` | PUT | `TipoPreferidoRequestDTO` | `PreferenciaCategoriaDTO`; `400`/`404` |
| `/categorias/{id}/tipo-preferido` | DELETE | — | **Limpia la preferencia** (204/200 según contrato de respuesta) |

### Correcciones respecto al borrador inicial
1. El tercer porcentaje es **`porcentajeAhorro`**, no "otros". La regla es
   **necesidades / deseos / ahorro** y suman 100.00.
2. El request admite además `activo` (default `true`),
   `automatizarAhorroEnMetas` (default `false`) y `asignaciones[]` (asignación del ahorro a
   metas: **F7**, fuera de F6). El response devuelve `id`, `usuarioRut`, porcentajes,
   `activo` y `automatizarAhorroEnMetas`.
3. **No existen** los códigos `SUMA_PORCENTAJES_INVALIDA` ni `LIMITE_INVALIDO`: los rechazos
   son `400 DATOS_INVALIDOS` con mensaje en `detail` (porcentajes faltantes/negativos/suma
   distinta de 100; límite ≤ 0 o categoría repetida). La app muestra el `detail`.
4. Ejecución e historial usan **`month`/`year` enteros** (no `mes=yyyy-MM`). El historial
   recibe **`desde` y `hasta` obligatorios** en `yyyy-MM`.
5. Los límites se llaman **`limiteMensual`** (no `limiteMonto`). El `PUT` **reemplaza el
   conjunto completo** con `{ "categorias": [{ "categoriaId", "limiteMensual" }] }`.
6. El tipo preferido **no acepta `null` en el body**: solo `NECESIDAD` o `DESEO`, y solo para
   categorías cuyo tipo por defecto sea NECESIDAD o DESEO. Para quitar la preferencia se usa
   **`DELETE /categorias/{id}/tipo-preferido`**.

## Reglas de dominio y UX
- **Porcentajes**: `Decimal` con escala 2, rango 0–100 y suma **exactamente 100.00**.
  Client-side se exige antes de enviar; el servidor vuelve a validar. Error genérico
  `DATOS_INVALIDOS` → mostrar `detail`.
- **Autobalanceo reactivo**: la pantalla mantiene tres controles. Al mover uno, los otros dos
  se recalculan proporcionalmente para conservar 100.00; si el usuario teclea un valor que
  deja la suma distinta, se bloquea el guardado y se informa cuánto falta/sobra.
- **Modelo financiero**: límites, presupuestos y consumos siempre `Decimal`; el `double` solo
  puede existir en la posición visual de un slider.
- **Sugerencia**: `sugerencia` es opcional. Si falta (`motivo = DATOS_INSUFICIENTES`, menos de
  2 meses válidos) se muestra `actual` y se explica que no hay sugerencia; nunca es un error.
- **Ejecución** (`EjecucionPresupuestoDTO`): bloques **necesidades, deseos y ahorro** con
  `presupuesto*`, `gasto*`/`ahorroRealizado`, `totalIngresos`, porcentajes configurados y
  `automatizarAhorroEnMetas`. No hay bloque "otros".
- **Límites por categoría**: `GET` devuelve los configurados (categoría + `limiteMensual`);
  `PUT` envía el conjunto completo (solo positivos, sin `categoriaId` repetido). Al guardar se
  refresca la ejecución por categoría.
- **Ejecución por categoría**: `limite`, `gastado`, `porcentajeUsado` y `estado`
  (`BAJO_EL_PLAN`/`CERCA_DEL_PLAN`/`SOBRE_EL_PLAN`) vienen del servidor; la app no recalcula.
- **Preferencias**: muestra `tipoPorDefecto`, `tipoPreferido?` y `tipoEfectivo`. Cambiar el
  tipo solo se ofrece si `tipoPorDefecto` es NECESIDAD o DESEO; "quitar preferencia" usa
  `DELETE`. Un `400`/`404` se muestra con `failureMessage`.
- **Reconciliación**: tras `POST /presupuestos/me`, reemplazar la config con la respuesta e
  **invalidar la ejecución** (global y por categoría). El plan mensual tomará la nueva `guia`
  en su próxima lectura.

## Estructura propuesta (`lib/features/presupuesto/`)
- `domain/`: `regla_presupuestaria.dart`, `ejecucion_presupuesto.dart`,
  `limite_categoria.dart`, `preferencia_categoria.dart`, `presupuesto_repository.dart`.
- `data/`: DTOs a mano por schema y `dio_presupuesto_repository.dart`.
- `presentation/controllers/`: regla (autobalanceo), ejecución/historial, límites y
  preferencias.
- `presentation/screens/`: `/presupuestos/configuracion`, `/presupuestos/ejecucion`,
  `/presupuestos/limites`.
- Rutas nuevas privadas y entrada desde el menú del home (junto a Deudas/Plan).

## Plan de ejecución (3 bloques)
1. **Datos y dominio**: DTOs del contrato, entidades `Decimal`, repositorio y tests con
   `FakeHttpAdapter` (URLs, cuerpos, parseo, `DATOS_INVALIDOS`).
2. **Configuración de la regla**: controlador con autobalanceo, pantalla con sugerencia y
   guardado (`POST`), activo/automatización; invalidación de ejecución. Tests unitarios del
   balanceo y widget.
3. **Ejecución, historial, límites y preferencias**: pantallas y controladores, reemplazo del
   conjunto de límites, tipos preferidos con `DELETE`, tests y verificación manual con
   `ana.demo1` (revivir Postgres/backend).

## Pruebas
- DTOs/repositorio: cuerpos exactos (incluido `{categorias: [...]}`), `month`/`year`,
  `desde`/`hasta`, parseo de ejecución/historial/preferencias y `DATOS_INVALIDOS`.
- Regla: autobalanceo a 100.00 sin perder escala, bloqueo de envío si no suma, sugerencia con
  y sin datos (`DATOS_INSUFICIENTES`), `POST` reemplaza e invalida ejecución.
- Límites: conjunto completo, rechazo de ≤ 0/repetidos, refresco de ejecución por categoría.
- Preferencias: cambiar y quitar (`DELETE`), restricción a NECESIDAD/DESEO y a categorías
  elegibles, 400/404 mostrados.
- Widget: sliders coordinados, sugerencia aplicada, paneles de ejecución e historial y límites.

## Fuera de alcance
Asignación del ahorro a metas (`asignaciones[]`, F7), ejecución automática real de abonos,
push/reportes y cualquier recálculo del plan mensual distinto de D6.

## Criterios de aceptación
- `flutter analyze` sin issues y `flutter test` en verde.
- Manual con `ana.demo1`: configurar una regla (y ver que `guia` aparece en el plan),
  revisar ejecución/historial, definir límites y cambiar/quitar un tipo preferido.
- Sin `print`, sin `double` para dinero, errores siempre por `codigo` y `detail`.

## Entrega
Commits sugeridos: `feat(presupuesto): regla y configuracion` y
`feat(presupuesto): ejecucion, historial, limites y preferencias`.
