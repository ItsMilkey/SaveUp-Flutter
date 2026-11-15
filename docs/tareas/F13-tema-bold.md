# F13 — Tema adicional Bold

## Objetivo

Añadir una variante visual «Bold», cercana al tema claro y basada en las referencias neo
brutalistas, con color por bloques, outline de tinta y acentos más expresivos. Permitir elegir y
previsualizar Sistema, Claro, Oscuro y Bold desde una pantalla abierta por «Más».

## Prerrequisito

- F0–F8 y F10–F12 implementadas; F9 (push) no es prerrequisito.
- No requiere backend ni sincronización de contrato.

## Lecturas previas

- `docs/CONTEXT.md` (decisión D14).
- `docs/Design_System/DESIGN_SYSTEM_PLAN.md` y `docs/Design_System/References/`.
- `.agents/rules/flutter-dart.md`.
- `lib/core/design_system/theme/saveup_theme.dart` y `saveup_colors.dart`.
- `lib/main.dart`, `lib/app/router.dart` y `lib/app/app_shell.dart`.

## Alcance

- Conservar claro/oscuro y el modo `Sistema` por defecto.
- Añadir `SaveUpTheme.bold()` con paleta de papel cálido, tinta, superficies pastel y acentos
  vibrantes. Mantener colores semánticos de éxito, aviso, error, tipos y estados financieros.
- Parametrizar colores que cambien por tema mediante roles `SaveUpColors`; no reemplazar todos
  los `AppColors` a ciegas.
- Añadir la preferencia `system/light/dark/bold` y un repositorio local para guardar solo esa
  opción no sensible (`shared_preferences`, API `SharedPreferencesAsync`). Credenciales siguen
  exclusivamente en `flutter_secure_storage`.
- Agregar `Más → Tema` como ruta a una pantalla dedicada. Mostrar una miniatura realista de cada
  tema, marcar el actual y aplicar/persistir la selección al tocar una opción sin salir de la
  pantalla. «Sistema» refleja la luminosidad actual del dispositivo.
- Mantener previews aislados del tema global: ver una tarjeta no cambia selección; seleccionar sí.
- Actualizar showcase, documentación de contexto y pruebas.

## Pruebas

- Tema: roles Bold y contraste; claro/oscuro mantienen valores y semántica.
- Preferencia: parseo de datos desconocidos a `system`, provider con fake repository,
  persistencia/selección sin tocar backend.
- Widget: las cuatro previews se muestran; selección actual marcada; escoger Bold actualiza el
  tema raíz y guarda el valor; fallar al guardar mantiene la opción previa.
- Router: desde «Más», «Tema» abre la pantalla con las cuatro miniaturas.
- Goldens de showcase/preview Bold sin regenerar snapshots no relacionados.
- `flutter analyze`, `flutter test` y verificación visual en emulador Android de Sistema, Claro,
  Oscuro y Bold. Docker no es necesario.

## Fuera de alcance

- Tema oscuro Bold, sincronización de preferencia con backend/cuenta, cambios de lógica financiera,
  ilustraciones nuevas o rediseño completo de cada pantalla.
- Cambiar los colores que identifican estados financieros, errores o tipos de presupuesto sin
  preservar su semántica.

## Criterios de aceptación

- La primera ejecución y las instalaciones existentes conservan «Sistema»; una selección guardada
  se restaura antes de mostrar la interfaz inicial.
- En `Más → Tema`, cada opción tiene una vista previa legible; el tema activo se reconoce con
  etiqueta/check y selección semántica.
- Elegir otra opción cambia la app inmediatamente y persiste tras reiniciar; volver a Sistema
  restaura el comportamiento OS.
- Bold es claramente más expresivo que Claro, respeta contrastes y no altera claro/oscuro.
- `flutter analyze` limpio y pruebas de la funcionalidad aprobadas; fallos de golden baseline
  externos quedan documentados sin actualizarse accidentalmente.

## Entrega

- Implementación solo en frontend, sin cambios de contrato/backend; un commit local en español al
  cerrar.
