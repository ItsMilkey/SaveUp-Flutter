# F3 — Movimientos, saldo y categorías (primer corte vertical)

> **Avance (2026-11-06):** código del primer corte completo.
> - Slice 1 (`8c53403`): home real con saldo (`GET /saldos/me`), listado
>   paginado (`size=50`, scroll infinito, dedupe por `id`), filtros de fechas y
>   tipo con reinicio a `page=0`, pull-to-refresh y estados vacío/error.
> - Slice 2: alta mínima (`POST /movimientos`) con `SugerenciaCategoriaController`
>   (`AsyncNotifier`, debounce 400 ms, descarte por eco de `texto`, `ambigua`
>   con elección explícita) y selector de categoría desde `GET /categorias`.
>   207 tests en verde y `flutter analyze` limpio.
>
> **Verificación manual en emulador (contra backend real, `ana.demo1`): PASÓ.**
> - Home con saldo real (`$0` inicial, luego `-$14.500` en rojo) y lista vacía.
> - Alta "comida": el backend devolvió **ambigua** con dos categorías; la UI no
>   preseleccionó, exigió elegir chip (Restaurantes y Salidas) y guardó
>   `monto=-4500.00, tipo=GASTO_GENERAL, categoria_id=17` (verificado en BD);
>   saldo y lista se refrescaron.
> - Alta "supermercado" (no ambigua): preseleccionó Alimentación Base y guardó
>   (`categoria_id` correcta), saldo `-$14.500`, 2 movimientos.
> - Filtro por tipo "Ingreso": 0 movimientos + estado vacío con "Quitar
>   filtros"; filtro por fecha `Desde 2026-11-07`: lista vacía; al limpiar,
>   vuelven los 2 movimientos.
>
> **F3b (edición/eliminación):** `PUT /movimientos/{id}` parcial (el contrato
> **no** permite cambiar `tipo`) con formulario compartido y reconciliación
> del ítem + saldo; `DELETE /movimientos/{id}` con swipe + confirmación,
> quitando el ítem y refrescando el saldo. Solo se ofrece para
> `INGRESO_GENERAL`/`GASTO_GENERAL` (el backend responde 409 en los demás).
> 212 tests en verde.
>
> **Verificación manual F3b (emulador, backend real): PASÓ.** Editar "comida"
> (4500→5000) desde el ítem: tipo fijo, monto absoluto y categoría
> precargados; al guardar, `monto=-5000.00` en BD, lista y saldo reconciliados
> (`-$15.000`). Swipe + diálogo en "supermercado": `Eliminar` borró la fila en
> BD, saldo `-$5.000`; repetido con "comida": cuenta limpia ($0, 0
> movimientos, tabla vacía).
>
> **Avance posterior (2026-11-11): pulido de UI.** Encabezado de marca centrado
> (`NeoSliverAppBar`) y saludo con el nombre en Inicio; selector de categoría con
> recientes/frecuentes, iconos y agrupación por tipo (respeta el contexto
> GASTO/INGRESO del contrato); montos con separador de miles mientras se
> escriben. Todo en `presentation`.

## Objetivo
Que una persona autenticada vea su **saldo actual** y sus **movimientos paginados** con
filtros por fechas y tipo, y pueda **registrar un movimiento** con categoría asistida por el
sugeridor del backend (preselección con confirmación cuando es ambigua).

## Prerrequisito
F2 cerrada (commits `10cadae` … `3c152ad`).

## Lecturas previas
`docs/CONTEXT.md` (Dinero, Fechas, Errores, Autenticación), `docs/contrato/CLIENTE_FLUTTER.md`
(paginación y sugeridor de categoría) y `docs/contrato/openapi.json`. Referencia de diseño del
sugeridor: `docs/contrato/CLIENTE_FLUTTER.md` (T10b: debounce 400 ms, eco de `texto`,
`ambigua`).

## Endpoints del contrato (no inventar otros)
- `GET /saldos/me` → `200 { saldo }` (número con escala 2; **puede ser negativo**).
- `GET /movimientos/paginados/me` con query: `desde`, `hasta` (`yyyy-MM-dd`, inclusivos),
  `tipoMovimiento` (`INGRESO_GENERAL|GASTO_GENERAL|PAGO_DEUDA|ABONO_META|RETIRO_META`),
  `categoriaId`, `partidaId`, `montoMin`, `montoMax`, `q`, `page` (base 0, por defecto 0) y
  `size` (por defecto 50). Responde `{ content[], currentPage, totalItems, totalPages }`;
  cada movimiento trae `id, monto (con signo), descripcion, fecha (ISO-8601 UTC),
  tipoMovimiento, categoria?, partidaId?`.
- `GET /categorias` → `200 [CategoriaDTO]` (`id, codigo, nombre, iconId?, colorHex?,
  tipoPresupuesto?`).
- `GET /categorias/sugerencia?texto&contexto=GASTO|INGRESO` (protegido) → `200 { texto,
  sugerencias[0..3], ambigua }`; `texto` es el original exacto (eco), máximo 80 tras recortar,
  menos de 3 caracteres normalizados → lista vacía.
- `POST /movimientos` con `{ monto, descripcion, tipoMovimiento, categoriaId? }` → movimiento
  creado. (Alta mínima; el resto del CRUD va en F3b.)

## Dependencias a agregar
Ninguna (selectores de fecha nativos de Material).

## Alcance

### 1. Dominio — `lib/features/movimientos/domain/`
- `Movimiento` (`id`, `monto` **`Decimal`**, `descripcion`, `fecha` instante UTC,
  `tipoMovimiento`, `Categoria?`, `partidaId?`).
- `Categoria` (`id`, `codigo`, `nombre`, `iconId?`, `colorHex?`, `tipoPresupuesto?`).
- `MovimientoTipo` enum con los cinco valores del contrato.
- `MovimientoFiltro` (`desde`/`hasta` como `CalendarDate?`, `tipoMovimiento?`,
  `categoriaId?`, `q?`, `montoMin?`/`montoMax?` `Decimal?`); `toQueryParameters()` omite los
  nulos y serializa fechas con `CalendarDate.toJson()`.
- `PaginaMovimientos` (`content`, `currentPage`, `totalItems`, `totalPages`).
- `SugerenciaCategoria` (`categoriaId`, `codigo`, `nombre`, `confianza` **`Decimal`**,
  `motivo`) y `RespuestaSugerencia` (`texto`, `sugerencias`, `ambigua`).
- `SaldosRepository.saldoActual() → Decimal`;
  `MovimientosRepository.pagina(filtro, page, size=50)` / `registrar(...)`;
  `CategoriasRepository.listar()` / `sugerir(texto, contexto)`.

### 2. Datos — `lib/features/movimientos/data/`
- DTOs a mano según `openapi.json`. Montos con `moneyFromJson` (nunca `double`); fechas con
  `parseInstant`; sugerencias `confianza` también con `moneyFromJson` o `Decimal.parse` del
  número JSON (escala 2).
- Query de paginación: **no enviar parámetros nulos ni vacíos**; `size` fijo **50** desde la
  presentación; `page` base 0.
- Respuesta 204 y cuerpos inesperados se manejan como en F2 (sin exigir JSON donde no lo hay).

### 3. Home real (primer slice) — `lib/features/movimientos/presentation/`
- **Tarjeta de saldo** desde `GET /saldos/me` con `Money.formatClp` (saldo negativo incluido),
  estados de carga/error y reintento; se recarga al volver de registrar y con pull-to-refresh.
- **Listado paginado**: carga inicial `page=0&size=50`; al acercarse al final, siguiente página;
  se detiene cuando `currentPage + 1 >= totalPages` o `content` vacío; nunca dos cargas en
  vuelo; deduplicación por `id` (el backend podría solapar páginas si algo cambia).
- **Filtros**: rango de fechas (`desde`/`hasta`, inclusivos, date pickers) y tipo de movimiento
  (ninguno/todos los del enum). Cambiar un filtro reinicia el listado desde `page=0`. Estado
  vacío con mensaje y acción "quitar filtros".
- Cada ítem: descripción, fecha (zona America/Santiago para mostrar), categoría y monto
  formateado con signo/CLP. Estados de error con reintento sin perder los filtros.
- El botón "Nuevo movimiento" abre el alta mínima.

### 4. Alta mínima de movimiento (ancla del sugeridor)
- Campos: descripción, monto (`Money.parseUserInput`), categoría (dropdown desde
  `GET /categorias`) y tipo (`GASTO_GENERAL` por defecto). **El contrato no recibe fecha**
  (`MovimientoRegistroDTO`): el backend usa el instante del registro.
  `POST /movimientos`. `VALIDACION_FALLIDA` → `errores[]` por campo.
- Al éxito: cerrar, refrescar saldo y lista.

### 5. Sugeridor de categorías (desafío UX)
`SugerenciaCategoriaController` como **`AsyncNotifier`** en
`lib/features/movimientos/presentation/categoria_sugerencia_controller.dart`:
- **Debounce de 400 ms** desde la última tecla (testeable con `fakeAsync`).
- Una sola petición en vuelo por texto; al cambiar el texto se cancela/invalida la anterior.
- **Descarte por eco**: aplica la respuesta solo si `respuesta.texto` es **exactamente igual**
  al texto actual del formulario (incluidos espacios y mayúsculas, sin recortar). Si no, la
  descarta en silencio.
- **`ambigua=true`**: no se preselecciona en silencio; se exige **confirmación visible**
  (diálogo/elección explícita) antes de fijar la categoría.
- Con lista vacía no se preselecciona nada; con sugerencias, la primera queda preseleccionada
  y las demás como opciones rápidas (el usuario siempre puede cambiarla).
- `contexto` según el tipo del formulario: `GASTO` por defecto; `INGRESO` si el tipo es
  `INGRESO_GENERAL`. El texto nunca se registra en logs (G9).
- UI: `CategoriaSugeridaPicker` reutilizable sobre el campo descripción (chips de sugerencia +
  confirmación si ambigua).

### 6. Edición y eliminación (F3b)
- **Edición** (`PUT /movimientos/{id}`): mismo formulario que el alta, con
  `MovimientoFormScreen(movimiento: ...)`. `tipo` **no es editable** (el
  contrato no lo incluye; se muestra fijo) y la fecha tampoco. Edición
  parcial: solo viajan los campos con valor; `desvincularPartida` solo si es
  `true`. Al 200 se **reemplaza el ítem** en la lista y se refresca el saldo.
  Si el movimiento tiene partida y se cambia la categoría sin desvincular, el
  backend responde `400 DATOS_INVALIDOS` y se muestra su `detail`.
- **Eliminación** (`DELETE /movimientos/{id}` → 204): swipe-to-delete con
  diálogo de confirmación; al 204 se quita el ítem de la lista local y se
  refresca el saldo. Errores: SnackBar y el gesto se cancela.
- Solo se permite editar/eliminar `INGRESO_GENERAL` y `GASTO_GENERAL` sin
  deuda/meta (regla del backend; el resto responde 409).

## Pruebas
- DTOs: `saldo` negativo, `monto` con signo, `confianza` y `Decimal` sin `double`; página con
  `totalPages=0` y `content=[]`.
- Query: filtros nulos no se envían; `desde`/`hasta` como `yyyy-MM-dd`; `size=50`; `page`
  consecutiva.
- Listado: paginación acumulativa sin duplicados, corte en la última página, un solo fetch
  concurrente, reinicio a `page=0` al cambiar filtros, error conserva filtros.
- Saldo: se muestra formateado CLP y se refresca tras registrar.
- Alta: body exacto del contrato; `VALIDACION_FALLIDA` por campo; éxito refresca.
- Sugeridor: debounce (una llamada tras 400 ms), eco descarta respuestas viejas, `ambigua`
  exige confirmación visible, lista vacía no preselecciona, `contexto` correcto, sin logs del
  texto.
- Router: home real sigue exigiendo sesión; sin sesión → login.

## Seguridad
- Nada de `print` ni logs con descripciones/textos del usuario.
- Dinero siempre `Decimal`; el `double`/`num` solo existe al borde JSON.

## Fuera de alcance (posteriores)
Movimientos vinculados a deudas/metas/partidas (UI), filtros por categoría/
monto/texto en la UI (el dominio los soporta), navegación completa por
pestañas, presupuesto y reportes.

## Criterios de aceptación
- `flutter analyze` sin issues y `flutter test` en verde.
- Flujo manual en emulador con `ana.demo1`: saldo real visible, scroll infinito hasta el final,
  filtro por fecha y por tipo, y **alta de un movimiento con sugerencia de categoría**
  (incluido un caso `ambigua`, p. ej. "comida" o "cena aniversario") verificada en la app y en
  la BD. Si algo no se pudo ejecutar, decirlo explícitamente.
- Sin `print`, sin logs de credenciales/textos, sin `double` para dinero.

## Entrega
Commits locales sugeridos: `feat(movimientos): saldo y listado paginado con filtros`,
`feat(movimientos): alta minima con sugeridor de categorias`. Resumen: archivos, decisiones,
pruebas y pendientes.
