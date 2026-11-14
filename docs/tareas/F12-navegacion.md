# F12 — Navegación flotante neo brutalista

## Objetivo

Modernizar `NeoBottomNav` para destacar la pantalla actual con un icono elevado y ampliado, un
indicador animado que se desliza al cambiar de destino y navegación opcional por arrastre
horizontal.

## Prerrequisito

- F0–F11 implementadas.
- No requiere cambios ni sincronización de contrato del backend.

## Lecturas previas

- `docs/CONTEXT.md` (decisión D13).
- `lib/core/design_system/components/navigation/neo_bottom_nav.dart`.
- `lib/app/app_shell.dart` y `lib/app/router.dart`.
- `.agents/rules/flutter-dart.md`.

## Alcance

- Conservar la cápsula flotante, bordes/sombra neo y colores del tema SaveUp claro/oscuro.
- El destino confirmado se controla desde `AppShell.location`; la vista no persiste una selección
  independiente.
- El icono activo sobresale del rail, crece y se desliza al cambiar de ruta; las etiquetas no
  deben saltar ni solaparse.
- Tap navega de inmediato. Arrastrar por Inicio, Deudas, Plan y Presupuesto previsualiza; al soltar
  en uno de ellos se llama una sola vez a `onSelected`. Cancelar o soltar fuera restaura la ruta.
- `Más` permanece como acción por toque y se declara explícitamente no arrastrable.
- Mantener destinos táctiles, Semantics de botón/etiqueta/selección, `SafeArea` y soporte de
  `MediaQuery.disableAnimations`.
- Actualizar la showcase del design system y los goldens claro/oscuro de navegación.

## Pruebas

- `test/core/design_system/design_system_navigation_test.dart`: tap, animación de ruta externa,
  arrastre/confirmación única, cancelación, `Más`, cambio de selección durante previsualización,
  Semantics, movimiento reducido y layout estrecho con texto ampliado.
- `test/core/design_system/design_system_navigation_golden_test.dart`: apariencia de navegación
  en claro y oscuro.
- Ejecutar `flutter analyze` y `flutter test`.
- Verificar manualmente en Android/iOS el toque, el arrastre, cancelación, `Más`, ambos temas y
  movimiento reducido.

## Fuera de alcance

- Cambiar rutas, número/orden de destinos, shell de detalles o comportamiento del menú `Más`.
- Añadir backend, estado global, dependencias o lógica de negocio.

## Criterios de aceptación

- El icono de la ruta actual es visiblemente más grande y se eleva sobre la píldora; el indicador
  se desliza al cambiar de tab.
- Arrastrar y soltar confirma un único destino principal; cancelar no cambia la ruta.
- `Más` solo abre su menú al tocarlo y no figura como pantalla seleccionada.
- Sin recortes/overflows a 320 dp, con texto ampliado, tema oscuro o safe area.
- Semantics expone botones/etiquetas/selección y la preferencia de movimiento reducido se respeta.
- `flutter analyze` sin problemas; tests focales/goldens de navegación pasan.

## Entrega

- Implementada en frontend; componente y tests en `core/design_system`, integración en el shell y
  showcase, decisión D13 en `docs/CONTEXT.md`.
