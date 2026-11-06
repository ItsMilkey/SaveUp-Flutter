# F6a — Plan mensual: partidas, grupos, sliders con cálculo local y lote atómico

> **Avance Bloque 1 (2026-11-06): motor puro + vectores.**
> `CalculadoraPlanDart` en `lib/features/presupuesto/domain/services/` porta
> `CalculadoraPlan.java` con `Decimal` (HALF_UP) y `porcentajeUsado` truncado
> DOWN. El test `test/features/presupuesto/plan_vectores_test.dart` lee la
> copia de solo lectura `docs/contrato/plan-vectores.json` (v3) y valida
> **V01–V33 campo a campo**; añade inmutabilidad/idempotencia, plan 0, ingreso
> 0, el caso 250.001/250.000 y un truncado explícito. 40 tests del bloque en
> verde; suite total 270. Pendiente: Bloques 2 (controlador/sliders/lote) y
> 3 (pantalla, grupos, referencias y partidas vinculadas).
>
> **Avance Bloque 2 (2026-11-06): controlador, slider y lote atómico.**
> `PlanMensualController` (Notifier) con `PlanMensualState`: recálculo local en
> `moverPartida` (sin HTTP, vía `CalculadoraPlanDart.recalcularMontos`, que
> preserva `real` e imputación según D6), buffer de cambios por `partidaId`,
> `soltar()` que envía `PATCH /planes/{mes}/montos` en lotes de ≤100,
> reconciliación autoritativa con la respuesta y reaplicación visual de lo que
> quede sin confirmar; concurrencia sin bloquear sliders; reintento manual;
> partidas con `deudaId` ignoradas; tope `monto + max(remanente, 0)`.
> DTOs de lectura y de mutación + repositorio. Widget `PartidaMontoSlider`
> (drag local, PATCH solo al soltar; vinculadas sin slider con badge y aviso).
> Tests: 6 del controlador (local, lote único, concurrencia, vinculada, error +
> reintento, máximo 100) y 2 del slider. Total 278 en verde.
>
> **Avance Bloque 3 (2026-11-06): pantalla del plan, referencias, copia y grupos.**
> `/plan` con selector de mes (`BusinessMonth` de negocio, anterior/siguiente),
> resumen (planificado, remanente, margen, excede ingreso, reparto por tipo vs
> guía), secciones por grupo con subtotales y sliders, avisos de copia como
> información, referencias históricas (`incluirReferencias=true`, mes anterior
> y promedio 3M por categoría) y copia entre meses con selector de origen.
> CRUD básico de grupos en diálogo (crear/renombrar/eliminar, 409 mostrado).
> Tests de repositorio (referencias, copia, grupos, guía), controlador (copia
> ok/error, referencias) y pantalla (resumen/grupos/sliders, navegación de mes,
> referencias, avisos de copia, alta de grupo). 290 verdes.
>
> **Pendiente para cerrar F6a por completo:** formulario de alta/edición de
> partidas (con sugeridor de categorías) y edición del ingreso de referencia
> (`PUT /planes/{mes}/ingreso-referencia`), que la especificación incluye pero
> no estaban en el alcance de los tres bloques directivos.
>
> **Verificación manual (emulador, backend real): PASÓ.** Plan de noviembre
> sembrado vía API (2 grupos, Arriendo, Supermercado y una partida vinculada a
> una deuda demo con cuota): la pantalla muestra resumen ($660.000 → 34 % de
> margen), grupos con subtotales, sliders y la partida vinculada sin slider con
> badge de cuota. Arrastrar Arriendo a $520.636 actualizó el resumen
> ($780.636, 21,94 %) y persistió en BD (PATCH). Navegar a diciembre (vacío) y
> copiar desde noviembre dejó 3 partidas copiadas en BD; la partida vinculada
> aparece con estado de cuota `PENDIENTE`. Título del AppBar ajustado (selector
> de mes en barra inferior) tras detectar truncamiento. 290 tests verdes.

## Objetivo
Que la persona vea y edite el plan del mes (partidas por categoría con grupos, ingreso de
referencia, copia desde un mes anterior) y ajuste montos con **sliders** cuyo recálculo
ocurre **localmente durante el arrastre**, enviando el lote de cambios al backend solo al
soltar (`PATCH /planes/{mes}/montos`, atómico).

## Prerrequisito
F3 terminada (movimientos y categorías: el plan imputa gasto real). F6 puede ir antes o
después: la `guia` 50/30/20 del plan es informativa y nula si el usuario no configuró
presupuesto.

## Lecturas previas
`docs/contrato/PLAN_FORMULAS.md` (obligatoria) y `docs/contrato/plan-vectores.json`;
`docs/CONTEXT.md` (Dinero y porcentajes, Errores, D6 y decir cabal de "la app no recalcula"
con su excepción); `docs/contrato/openapi.json` tag "Planes".

## Alcance

### 1. Dominio — `lib/features/presupuesto/domain/` (o `lib/features/plan/`, decidir al abrir)
- Entidades espejo del contrato (a mano, sin generador): `PlanMensual` (mes `yyyy-MM`,
  `existe`, `ingresoReferencia`, resumen, partidas, `porCategoria`, `repartoPorTipo`, `guia`,
  grupos, `avisos`), `PartidaPlan`, `GrupoPlan`, `CategoriaPlan`, `RepartoTipo`, `Aviso`,
  `SinPlanificar`. Dinero y porcentajes como `Decimal`; `porcentajeUsado`/puntos como
  `Decimal` con el redondeo que impone la fórmula (nunca `double`).
- **`CalculadoraPlanDart`** (clase pura, sin Flutter ni Dio): espejo de la sección
  correspondiente de `PLAN_FORMULAS.md`. Solo recalcula lo que depende de montos
  planificados, sobre un `PlanMensual` entrante:
  - `diferencia = montoPlanificado − real` (§5).
  - `porcentajeUsado = real × 100 ÷ montoPlanificado` truncado DOWN a 2 decimales; nulo si
    plan = 0 (§1, §5).
  - `estado` por **multiplicación cruzada** con el umbral exacto: BAJO si
    `real×100 < 80×plan`; CERCA si `80×plan ≤ real×100 ≤ 100×plan`; SOBRE si
    `real×100 > 100×plan`; plan = 0 → SOBRE si `real > 0`, BAJO si `real = 0` (§5).
  - `planificadoTotal`, `remanenteLibre`, `margenSeguridadPct` (HALF_UP; nulo sin ingreso o
    si es 0) y `excedeIngreso` del resumen (§4).
  - Grupos afectados: `planificado` y `porcentajeDelPlanificado` (HALF_UP; la suma puede no
    dar 100,00 y no se fuerza) (§11).
  - `repartoPorTipo`: `planificado` y `porcentajeDelIngreso` por tipo (NECESIDAD, DESEO,
    OTROS); categorías tipo AHORRO no aparecen (§7).
  - **No** recalcula: `real`, la imputación, `estadoCuota`, referencias históricas,
    `gastoRealTotal`, `ahorroRegistrado`, `sinPlanificar`.
  - Tope del slider de una partida: `monto actual + max(remanenteLibre, 0)`, recalculado al
    mover **otras** partidas (§10). Teclear un monto mayor es válido con aviso informativo
    (`excedeIngreso`).
- Visibilidad de reglas de validación de partida para pre-validar en UI sin reintentos:
  nombre 1–80 tras `trim` (§8), monto ≥ 0 con escala 2 y < 10^13, categoría del catálogo
  distinta de `SUELDO`/`AHORRO`, máx 100 partidas por plan.

### 2. Datos — capa `data/`
DTOs a mano según `docs/contrato/openapi.json`, por el cliente de `core/network`, errores
como `AppFailure`:
- `GET /planes/{mes}` (`mes` es calendario de negocio `America/Santiago`, no zona del
  dispositivo). Opcional `?incluirReferencias=true` para la vista de referencias.
- `PATCH /planes/{mes}/montos` con `{cambios:[{partidaId, monto}]}`: 1 a 100, sin
  `partidaId` repetido. La respuesta tra el `PlanMensualResponseDTO` completo.
- `PUT/DELETE /planes/{mes}/partidas/{id}`, `POST /planes/{mes}/partidas`
  (`montoPlanificado` no se envía si la partida lleva `deudaId`: 400 si llega).
- `PUT /planes/{mes}/ingreso-referencia`.
- `POST /planes/{mes}/copiar-desde/{mesOrigen}`: exige destino sin partidas (409), origen
  con al menos una (404) y meses distintos (400).
- `GET/POST /planes/grupos`, `PUT/DELETE /planes/grupos/{id}` (máx 20; borrar grupo deja
  sus partidas sin grupo).

### 3. Presentación — slider y sincronización con el servidor
- **Selector de mes** de negocio reutilizando `core/time` (el paquete borne `timezone` ya
  inicializado al arrancar: el mes no se calcula con la zona del dispositivo).
- **Pantalla del plan:** resumen (planificadoTotal, remanenteLibre con % de margen, aviso si
  `excedeIngreso`), grupos con sus partidas (sección por grupo, "Sin grupo" al final),
  `sinPlanificar` si aplica y `avisos[]` informativos tras copiar.
- **Slider por partida** (`SliderPartida`):
  - `onChange`: actualiza el estado local vía `CalculadoraPlanDart`; ni una red.
  - `onChangeEnd`: agrega `{partidaId, monto}` al buffer de cambios pendientes y envía el
    `PATCH /planes/{mes}/montos` con todo lo acumulado.
  - Mientras un PATCH está en vuelo los sliders **no se bloquean**: los nuevos cambios se
    acumulan y se mandan en el siguiente lote (sin `partidaId` repetido dentro del lote).
  - Al responder el PATCH, el estado local se **reemplaza** por el plan del servidor (el
    recálculo local es vista provisional, no otra verdad).
- Partidas con `deudaId`: sin slider; el monto se muestra tal cual con la nota "el monto lo
  define la cuota" (PATCH sobre ellas → 409), badge `estadoCuota` (PENDIENTE/PARCIAL/PAGADA)
  y aviso si `vinculoDesactualizado=true`.
- Crear/editar partida: formulario con nombre, categoría (catálogo con sugerencia del
  endpoint `/categorias/sugerencia` con contexto, mismo patrón de F3: debounce 400 ms, eco
  de `texto`, confirmación si `ambigua`), monto por teclado numérico, grupo opcional.
  Cambiar categoría de una partida con movimientos → 409 se muestra tal cual.
- Grupos: lista, crear, renombrar (1–60), borrar (aviso de partidas sin grupo).
- Copiar mes: modal de origen, confirmación si el destino ya tiene partidas (409), muestra
  los `avisos` de partidas de deuda omitidas (`SIN_CUOTA_EN_EL_MES`).
- Estados de error por `codigo`: `VALIDACION_FALLIDA` → `errores[]` junto a cada campo;
  `CONFLICTO_REGLA_NEGOCIO`/`DATOS_INVALIDOS` → `detail`; sin conexión durante un PATCH →
  conservar el estado local y ofrecer reenvío manual (no se pierde el arrastre).

## Pruebas
- **Vector test (la garantía del drift 0):** `test/features/plan/plan_vectores_test.dart`
  Lee `docs/contrato/plan-vectores.json` (copia de solo lectura) y para cada caso V01–V33
  arma el plan de entrada (`ingresoReferencia`, partidas, movimientos) y compara
  **campo a campo** contra `esperado` (resumen, partidas, porCategoria, repartoPorTipo,
  grupos), convirtiendo los números JSON con `Decimal.parse(n.toString())` (regla de
  `money_json.dart`). Si la `version` del JSON es mayor que la esperada, el test debe
  fallar con mensaje que pida revisar `PLAN_FORMULAS.md`; añadir a mano los casos límite
  que el JSON no cubra (plan = 0 con real > 0; ingreso 0; margen nulo; grupos que
  suman 100,00 exacto; real 250.001/250.000 → SOBRE con porcentaje 100,00).
- Unit `CalculadoraPlanDart`: inmutabilidad (nunca muta el plan recibido), idempotencia.
- Unit del buffer de cambios en vuelo: acumulación, fusión por `partidaId`, tamaño ≤ 100,
  envío solo al soltar.
- Widget: drag del slider → el resumen y el estado del color cambian en el mismo frame;
  `onChangeEnd` dispara exactamente 1 PATCH con los cambios acumulados; la respuesta
  lenta no bloquea otro cambio y el resultado final coincide con el servidor.
- Widget: partida vinculada sin slider; copia con avisos; validaciones en el formulario
  (el nombre único normalizado se valida en el servidor, 409 mostrado).

## Fuera de alcance
Configuración 50/30/20, ejecución e historial de presupuesto, límites por categoría
(F6); CRUD de deudas y simulador (F4/F5); metas (F7); notificaciones (F9). La `guia` del
plan se muestra si viene, sin recalcularla.

## Criterios de aceptación
- `flutter analyze` sin issues y `flutter test` en verde, con el vector test incluido.
- Drag del slider: cero llamadas HTTP hasta `onChangeEnd`; un PATCH por lote; el estado
  final siempre es el del servidor.
- No existen `double` de dinero ni `print`; el `estado` usa la multiplicación cruzada (el
  vector V10 pasa).
- Cambios de la UI (colores de estado, colores de texto) solo por `estado` y campos del
  contrato; ninguna pantalla inventa textos por `detail` cuando hay `codigo`.

## Entrega
Commit local: `feat(plan): plan mensual con sliders, cálculo local validado por vectores
y lote atómico de montos`.
Resumen: archivos, pruebas (incluida la tabla de vectores corridos), decisiones nuevas
tomadas contra las fórmulas, y lo que quedó pendiente para F6/F7.
