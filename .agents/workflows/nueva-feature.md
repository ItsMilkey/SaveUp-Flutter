# Workflow: implementar una nueva feature

Paso a paso para tomar una tarea del backlog y dejarla cerrada.

## 1. Entender el contexto

1. Leer `docs/CONTEXT.md` completo (arquitectura, dinero, fechas, errores,
   autenticación).
2. Leer la tarea correspondiente en `docs/tareas/` (objetivo, alcance,
   criterios de aceptación, pruebas) y el documento del backend
   `docs/CLIENTE_FLUTTER.md` si la tarea toca la API.
3. Si algo del contrato no está documentado, **detenerse y preguntar**; no
   inventar endpoints, campos ni códigos de error. Registrar la duda como `TODO`
   en `docs/CONTEXT.md` si queda pendiente.

## 2. Planificar

1. Identificar la feature afectada (`lib/features/<feature>`) y sus capas.
2. Listar los archivos a crear/modificar, incluyendo pruebas.
3. Definir el estado en Riverpod (providers/notifiers) antes de escribir UI.
4. Declarar supuestos explícitamente en el plan.

## 3. Implementar

1. `domain` primero: entidades, contratos de repositorio, casos de uso.
2. `data` después: DTOs, mapeo (montos con `Money.parse`, fechas vía
   `lib/core/time`), implementación del repositorio con Dio.
3. `presentation` al final: widgets + providers. Sin lógica de negocio en
   widgets.
4. Dinero siempre con `Decimal`; jamás `double`.
5. Escribir las pruebas junto al código, no al final.

## 4. Verificar

```sh
flutter analyze
flutter test
```

- Corregir hasta que no haya errores ni warnings.
- Si se tocó configuración nativa, correr además un build de debug del
  dispositivo/emulador disponible (no es obligatorio para tareas solo Dart).

## 5. Cerrar

1. Actualizar `docs/tareas/` (estado de la tarea) y, si cambió una decisión
   técnica, `docs/CONTEXT.md`.
2. Resumir en la respuesta: cambios hechos, archivos clave, resultados de
   `analyze`/`test` y **pendientes/TODOs** abiertos.
3. Commit en español con Conventional Commits, p. ej.
   `feat(movimientos): listar movimientos del mes`.
