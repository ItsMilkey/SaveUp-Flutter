# Reglas Flutter/Dart (siempre activas)

Aplican a todo el código de este repositorio, sin excepción.

## Lenguaje y nombres

- **Null safety** activado: no usar `!` para silenciar nulabilidad salvo que sea
  demostrablemente seguro, y nunca en datos que vienen del backend.
- Código y nombres de símbolos en **inglés**; documentación y comentarios en
  **español**.
- Archivos y carpetas en `snake_case`. Clases en `PascalCase`, variables y
  métodos en `camelCase`.
- **Un archivo por widget público.** Los widgets privados auxiliares pueden
  vivir en el mismo archivo que su widget público.

## Estado

- **Riverpod es el único gestor de estado.** No usar `setState` para estado de
  negocio, ni `Provider` de `provider`, ni Bloc, ni GetX.
- `setState` solo se admite para estado efímero de UI (animaciones, controllers).
- Los providers viven cerca de la feature que los usa; los transversales, en
  `lib/core/` o `lib/app/`.

## Separación de capas

- **Sin lógica de negocio en widgets.** Los widgets solo leen estado y emiten
  eventos; la lógica vive en `domain` o en los notifiers/providers.
- Nada de llamadas HTTP directas desde `presentation`: siempre a través de
  repositorios/casos de uso.

## Dinero

- **Nunca `double` para dinero.** Usar `Decimal` de `package:decimal`.
- Parsear montos del backend con `Money.parse` y mostrarlos con
  `Money.formatClp`.

## Prohibiciones

- **Sin `print`** (ni `debugPrint` para datos sensibles). Usar logging
  estructurado o propagar el error.
- Sin generadores de código (freezed, build_runner) por ahora.
- No inventar contratos del backend: endpoints, campos y códigos de error se
  dejan como `TODO` documentado hasta confirmarlos.

## Pruebas y calidad

- **Pruebas junto a cada módulo nuevo**: unitarias para `domain`/`core`, de
  widgets para `presentation`.
- `flutter analyze` y `flutter test` deben pasar sin errores ni warnings antes
  de cerrar una tarea.
- No dejar código comentado ni TODOs sin dueño: todo `TODO` explica qué falta y
  de qué documento/equipo depende.
