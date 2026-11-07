# F11 — Asignaciones del ahorro a metas

> **Estado: backend y contrato listos (2026-11-07); data/UI pendientes.** La
> pantalla se implementará con el rediseño UI/UX, igual que F10.

## Objetivo
Que la persona decida **cómo repartir su porcentaje de ahorro entre sus metas**
(por ejemplo 60 % viaje / 40 % notebook) y que la app pueda leer y editar ese
reparto sin sobrescribir lo que no ve.

## Contrato (ya implementado en LITE)
| Método | Ruta | Uso |
|---|---|---|
| `GET` | `/presupuestos/asignaciones/me` | `200 [{metaId, metaNombre, porcentaje}]`; `[]` si no hay configuración o asignaciones |
| `POST` | `/presupuestos/me` | Campo opcional `asignaciones: [{metaId, porcentaje}]` |

Reglas:
- `asignaciones` omitido o `null`: conserva las actuales.
- `asignaciones: []`: las elimina todas (sin automatización).
- Lista: cada `porcentaje` > 0, sin metas repetidas, todas del usuario y **suma
  exacta 100.00**. Cualquier violación responde `400 DATOS_INVALIDOS` con
  `detail`; no se omite en silencio.
- El Smart-Split reparte el `porcentajeAhorro` según estas asignaciones. Con suma
  100 se asigna todo el ahorro; por eso no se permite sumar más ni dejar huecos
  sin querer. Si se quiere dejar una parte “sin meta”, se asigna a la meta base
  «Ahorros».
- La app debe leer primero el `GET` y enviar el conjunto completo al guardar.

## UX propuesta
- Dentro de la pantalla de presupuesto, sección **«Distribución del ahorro»**:
  - Lista de metas del usuario (`GET /metas/me`) con su porcentaje editable.
  - «Agregar meta» para las que aún no están asignadas.
  - Indicador `Total: 87.50 % / 100.00 %`; el guardado se bloquea si no es
    exactamente 100.00, con el mensaje de cuánto falta/sobra.
  - Botón para quitar una asignación.
  - Auto-ajuste opcional: al mover una, repartir el resto proporcionalmente como
    en la regla 50/30/20 (con `Decimal`; `double` solo en el slider).
  - Estado vacío: «Sin distribución: el ahorro queda en la meta base». El botón
    «Limpiar distribución» envía `[]`.
  - Si `automatizarAhorroEnMetas` está apagado, mostrar que la distribución se
    guarda pero no se ejecutará hasta activarlo.
- La sección convive con la regla 50/30/20: el `POST /presupuestos/me` lleva los
  tres porcentajes, `activo`, `automatizarAhorroEnMetas` y `asignaciones`.
- Si el `GET` de asignaciones falla, ocultar la sección y **omitir**
  `asignaciones` al guardar la regla (no borrar datos que no se pudieron leer).

## Data/controlador (frontend)
- Dominio `AsignacionPresupuesto` (`metaId`, `metaNombre`, `porcentaje` `Decimal`)
  y `AsignacionPresupuestoDatos` para el request.
- Repositorio de presupuesto: añadir `Future<List<AsignacionPresupuesto>> listarAsignaciones()`.
- Controlador de la sección: carga metas + asignaciones, edita porcentajes,
  agrega/quita, valida suma 100 en `Decimal`, guarda el conjunto completo y
  refresca; errores por campo/`detail`.
- Reutilizar `Money`/`Decimal` y el patrón de autobalanceo de F6.
- Tests de contrato (GET y cuerpo del POST), controlador (suma/validación),
  widget (sección, total, estado vacío, 400).
- Sin dependencias nuevas.

## Fuera de alcance
- La ejecución automática de abonos (ya vive en el backend/Smart-Split).
- Cambiar la regla 50/30/20 desde esta sección (se hace en F6).
- Analítica (F10) y rediseño visual (tarea aparte).

## Criterios de aceptación
- Leer una distribución existente y mostrarla.
- Guardar 60/40, verla en el `GET` y en el Smart-Split.
- Rechazar 60/30 con el `detail` del backend y bloquear el guardado local.
- Limpiar la distribución y verificar `[]`.
- Meta base/ajena y errores de red manejados sin perder datos.
