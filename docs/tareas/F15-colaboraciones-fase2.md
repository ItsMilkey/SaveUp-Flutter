# F15 — Colaboraciones fase 2: deuda compartida con un tercero

## Alcance

Implementar en la app la etapa 2 del plan: deudas con un acreedor externo repartidas entre 2 a 10
personas, con cuotas opcionales, pagos con imputación, adelantos y salida con reasignación. El
contrato proviene de LITE T12 (`a461379`, migración V19); las copias `docs/contrato/*` son de solo
lectura y las trae `scripts/sync-contract.ps1` del workspace.

## Decisiones aplicadas

- **Doble presencia:** la deuda grupal se lista en `Colaboraciones → Deudas` (donde se opera) y en
  la pantalla `Deudas` con un distintivo "Compartida" que redirige a Colaboraciones.
- El alta pide el total, el acreedor externo (texto libre), el reparto por participante (incluida la
  propia persona, suma exacta) y cuotas opcionales; atajos de reparto equitativo y cuotas mensuales
  iguales con precisión de centavos.
- El pago prellena la imputación proporcional al pendiente y permite equitativa o manual; valida que
  la suma sea exacta antes de enviar. La parte propia se aplica de inmediato y el resto queda
  pendiente: el estado real lo trae el backend.
- El botón "Registrar adelanto" aparece solo en pagos confirmados de quien desembolsó con partes a
  otras personas; genera una deuda directa que la contraparte acepta con la invitación.
- El reparto y la salida proponen montos sobre el pendiente con confirmación de los demás; la
  responsabilidad original nunca se edita desde la app.
- La bandeja de actividad y las invitaciones reutilizan fase 1; la invitación grupal muestra
  acreedor externo, total y responsabilidad ofrecida.

## Pantallas y archivos

- `lib/features/colaboraciones/domain/colaboracion.dart`: `DeudaGrupal`, participantes con
  responsabilidad, cuotas, `MontoParticipante` y datos de entrada de pago/reparto/salida.
- `lib/features/colaboraciones/data/dio_colaboraciones_repository.dart`: snapshot con
  `/deudas-grupales/me` y las rutas de fase 2 (crear, pagar, repartir, salir, adelantos, cancelar,
  historial).
- `lib/features/colaboraciones/presentation/colaboraciones_forms.dart`: formularios de alta con
  editor de participantes y cuotas, pago con imputaciones, reparto, salida y adelanto. Repartos
  exactos en centavos solo para prellenar.
- `lib/features/colaboraciones/presentation/colaboraciones_screen.dart`: tarjetas de deuda grupal
  con acciones, historial con adelantos, invitación grupal y FAB con selector de tipo de deuda.
- `lib/features/deudas/presentation/deudas_screen.dart`: listado con distintivo "Compartida" que
  redirige a Colaboraciones.

## Verificación

- `flutter analyze` limpio y suite completa en verde (547 tests) con cobertura nueva: snapshot
  grupal, crear con reparto/cuotas, pago con imputaciones, reparto/salida y render de tarjeta.
- Flujo end-to-end validado contra el backend real (Docker + PostgreSQL 16) en emulador Android.
