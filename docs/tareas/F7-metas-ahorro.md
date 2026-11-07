# F7 — Metas de ahorro: crear, abonar, retirar

> **Estado: redactada contra el contrato real (2026-11-07).** Se implementa en
> dos bloques: (1) dominio, DTOs y repositorio; (2) controladores, pantallas,
> rutas, tests y verificación manual.
>
> **Avance Bloque 1 (2026-11-07): dominio, DTOs y repositorio.**
> `MetaAhorro` con `montoActual`/`montoObjetivo` en `Decimal`, `fechaLimite` en
> `CalendarDate` y tolerancia a la meta legacy sin objetivo/fecha. `MetasRepository`
> con los seis endpoints; DTOs a mano (`montoObjetivo` y `fechaLimite` opcionales) y
> repositorio Dio. Tests de contrato: 6 (parseo con y sin objetivo, cuerpos exactos de
> alta/edición/abono/retiro, `DELETE 204` y `detail` del `409`). Total 350 verdes.
>
> **Avance Bloque 2 (2026-11-07): controladores, pantallas y verificación.**
> `MetasController` (lista) y `MetaAccionesController` (abonar/retirar/eliminar
> con refresco de la lista, del home y de la ejecución del presupuesto), más
> `MetaFormController` con errores por campo. Pantallas `/metas` (tarjetas con
> progreso, fecha, acciones y meta base protegida), alta/edición con selector de
> fecha futura y diálogo de abono/retiro (valida monto y tope local; muestra el
> `detail` del servidor). Rutas y entrada desde el home. Se corrigió el refresco
> del home: invalidar `movimientosProvider` lo dejaba en «Cargando movimientos…»
> porque solo se inicializa en `initState`; ahora se llama a `refrescar()`.
> Tests: 19 nuevos (controladores, formulario, lista y diálogos); total 369
> verdes y `flutter analyze` limpio.
>
> **Verificación manual (emulador, backend real): PASÓ.** Meta «Notebook» de
> `$800.000` con fecha futura; abono de `$100.000` → `$100.000/$800.000` (12,5 %)
> y saldo del home `$400.000` con movimiento `ABONO_META -$100.000`; retiro de
> `$20.000` con saldo `$420.000`; edición del objetivo a `$900.000`
> (`$80.000/$900.000`, 8,89 %); eliminación con confirmación → meta fuera, saldo
> `$500.000` y movimiento de devolución `+$80.000`; meta base «Ahorros» sin
> opción de eliminar. El retiro excesivo por API devuelve `409
> CONFLICTO_REGLA_NEGOCIO` con su `detail`.

## Objetivo
Que la persona cree metas de ahorro con objetivo y fecha, abone y retire dinero de ellas, las
edite y las elimine. Cada abono/retiro crea un movimiento real (`ABONO_META`/`RETIRO_META`) que
mueve el saldo del home; al eliminar una meta con ahorro, el backend devuelve el dinero al saldo.
La pantalla también sirve de base para la futura asignación automática del ahorro (ver "Fuera de
alcance").

## Prerrequisito
F6 cerrada (commits `e85848a` backend / `f9ef17c` frontend). No depende de F6a.

## Lecturas previas
`docs/CONTEXT.md`, `docs/contrato/CLIENTE_FLUTTER.md`, `docs/contrato/openapi.json` (tag
"Metas de ahorro") y `backend/docs/CONTEXT.md` (invariante de metas y `SignoMovimiento`).

## Endpoints del contrato (no inventar otros)

| Endpoint | Método | Entrada | Salida / errores |
|---|---|---|---|
| `/metas` | POST | `MetaAhorroCreacionDTO` | `201 MetaAhorroResponseDTO`; `400`/`409` |
| `/metas/me` | GET | — | `200 [MetaAhorroResponseDTO]` |
| `/metas/{metaId}` | PUT | `MetaAhorroCreacionDTO` | `200 MetaAhorroResponseDTO`; `400`/`404`/`409` |
| `/metas/{metaId}` | DELETE | — | `204`; `404`/`409` (meta protegida) |
| `/metas/{metaId}/abonar` | POST | `AbonoRetiroDTO` | `200 MetaAhorroResponseDTO`; `400`/`404` |
| `/metas/{metaId}/retirar` | POST | `AbonoRetiroDTO` | `200 MetaAhorroResponseDTO`; `400`/`404`/`409` |

### Campos
- `MetaAhorroCreacionDTO`: `nombre` (obligatorio, no vacío), `montoObjetivo` (positivo, escala 2),
  `fechaLimite` (`yyyy-MM-dd`, **futuro**; opcional).
- `MetaAhorroResponseDTO`: `id`, `nombre`, `montoObjetivo?`, `fechaLimite?`, `montoActual`.
- `AbonoRetiroDTO`: `monto` (positivo, escala 2) y `descripcion` (obligatoria, no vacía).

## Reglas de contrato y dominio que la app debe respetar
- **Dinero** siempre `Decimal` (borde JSON con `moneyFromJson`/`moneyToJson`); fechas de
  calendario con `CalendarDate` (`yyyy-MM-dd`, nunca `DateTime` con zona).
- **Meta por defecto legacy "Ahorros"**: puede venir con `montoObjetivo` y `fechaLimite` nulos.
  La app debe tolerarlo: la trata como meta sin objetivo (sin barra de progreso ni fecha), permite
  editar solo el nombre, y **no ofrece eliminar** (el backend igual responde `409` con `detail`).
- **Crear** no mueve el saldo. **Abonar** crea `ABONO_META` negativo (sale del saldo) y sube
  `montoActual`. **Retirar** crea `RETIRO_META` positivo (vuelve al saldo) y baja `montoActual`.
- **Retirar más de lo ahorrado** → `409 CONFLICTO_REGLA_NEGOCIO` con `detail` («El monto a retirar
  no puede ser mayor al total ahorrado.»). La UI lo valida también localmente contra
  `montoActual`, pero muestra el `detail` si el servidor rechaza.
- **Eliminar** una meta con ahorro crea un `RETIRO_META` por el total y devuelve el dinero al
  saldo; la confirmación debe explicarlo. Las metas protegidas responden `409` con `detail`.
- Tras abonar/retirar/eliminar se invalida `movimientosProvider` (saldo y lista del home) y
  `ejecucionPresupuestoProvider` (el abono/retiro afecta `ahorroRealizado`). Tras crear/editar/
  eliminar se refresca la lista de metas.
- Errores por `codigo` con `failureMessage`; `400 DATOS_INVALIDOS`/`VALIDACION_FALLIDA` muestran
  `detail` o los errores por campo; `409` muestra el `detail`.

## UX propuesta
- Entrada desde el home: icono `savings_outlined` con tooltip «Metas de ahorro» → `/metas`.
- **Lista** `/metas`: tarjetas con nombre, progreso (`montoActual / montoObjetivo` cuando hay
  objetivo, con porcentaje y barra; `montoActual` solo cuando no lo hay), fecha límite, acciones
  «Abonar» y «Retirar», y menú «Editar»/«Eliminar». Estado vacío con botón para crear la primera.
  FAB «Nueva meta».
- **Alta/edición** `/metas/nueva` y `/metas/{id}/editar` (recibe la `MetaAhorro` por `extra`):
  nombre, monto objetivo (`Money.parseUserInput`, > 0), fecha límite opcional con selector que
  solo admite fechas futuras. En la meta por defecto se bloquean objetivo/fecha y se explica por
  qué. Guardado con errores por campo (`VALIDACION_FALLIDA`) y `detail` para el resto.
- **Abono/retiro**: diálogo con monto y descripción (prefijada «Abono a …» / «Retiro de …»,
  editable). Valida monto > 0 y, en retiro, ≤ `montoActual`; el 409 del servidor se muestra con su
  `detail`. Al terminar, SnackBar y lista/saldo refrescados.
- **Eliminar**: confirmación que advierte que el ahorro vuelve al saldo.

## Estructura
`lib/features/metas/`
- `domain/`: `meta_ahorro.dart` (`MetaAhorro`, `MetaAhorroDatos`), `metas_repository.dart`.
- `data/`: `meta_dtos.dart` (a mano, `Decimal`/`CalendarDate`, tolerante a `montoObjetivo` nulo) y
  `dio_metas_repository.dart`.
- `presentation/controllers/`: `metas_controller.dart` (lista + acciones abonar/retirar/eliminar)
  y `meta_form_controller.dart` (alta/edición con errores por campo).
- `presentation/screens/`: `metas_screen.dart`, `meta_form_screen.dart`.
- `presentation/widgets/`: `movimiento_meta_dialog.dart`.
- Rutas privadas en `app/routes.dart` y `app/router.dart`; icono en el AppBar del home.

## Plan de ejecución (2 bloques)
1. **Datos y dominio**: modelos `Decimal`/`CalendarDate`, DTOs, repositorio Dio y tests de
   contrato (URLs, cuerpos exactos, parseo con y sin objetivo/fecha, `detail` de 409).
2. **Controladores y UI**: lista, alta/edición, abono/retiro, eliminación, invalidaciones, rutas y
   entrada del home; tests de controlador y widget; verificación manual con un usuario demo.

## Pruebas
- Repositorio: `POST /metas`, `GET /metas/me`, `PUT/DELETE /metas/{id}`, `POST .../abonar` y
  `.../retirar` con `{monto, descripcion}`; parseo de `montoObjetivo`/`fechaLimite` nulos;
  `409` con `detail`.
- Controlador: carga de lista, alta/edición/eliminación, abono y retiro con refresco de la lista;
  retiro inválido muestra el `detail`; errores de validación por campo.
- Widget: lista con/sin metas, progreso y meta por defecto; formulario (objetivo requerido,
  fecha futura, campos bloqueados en la meta por defecto); diálogos de abono/retiro y ejecto del
  409; eliminar con confirmación.
- `flutter analyze` sin issues y `flutter test` en verde.

## Fuera de alcance
- `asignaciones[]` del `POST /presupuestos/me` (asignación automática del ahorro a metas). **No se
  implementa en F7**: ya existe la lectura (`GET /presupuestos/asignaciones/me`) y la validación de
  suma 100 en el backend, pero sus DTOs, controlador y UI son la tarea aparte **F11**
  (`F11-asignaciones-presupuesto.md`).
- Smart-Split/automatización de abonos y reportes.

## Criterios de aceptación
- Crear una meta con objetivo y fecha futura, verla en la lista con progreso.
- Abonar: movimiento `ABONO_META` visible en el home y saldo reducido; `montoActual` sube.
- Retirar: movimiento `RETIRO_META` y saldo recuperado; retirar de más devuelve `409` con `detail`.
- Editar nombre/objetivo/fecha; eliminar con confirmación y reintegro del ahorro.
- Verificación manual en emulador con backend real y sin `print` ni `double` para dinero.
