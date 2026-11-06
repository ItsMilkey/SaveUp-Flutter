# F4 — Deudas y simulador de crédito

> **Avance (2026-11-06): implementada y verificada.**
> - Commit `f9c12be`: dominio/data (DTOs a mano, `Decimal`, fechas
>   calendario/instante), `/deudas` con progreso y segmentación
>   activas/historial, detalle con ficha y cronograma, formulario de
>   alta/edición (bloqueado si ya hay pagos).
> - Commit `99e71d3`: `POST /deudas/{id}/pagar` (cuota calculada o monto
>   libre, refresca deuda + movimiento + saldo), historial paginado
>   (`/pagos`, size 20), `PATCH cancelar` con confirmación defensiva y
>   `/simulador` (cuota, CAE, resumen educativo, tabla, comparación y
>   advertencias).
> - **Verificación manual (emulador, backend real): PASÓ.** Deuda «Credito»
>   120.000 en 12 cuotas sin interés; pago de cuota → movimiento
>   `PAGO_DEUDA -10.000` en BD y saldo del home `-$10.000`, ficha `1 de 12`
>   y edición bloqueada; deuda «Tarjeta» cancelada → estado `CANCELADA` en
>   BD; simulación 500.000 a 12 cuotas con 1,5 % con tabla y advertencia del
>   CAE. 230 tests verdes y `flutter analyze` limpio.
> - Datos demo dejados a propósito: una deuda activa (para vincular partidas
>   en F6a) y una cancelada; el pago demo deja saldo `-$10.000`.

## Objetivo
Gestionar los pasivos del usuario (listar, crear/editar condiciones, pagar cuotas o abonos, ver
cronograma e historial, cancelar) y ofrecer un **simulador de crédito puro** para decidir antes
de endeudarse. F4 va antes que F6a porque las partidas del plan pueden vincularse a una deuda
real (`deudaId`), y conviene tener deudas reales para validar ese vínculo.

## Prerrequisito
F3 cerrada (commits `8c53403` … `07324d0`).

## Lecturas previas
`docs/CONTEXT.md`, `docs/contrato/CLIENTE_FLUTTER.md` (paginación: pagos `size` 20 por defecto)
y `docs/contrato/openapi.json`. Reglas de negocio del backend: `backend/docs/tareas/T1b`,
`T1c`, `T2` y `T3`.

## Endpoints del contrato (no inventar otros)
- `GET /deudas/me` → `200 [DeudaResponseDTO]` (incluye activas y canceladas; el estado viene en
  `estado`).
- `GET /deudas/{deudaId}` → `200 DeudaResponseDTO` (detalle).
- `POST /deudas` y `PUT /deudas/{deudaId}` con **el mismo** `DeudaCreacionDTO` → `200 DeudaResponseDTO`.
- `POST /deudas/{deudaId}/pagar` con `PagoDeudaDTO` → `200 DeudaResponseDTO` (crea un movimiento
  `PAGO_DEUDA` con monto negativo en el backend).
- `GET /deudas/{deudaId}/pagos?page&size` → `200 PageResponseDTO<PagoDeudaResponseDTO>`
  (historial, orden fecha desc; **es este endpoint, no `/historial`**).
- `GET /deudas/{deudaId}/amortizacion` → `200 [CuotaSimulacionDTO]` (cronograma con
  `estado`, `montoPagado`, `previa`).
- `PATCH /deudas/{deudaId}/cancelar` → `200 DeudaResponseDTO`
  (409 si la deuda ya está `PAGADA`; **no** genera movimiento ni mueve el saldo).
- `POST /simulaciones/credito` con `SimulacionCreditoRequestDTO` →
  `200 SimulacionCreditoResponseDTO` (sin persistencia).

## Reglas del contrato que la UI debe respetar
- **Tasas en porcentaje**, no fracción: `1.5` = 1,5 %. (`tasaMensual`, `tasaAnualEfectiva`, CAE).
- **Dinero** siempre `Decimal` (borde JSON con `moneyFromJson`/`moneyToJson`);
  fechas de calendario con `CalendarDate`; instantes con `parseInstant`.
- `CuotaSimulacionDTO.fechaVencimiento` es `yyyy-MM-dd` (no instante) y es opcional.
- **Crear una deuda no mueve el saldo**; solo los pagos generan `PAGO_DEUDA`.
- `cuotasPagadasPrevias`: no crean movimientos ni tocan saldo; deben ser `< cantidadCuotas`.
- **Editar** (`PUT`) solo si la deuda **no tiene pagos** (`PAGO_DEUDA`): 409 en caso contrario.
- **Pagar**: `modoPago` `CUOTA_CALCULADA` (ignora `monto`, cobra lo pendiente de la próxima
  cuota) o `MONTO_PERSONALIZADO` (monto obligatorio > 0, por defecto). 409 si el monto supera
  el total por pagar o si la deuda no está `PENDIENTE`.
- Estados: `PENDIENTE | PAGADA | CANCELADA`. `cuotasPagadas` son las efectivamente pagadas
  (incluye previas); la barra de progreso usa `cuotasPagadas / cantidadCuotas`.
- Simulador: plazo por `cantidadCuotas` **o** `fechaPrimeraCuota`+`fechaUltimaCuota` (exactamente
  una); en `TASA_CONOCIDA` exactamente una de las dos tasas; `valorCuota` solo en
  `CUOTA_CONOCIDA`; `cantidadCuotasAlternativas` máx. 5 (solo SIN_INTERES/TASA_CONOCIDA);
  `incluirTabla` por defecto `true`.

## Dependencias a agregar
Ninguna.

## Alcance

### 1. Dominio — `lib/features/deudas/domain/`
- `Deuda` con todos los campos de `DeudaResponseDTO` que la UI usa (id, nombre, descripción,
  `TipoDeuda`, `ModalidadCalculo`, `EstadoDeuda`, montos `Decimal`, tasas `Decimal`, fechas,
  `cuotasPagadas`, `cantidadCuotas`, `proximaCuota*`, `interesesPagados`).
- `PagoDeuda` (`id`, `fecha` instante, `monto`, `capital`, `interes`, `costos`, `descripcion`).
- `CuotaAmortizacion` (número, vencimiento `CalendarDate?`, cuota, capital, interés, costo
  adicional, saldo, `estado` `PAGADA|PARCIAL|PENDIENTE`, `montoPagado`, `previa`).
- `PaginaPagos` (`content`, `currentPage`, `totalItems`, `totalPages`, `esUltima`).
- `DeudasRepository`: `listar()`, `detalle(id)`, `crear(...)`, `editar(id, ...)`,
  `pagar(id, {monto?, modoPago, descripcion})`, `pagos(id, page, size=20)`,
  `amortizacion(id)`, `cancelar(id)`.
- `SimuladorRepository.simular(SimulacionCreditoRequest)`.

### 2. Datos — `lib/features/deudas/data/`
DTOs a mano espejo de los schemas (`DeudaCreacionDTO`, `DeudaResponseDTO`, `PagoDeudaDTO`,
`PagoDeudaResponseDTO`, `PageResponseDTO…`, `CuotaSimulacionDTO`,
`SimulacionCreditoRequestDTO`/`ResponseDTO`, `ResumenEducativoDTO`, `ComparacionPlazoDTO`).
Query `page`/`size` solo en pagos. Errores ya traducidos por `ApiClient`.

### 3. Listado de deudas — `/deudas`
- Cards con: nombre, tipo, estado, **barra de progreso** `cuotasPagadas/cantidadCuotas`,
  `montoRestante`/`totalPorPagar`, próxima cuota (número, monto pendiente y vencimiento si
  existe). Montos con `Money.formatClp`.
- Segmentación visual **Activas** (`PENDIENTE`) y **Canceladas/Pagadas** (sección o pestañas),
  derivada de `estado`.
- Entrada desde el home (acción "Deudas" en el AppBar o tarjeta de acceso) y FAB
  "Nueva deuda" → formulario. La lista se recarga al volver de pagar/editar/cancelar.

### 4. Detalle — `/deudas/{id}`
- Ficha: condiciones (modalidad, capital, tasas %, cuota, gastos, CAE, costo total), estado,
  progreso y próxima cuota.
- **Cronograma** desde `GET /deudas/{id}/amortizacion` (tabla con estado por cuota y marca
  "previa"; las pagadas/parciales se diferencian).
- **Historial paginado** desde `GET /deudas/{id}/pagos` (`size=20`, scroll infinito, mismos
  criterios de F3: sin doble carga, corte por `totalPages`, dedupe por `id`), con desglose
  capital/interés/costos por pago.
- Acciones: **Pagar** (diálogo con modo `CUOTA_CALCULADA` o monto personalizado + descripción),
  **Editar** (si `estado=PENDIENTE`; el backend igual puede responder 409 si ya hay pagos →
  mostrar el mensaje), **Cancelar** (diálogo defensivo, `PATCH cancelar`).

### 5. Alta/edición — `/deudas/nueva` y `/deudas/{id}/editar`
Formulario con el mismo `DeudaCreacionDTO`:
nombre, descripción, tipo; **modalidad** (`SIN_INTERES`, `TASA_CONOCIDA`, `CUOTA_CONOCIDA`);
`montoCapital`; plazo por **cuotas** o por **fechas** (exactamente una vía);
tasa mensual **o** anual (una sola, en %); `valorCuota` (solo CUOTA_CONOCIDA);
`gastosIniciales`, `costoAdicionalPorCuota`; `cuotasPagadasPrevias`.
Validación local de las reglas por modalidad/plazo antes de enviar; `VALIDACION_FALLIDA` se
reparte por campo (`errores[]`). Al 200: volver al detalle/lista con la deuda actualizada.

### 6. Pago y saldo
- Al 200 de `pagar`, actualizar la deuda mostrada y **refrescar saldo y movimientos** (el
  backend crea el `PAGO_DEUDA`): al volver al home desde deudas, `MovimientosController` ya
  recarga al montar; además ofrecer "Pagar" desde el detalle sin salir.
- El diálogo muestra el monto pendiente de la próxima cuota y el saldo capital como referencia
  para pagos personalizados.

### 7. Simulador — `/simulador`
- Formulario según reglas del request (modalidad, capital, plazo/tasas/cuota, gastos,
  ingreso mensual opcional, plazos alternativos opcionales, incluir tabla).
- Resultado: cuota, monto total, costo del crédito, CAE, intereses y costos,
  `resumenEducativo` (% sobre capital/total/ingreso), tabla de amortización, comparación de
  plazos y **advertencias** (siempre mostrar la del CAE referencial).
- Acceso desde la lista de deudas ("Simular crédito") y desde el alta (opcional).
- Todo se calcula en el backend: la app no reimplementa el motor.

## Pruebas
- DTOs: tasas en porcentaje, montos `Decimal`, fechas calendario vs instante, enums,
  página de pagos vacía.
- Repositorio: cuerpos exactos de crear/editar (mismo DTO), `pagar` con `CUOTA_CALCULADA` sin
  `monto` y con monto; `page`/`size=20` en pagos; `PATCH cancelar`; simulación con cuerpo
  exacto y parseo de tabla/comparación/advertencias; 409 y `VALIDACION_FALLIDA`.
- Listado: progreso y próxima cuota, separación activas/canceladas.
- Detalle: cronograma con estados, historial paginado sin duplicados, pago refresca la ficha
  (y el saldo al volver), cancelar exige confirmación.
- Formulario: reglas por modalidad/plazo (validaciones locales y del backend), 409 al editar
  con pagos.
- Simulador: reglas cruzadas del request, render de tabla/comparación/advertencias.

## Seguridad
- Sin `print` ni logs de datos financieros; dinero nunca en `double`.
- Confirmación explícita para cancelar una deuda y para registrar pagos.

## Fuera de alcance
- Recalcular el cronograma por abonos extra (el backend no lo hace).
- Pago de deudas desde el formulario de movimientos (el backend lo delega; la UI de F4 usa
  `POST /deudas/{id}/pagar`).
- Vincular deudas a partidas del plan: llega en F6a (solo se valida que existan deudas reales).
- Historial global de pagos entre deudas, notificaciones y reportes.

## Criterios de aceptación
- `flutter analyze` sin issues y `flutter test` en verde.
- Flujo manual en emulador con `ana.demo1`: crear una deuda (modalidad con tasa), ver la card
  con progreso, pagar una cuota (`CUOTA_CALCULADA`) → saldo y `PAGO_DEUDA` visibles en home,
  abrir detalle (cronograma + historial), pagar un monto personalizado, cancelar una deuda en
  estado `PENDIENTE`, y simular un crédito viendo cuota/CAE/tabla/advertencias. Verificar filas
  y estado en BD. Si algo no se puede ejecutar, decirlo.
- Sin `print`, sin `double` de dinero.

## Entrega
Commits locales sugeridos: `feat(deudas): listado, detalle y formulario de deudas` y
`feat(deudas): pagos, cancelacion y simulador de credito`. Resumen con archivos, decisiones,
pruebas y pendientes.
