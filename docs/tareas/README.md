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
- [ ] **F3** movimientos, saldo y categorías (primer corte vertical completo: listar, crear,
  filtrar, editar, eliminar; pantalla de inicio real) — **corte completo hecho**: saldo, listado
  con filtros, alta, sugeridor, edición y eliminación; verificación manual registrada.
- [ ] **F4** deudas: lista, detalle, pagos flexibles, amortización, cancelar
- [ ] **F5** simulador de endeudamiento (`POST /simulaciones/credito`)
- [ ] **F6** presupuesto: configuración, ejecución, historial, límites por categoría,
  sugerencia-regla
- [ ] **F6a** plan mensual: partidas, grupos, sliders con cálculo local (D6) y lote atómico
  de montos — `F6a-plan-mensual.md` (ya redactada: se reservaron su contrato y sus fórmulas
  en la misma pasada de análisis)
- [ ] **F7** metas de ahorro: crear, abonar, retirar
- [ ] **F8** exportar reportes (guardar/compartir archivo)
- [ ] **F9** notificaciones push (requiere proyecto Firebase y, para iOS, cuenta de Apple
  Developer de pago; en producción el backend las tiene desactivadas)

Las tareas F2 en adelante se redactan cuando se acerque su turno, con el contrato real a mano.
