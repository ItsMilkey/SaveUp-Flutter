# Tareas de saveup_app

Cada tarea es un archivo `Fn-nombre.md` con: **Objetivo**, **Prerrequisito**, **Lecturas previas**,
**Alcance**, **Pruebas**, **Fuera de alcance**, **Criterios de aceptación** y **Entrega**.
Se ejecutan en orden con el workflow `/nueva-feature` (ej. `/nueva-feature docs/tareas/F0-core.md`).
Al terminar, marcar aquí con `[x]`.

## Plan

- [x] **F0** núcleo: dinero, tiempo, errores y cliente HTTP con sesión — `F0-core.md`
- [x] **F1** autenticación, sesión persistente y versión mínima — `F1-auth.md`
- [x] **F2** cuenta: recuperar y cambiar contraseña, eliminar cuenta, legales (envío de correo
  pendiente en producción; cuerpo legal provisional hasta que exista su fuente)
- [x] **F3** movimientos, saldo y categorías (primer corte vertical completo: listar, crear,
  filtrar, editar, eliminar; pantalla de inicio real) — implementada y verificada manualmente
  (saldo, filtros, alta con sugeridor, edición y eliminación) — `F3-movimientos.md`
- [x] **F4** deudas: lista, detalle, pagos flexibles, amortización, cancelar y simulador de
  crédito — `F4-deudas.md` (implementada y verificada manualmente; deja una deuda activa demo
  para vincular partidas en F6a)
- [x] **F5** simulador de endeudamiento (`POST /simulaciones/credito`) — **absorbida por F4**:
  el simulador se implementó y verificó dentro de F4 (no requiere tarea aparte)
- [x] **F6** presupuesto: configuración, ejecución, historial, límites por categoría,
  sugerencia-regla — `F6-presupuesto.md` (completa: regla con autobalanceo, ejecución/historial,
  límites y tipos preferidos; verificada manualmente. Incluye fix de backend para reemplazar
  límites existentes sin 409)
- [x] **F6a** plan mensual: partidas, grupos, sliders con cálculo local (D6) y lote atómico
  de montos — `F6a-plan-mensual.md` (completa: motor validado por 33 vectores, controlador,
  pantalla, ingreso de referencia, CRUD de partidas/grupos, referencias y copia; verificada
  manualmente)
- [x] **F7** metas de ahorro: crear, abonar, retirar — `F7-metas-ahorro.md`
  (completa: lista, alta/edición, abonos/retiros con movimientos reales, eliminación con
  reintegro y meta base protegida; verificada manualmente. `asignaciones[]` queda fuera porque el
  contrato no las expone en ninguna lectura)
- [x] **F8** exportar reportes (guardar/compartir archivo) — `F8-reportes.md`
  (completa: CSV/PDF, alcance completo o mensual, descarga binaria, hoja de compartir y entrada
  desde el home; verificada manualmente)
- [ ] **F9** notificaciones push (requiere proyecto Firebase y, para iOS, cuenta de Apple
  Developer de pago; en producción el backend las tiene desactivadas)
- [x] **F10** analítica de gastos: torta por categoría y barras mensuales — `F10-analitica.md`
  (completa: KPIs, torta con «Sin categoría», tendencia de 6 meses, reparto por tipo y top de
  categorías con `fl_chart`; entrada desde «Más»)
- [x] **F11** asignaciones del ahorro a metas — `F11-asignaciones-presupuesto.md`
  (completa: sección «Distribución del ahorro» con `GET`/`POST`, autobalanceo a 100.00 y tests)

Las tareas F2 en adelante se redactan cuando se acerque su turno, con el contrato real a mano.
