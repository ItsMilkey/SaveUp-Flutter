# Tareas de saveup_app

Cada tarea es un archivo `Fn-nombre.md` con: **Objetivo**, **Prerrequisito**, **Lecturas previas**,
**Alcance**, **Pruebas**, **Fuera de alcance**, **Criterios de aceptación** y **Entrega**.
Se ejecutan en orden con el workflow `/nueva-feature` (ej. `/nueva-feature docs/tareas/F0-core.md`).
Al terminar, marcar aquí con `[x]`.

## Plan

- [x] **F0** núcleo: dinero, tiempo, errores y cliente HTTP con sesión — `F0-core.md`
- [ ] **F1** autenticación, sesión persistente y versión mínima — `F1-auth.md`
- [ ] **F2** cuenta: recuperar y cambiar contraseña, eliminar cuenta, legales (el envío de correo
  está pendiente en producción; legales depende de T9.7 del backend)
- [ ] **F3** movimientos, saldo y categorías (primer corte vertical completo: listar, crear,
  filtrar, editar, eliminar; pantalla de inicio real)
- [ ] **F4** deudas: lista, detalle, pagos flexibles, amortización, cancelar
- [ ] **F5** simulador de endeudamiento (`POST /simulaciones/credito`)
- [ ] **F6** presupuesto: configuración, ejecución, historial, límites por categoría
- [ ] **F7** metas de ahorro: crear, abonar, retirar
- [ ] **F8** exportar reportes (guardar/compartir archivo)
- [ ] **F9** notificaciones push (requiere proyecto Firebase y, para iOS, cuenta de Apple
  Developer de pago; en producción el backend las tiene desactivadas)

Las tareas F2 en adelante se redactan cuando se acerque su turno, con el contrato real a mano.
