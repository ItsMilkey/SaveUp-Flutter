# F14 — Colaboraciones: metas compartidas y deudas directas

## Objetivo

Implementar el primer corte colaborativo de SaveUp: metas compartidas, deudas directas entre dos cuentas,
invitaciones con aceptación, movimientos confirmables e historial en una bandeja in-app.

## Decisiones de producto aplicadas

- Invitaciones ligadas al correo, válidas por 7 días y revocables; el código opaco se almacena como hash y se
  muestra una vez para copiarlo. El destinatario autenticado también puede aceptar o rechazar desde su bandeja.
- Aceptar una invitación a meta confirma solo participación; aceptar una deuda directa confirma dirección y monto.
- El pago propio del deudor se aplica al instante; un pago que otra persona atribuye al deudor espera confirmación.
- La condonación puede ser parcial o total y requiere confirmación bilateral.
- Los gastos de meta usan el prorrateo del servidor con precisión de 2 decimales; los centavos residuales se asignan
  al mayor saldo atribuible (empate por RUT estable).
- Esta fase usa una bandeja in-app, sin correo ni push.
- Montos CLP, hasta 2 decimales; dinero en Dart con `Decimal`. La app no recalcula saldos ni prorrateos.

## Contrato

Las copias de solo lectura en `docs/contrato/` se sincronizan desde el backend. Consultar
`docs/contrato/openapi.json` para paths, DTOs y estados:

- Metas y deudas directas: creación, listado, invitación y aceptación/rechazo.
- Operaciones: aportes, gastos, retiros, pagos, condonaciones, propuestas y confirmaciones.
- Historial por recurso y bandeja de actividad.

## Alcance de interfaz

- Entrada desde «Más → Colaboraciones».
- Secciones de metas, deudas, invitaciones y actividad con carga/error/vacío/pendiente.
- Crear metas compartidas y deudas directas; luego mostrar/copiar el código de invitación.
- Aportar, gastar y retirar de metas; pagar, condonar o proponer cambio de saldo en deudas.
- Confirmar/rechazar operaciones pendientes; presentar el historial y `atribuciones[]` del backend.
- En `/metas`, marcar metas compartidas y dirigir sus acciones a Colaboraciones; no ofrecer acciones individuales.

## Estructura

`lib/features/colaboraciones/{domain,data,presentation}`. HTTP por `ApiClient`, dominio con `Decimal`, estado
Riverpod y componentes del design system actual. Sin generadores ni dependencias nuevas.

## Pruebas

- DTOs/repositorio: paths, payloads, parseo de dinero/fechas y estados de confirmación.
- Controladores: carga, refresh, aceptar/rechazar, movimientos y propagación de `AppFailure`.
- Widgets: secciones y estados; formularios; respuestas de invitación y confirmación.
- Cierre: `flutter analyze` y `flutter test`; verificación manual con dos cuentas si hay emulador disponible.

## Fuera de alcance

- Deudas compartidas con acreedor externo, reparto entre varios deudores o cuotas.
- Correo, push y enlaces universales.
- Recalcular saldos, atribuciones o redondeo en Flutter.
