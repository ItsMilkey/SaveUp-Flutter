# Tareas

Backlog de la app móvil. Cada tarea es un archivo Markdown en esta carpeta con
el siguiente formato.

## Formato

```markdown
# <ID> — <Título corto>

## Objetivo
Qué problema resuelve y para quién, en 2-3 líneas.

## Alcance
Qué entra y qué NO entra (para evitar scope creep).

## Criterios de aceptación
- [ ] Criterio verificable 1
- [ ] Criterio verificable 2

## Pruebas
- [ ] Prueba unitaria de ...
- [ ] Prueba de widget de ...

## Dependencias / notas
Endpoints del backend, tareas previas, decisiones pendientes (TODOs).
```

Reglas:

- Una tarea = un PR conceptual.
- Los criterios de aceptación deben ser verificables (no "que se vea bien").
- Toda dependencia del backend se referencia a `docs/CLIENTE_FLUTTER.md`; no se
  inventan contratos.
- Al cerrar una tarea, actualizar su estado en la lista de abajo.

## Estado de bloques

| Bloque | Descripción | Estado |
| --- | --- | --- |
| F0 | _Por completar_ | Pendiente |
| F1 | _Por completar_ | Pendiente |

> Todo: completar la definición de F0 y F1 con el equipo de producto.
