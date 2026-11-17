# SaveUp — Plan de rework de UI

> **Estado:** aprobado, sin fases iniciadas.
> **Fecha de apertura:** 2026-11-17.
> **Rama de trabajo:** `rework/ui` (nada de commits del rework en `main`).
> **Documento vivo.** Se actualiza al cerrar cada fase (§9 estado, §10 bitácora), no al final.
> Este plan manda sobre la ejecución; si algo no está aquí, no se hace sin anotarlo antes.

---

## 0. Cómo se trabaja con este documento

1. Cada sesión de trabajo empieza leyendo **§9 (estado)** y anunciando qué fase / lote se toca.
2. Cada lote termina con: gates corridos (§5), estado actualizado en §9 y una línea en §10.
3. Cambiar el plan es parte del plan: se propone, se anota en §10 con fecha y motivo, y se sigue.
4. Si aparece una decisión que el plan no cubre (navegación, contrato, lógica, dependencias nuevas),
   **se detiene y se consulta** — regla de oro del workspace.

### 0.1 Rama de trabajo

El rework **no se hace sobre `main`**. Todo el trabajo vive en una rama dedicada, y `main` solo
recibe cuando una unidad cierra con sus gates verdes.

| Aspecto | Regla |
|---|---|
| Rama de integración | **`rework/ui`**, creada desde `main` (`da195d0` al abrir el plan) |
| Ramas hijas | `rework/ui-ola-1`, `rework/ui-ola-2`… solo si el rework se alarga; nacen de `rework/ui` y vuelven a `rework/ui`, nunca a `main` |
| Granularidad | **Un lote = un commit** en la rama activa (Conventional Commits en español) |
| Primer commit | Este plan (`docs/Design_System/REWORK_UI_PLAN.md`), para que el plan exista antes del primer píxel |
| Prohibido | Commits del rework directos en `main`; force-push sobre ramas ya publicadas |
| Integración a `main` | Al cerrar F6, o antes si una ola lo amerita, por merge/PR que referencia este plan y resume qué se conservó, evolucionó y destruyó |
| Publicación | El push a `origin` se decide con el usuario; el plan **no asume** publicar cada lote |

Consecuencia práctica: los gates de §5 se corren en la rama activa, y el estado de §9 registra
también la rama y el commit de cada fase cerrada.

---

## 1. Decisiones firmadas (2026-11-17)

| Nº | Decisión | Efecto práctico |
|---|---|---|
| D-R1 | **Alcance completo**: rework de toda la interfaz, no solo pantallas clave | Las 10 features entran; se ejecuta por olas (§7) |
| D-R2 | Las **reglas del lenguaje visual actuales son la base**; se puede construir sobre ellas y **destruir lo que no sirva** | `DESIGN_SYSTEM_PLAN.md` se hereda y se enmienda; existe un procedimiento explícito de conservar / evolucionar / destruir (§2.3) |
| D-R3 | El neo-brutalismo **se queda**, pero se evoluciona si hace falta | La dirección visual puede cambiar en forma (radios, sombras, densidad, tipografía), no en identidad papel+tinta+acentos |
| D-R4 | Pantallas piloto: **movimientos, presupuesto, metas** + showcase como banco de pruebas | Es la ola 1; el resto espera a que el piloto cierre con gates verdes |

Entorno confirmado el 2026-11-17: Docker activo, emulador `emulator-5554` (Android 17 / API 37)
conectado, Flutter 3.47.8 estable en `C:\Users\hanom\Downloads\flutter`.
El backend se puede levantar en local para probar flujos reales (§4).

---

## 2. Base que se hereda

### 2.1 Contrato vigente

- `docs/Design_System/DESIGN_SYSTEM_PLAN.md` — contrato del design system (390 líneas):
  principios, paleta, tipografía, forma/profundidad, densidad, arquitectura modular,
  contrato de componentes, navegación, patrones financieros, accesibilidad, pruebas,
  migración y 8 decisiones aprobadas (2026-11-07).
- `docs/Design_System/neo_brutalism_guidelines.md` — reglas críticas del rediseño original
  (solo presentación, sombras `blurRadius: 0`, bordes 2, proteger `Key`s y textos).
- `docs/Design_System/References/` — 11 imágenes de referencia del lenguaje visual.
- `docs/CONTEXT.md` — decisiones de arquitectura D1–D14 de la app (D14 = tema Bold).

### 2.2 Lo ya construido (no se reinventa sin evidencia)

`lib/core/design_system/`: tokens (`app_colors`, `app_typography`, `app_spacing`, `app_radii`,
`app_borders`, `app_shadows`, `app_motion`, `app_density`), tema (`saveup_theme` con
**claro / oscuro / Bold**, `saveup_colors` y `saveup_shadows` como `ThemeExtension`),
27 componentes `neo_` (átomos, moléculas, navegación, patrones) y
`showcase/design_system_showcase_screen.dart`.
Goldens existentes: átomos, moléculas, navegación y tema Bold.

### 2.3 Procedimiento «conservar / evolucionar / destruir»

Tabla obligatoria de F0. Ningún token ni componente se toca antes de que las tres columnas
«veredicto», «evidencia» y «reemplazo» estén completas.

| Veredicto | Criterio | Acción |
|---|---|---|
| **Conservar** | Usado en ≥2 features, sin deuda detectada, cumple las reglas del §2.1 | Se queda tal cual; su API no cambia |
| **Evolucionar** | Concepto correcto, pero falla en forma/contraste/densidad/API | Se modifica; se documenta el cambio en el contrato y se actualizan sus tests y golden |
| **Destruir** | Duplicado, sin uso, contradice una regla (p. ej. sombra con blur) o no escala | Se elimina en el mismo lote que su reemplazo; nunca queda código muerto al cierre de fase |

«Alcance completo» incluye **destruir el contrato mismo** si una regla no sirve: en ese caso la
enmienda se escribe en `DESIGN_SYSTEM_PLAN.md` (§3 o §12) en el mismo commit, con la decisión
nueva fechada. El contrato nunca queda desactualizado respecto al código.

---

## 3. Invariantes (no negociables)

1. **Solo presentación.** Se toca `lib/core/design_system/`, `lib/app/theme.dart` y
   `features/*/presentation/`. Nunca `domain/`, `data/`, controladores, providers de Riverpod
   ni DTOs.
2. **Contrato del backend intacto.** `docs/contrato/*` es solo lectura; no se edita a mano.
3. **Keys y textos exactos.** Se preservan `Key(...)` y textos usados por widget tests. Si un
   cambio visual obliga a romper un test, el test se actualiza en el **mismo commit** y se anota
   en la bitácora.
4. **Tokens como única fuente.** Cero `Color(0x…)`, `TextStyle(...)`, `EdgeInsets...` o
   `BoxShadow(...)` sueltos en `features/**/presentation`. Excepción documentada: colores por
   categoría de charts, que viven en `features/analitica/presentation/widgets`.
5. **Los 3 temas son obligatorios.** Todo cambio visual se verifica en claro, oscuro y Bold.
   Un componente que solo funciona en claro está incompleto.
6. **Densidad por jerarquía** (`hero` / `section` / `list` / `table`), nunca por pantalla.
7. **Sin big-bang.** Un lote = un commit en el repo `frontend`, Conventional Commits en español.
8. **Gates en verde antes de cada commit** (§5). Un lote que rompe goldens sin revisión de los
   PNG no está terminado.
9. **Componente nuevo = showcase primero.** Ningún componente entra a una feature antes de
   estar en el showcase con sus estados, tests y, si es átomo, golden.
10. **Si el rework pide datos nuevos, se detiene.** Eso no es diseño: es contrato, y va por el
    protocolo de dos repos.
11. **Rama dedicada.** Todo commit del rework va en `rework/ui` (o en una hija declarada en §0.1).
    `main` queda intacto hasta el cierre; un cambio visual accidental en `main` es un fallo del
    proceso, no un incidente menor.

---

## 4. Entorno y comandos (verificados el 2026-11-17)

`flutter` **no está en el PATH** de este equipo; se invoca por ruta absoluta:

```powershell
$flutter = 'C:\Users\hanom\Downloads\flutter\bin\flutter.bat'
```

| Necesidad | Comando |
|---|---|
| Analizar | `& $flutter analyze` |
| Tests | `& $flutter test` |
| Tests de un directorio | `& $flutter test test/core/design_system` |
| Actualizar goldens | `& $flutter test test/core/design_system --update-goldens` |
| Correr en emulador | `& $flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1` |
| Dispositivos | `& $flutter devices` (emulador, Windows desktop, Chrome) |
| Base de datos local | `docker start saveup-pg` (existe, hoy detenido; también `saveup-theme-pg`) |
| Backend local | `.\mvnw.cmd spring-boot:run` en `backend\` → `http://localhost:8080/api/v1` |
| Humo backend | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-test.ps1` |

`API_BASE_URL` es obligatoria y no tiene default. El emulador Android usa `10.0.2.2`.
Windows desktop y Chrome pueden usarse para iterar rápido, pero el criterio visual de la app
es el emulador Android (y, cuando aplique, iOS).

---

## 5. Gates

Cada gate produce un resultado que se anota en §9. Ningún lote avanza con un gate rojo sin
justificación escrita en §10.

| Gate | Qué valida | Cómo |
|---|---|---|
| **G0 · Análisis** | 0 issues de linter | `& $flutter analyze` |
| **G1 · Suite** | Nada roto | `& $flutter test` (baseline de F0) |
| **G2 · Goldens** | Cambio visual intencional y revisado | `--update-goldens` + **revisar los PNG del diff** antes de aceptar |
| **G3 · App viva** | Se ve y se toca bien | `flutter run` en `emulator-5554` con backend local; recorrer las pantallas del lote en los 3 temas |
| **G4 · Backend** | Los flujos tienen datos reales | `docker start saveup-pg` + `mvnw spring-boot:run` + smoke test |
| **G5 · Anti-slop** | Checklist de craft y estados | skill `anti-ui-slop` + `node .agents/skills/anti-ui-slop/scripts/count-finish.mjs` (heurístico, no prueba visual) |

**Deuda visual** (se mide en F0 y al cierre de cada ola, es el termómetro del ¿avance?):

```powershell
cd frontend
Get-ChildItem lib\features -Recurse -Filter *.dart | Select-String 'Color\(0x'
Get-ChildItem lib\features -Recurse -Filter *.dart | Select-String 'TextStyle\('
Get-ChildItem lib\features -Recurse -Filter *.dart | Select-String 'EdgeInsets\.'
Get-ChildItem lib\features -Recurse -Filter *.dart | Select-String 'BoxShadow\('
```

La meta no es 0 por decreto: es que cada cifra baje respecto de la anterior, con excepción
justificada por archivo.

---

## 6. Fases

Regla de carga de skills: **una principal + una de apoyo** por fase. Cargar las cinco juntas
gasta contexto sin mejorar el resultado.

### F0 · Línea base e inventario

- **Objetivo:** saber exactamente dónde estamos antes de cambiar nada.
- **Skills:** `ui-design` (modo audit, secciones de `reference/audit.md` y `audit.native.md`).
- **Pasos:** medir gates G0/G1 y anotar el baseline; contar deuda visual (§5); capturar el
  estado actual de showcase + movimientos + presupuesto + metas en claro/oscuro/Bold;
  completar la tabla de §2.3 para **todos** los tokens y componentes.
- **Entregable:** §9 con baseline real, tabla de inventario completa, lista de lo que se
  propone destruir/evolucionar con su evidencia.
- **Gate de salida:** G0 y G1 verdes (o baseline rojo documentado como deuda previa).
- **No se hace:** ni una línea de diseño todavía.

### F1 · Dirección visual (evolución del lenguaje)

- **Objetivo:** decidir qué se conserva y qué evoluciona del neo-brutalismo, con evidencia.
- **Skills:** `ui-radar` (principal) + `ui-ux-pro-max` (apoyo: `--domain style`, `--domain typography`).
- **Pasos:** 3–5 referencias reales de fintech/ahorros (iOS y web) elegidas por trabajo de
  producto, no por estética; contraste con las 11 referencias propias de `References/`;
  decisión explícita sobre radios, sombras, densidad, tipografía y uso del color.
- **Entregable:** enmienda a `DESIGN_SYSTEM_PLAN.md` (§3 y nueva decisión fechada en §12) +
  `MASTER.md` generado con `--design-system --persist -p SaveUp` en esta misma carpeta.
- **Gate de salida:** el usuario aprueba la dirección. Sin aprobación no hay F2.
- **Riesgo:** deriva estética sin criterio. Mitigación: cada cambio de dirección debe resolver
  un problema listado en F0.

### F2 · Tokens y tema

- **Objetivo:** el lenguaje evolucionado vive en tokens, no en pantallas.
- **Skills:** `anti-ui-slop` (contrato de estados) + `make-interfaces-feel-better` (detalle: motion,
  radios concéntricos, tipografía).
- **Pasos:** tocar `app_*.dart` y `saveup_theme.dart` / `saveup_colors` / `saveup_shadows`;
  verificar `MediaQuery.disableAnimations` y text scaling 1.0/1.3/2.0; showcase como primera
  evidencia.
- **Entregable:** tokens y 3 temas actualizados; showcase nuevo; goldens del DS actualizados
  con revisión.
- **Gate de salida:** G0, G1, G2 (con PNG revisados) y G3 sobre el showcase en los 3 temas.

### F3 · Componentes

- **Objetivo:** rework o reemplazo de átomos, moléculas, navegación y patrones según el inventario.
- **Skills:** `ui-design` (`reference/craft.md`, `polish.md`) + `make-interfaces-feel-better`.
- **Pasos:** por componente: API, estados (default/pressed/disabled/loading/error), semántica,
  tests, golden si es átomo, y entrada al showcase. Destruir lo obsoleto en el mismo lote.
- **Entregable:** componentes al día + showcase completo + tests por estado.
- **Gate de salida:** G0, G1, G2, G3 (showcase) y G5 sobre componentes.

### F4 · Ola 1 — piloto (movimientos, presupuesto, metas)

- **Objetivo:** validar el lenguaje en pantallas reales y densas antes de propagarlo.
- **Skills:** `ui-design` (principal) + `make-interfaces-feel-better` (detalle).
- **Orden:** movimientos → presupuesto → metas. Cada pantalla en su propio lote.
- **Por pantalla:** estados vacío/carga/error con datos reales del backend local; los 3 temas;
  text scaling; teclado y targets ≥ 48 dp; `NeoMoneyText` con signo además de color.
- **Gate de salida por pantalla:** G0, G1, G3 (emulador con backend) y G5.
- **Gate de salida de la ola:** revisión conjunta con el usuario. Si el lenguaje no convence,
  se corrige aquí y no se propaga.

### F5 · Olas siguientes (resto de la app)

- **Objetivo:** propagar el lenguaje aprobado a todas las features.
- **Olas sugeridas:** (2) auth + home + cuenta; (3) deudas + reportes; (4) analítica +
  aparición de app/versión. Orden ajustable en §7 con justificación.
- **Skills:** `ui-design` + `make-interfaces-feel-better` (apoyo puntual).
- **Gate de salida por lote:** los mismos gates de F4.

### F6 · Cierre

- **Objetivo:** que el rework sea verificable, no una impresión.
- **Skills:** `anti-ui-slop` (gate final) + `ui-design` (`reference/audit.md`).
- **Pasos:** auditoría de accesibilidad completa (contraste, semántica, reduce motion, text
  scaling 2.0), recorrido entero de la app en 3 temas, deuda visual a mínimos justificados,
  capturas antes/después, suite completa y goldens en verde.
- **Entregable:** informe de cierre en §10 + commit final en `frontend` referenciando este plan.
- **Gate de salida:** G0, G1, G2, G5 y recorrido manual completo (G3).

---

## 7. Olas y estado por pantalla

| Ola | Pantallas / features | Estado |
|---|---|---|
| 1 (piloto) | movimientos, presupuesto, metas, showcase | pendiente |
| 2 | auth, home, cuenta | pendiente |
| 3 | deudas, reportes | pendiente |
| 4 | analítica, apariencia/tema, app/versión | pendiente |
| — | navegación global (`NeoScaffold`, `NeoBottomNav`, `NeoMoreMenu`) | se toca en F2/F3 |

Estados posibles: `pendiente` → `en curso` → `gate verde` → `cerrada`.

---

## 8. Definición de hecho (por lote)

Un lote está hecho cuando:

1. Solo se tocó presentación (§3.1) y no hay lógica nueva.
2. Todo valor visual sale de tokens o de un componente del design system.
3. Funciona en claro, oscuro y Bold.
4. Estados vacío / carga / error cubiertos con datos reales del backend local.
5. Text scaling 1.0 y 2.0 sin overflow; targets ≥ 48 dp; contraste 4.5:1 cuerpo / 3:1 grande.
6. G0 y G1 verdes; G2 con PNG revisados si cambió algo visual.
7. Componente nuevo o modificado: en el showcase, con tests de sus estados.
8. §9 y §10 actualizados, y un commit en `frontend` **sobre la rama `rework/ui`** que cuenta qué
   se conservó, qué se evolucionó y qué se destruyó.

---

## 9. Registro de progreso

| Fase | Estado | Baseline / resultado | Fecha |
|---|---|---|---|
| F0 · Línea base e inventario | pendiente | — | — |
| F1 · Dirección visual | pendiente | — | — |
| F2 · Tokens y tema | pendiente | — | — |
| F3 · Componentes | pendiente | — | — |
| F4 · Piloto (3 pantallas) | pendiente | — | — |
| F5 · Olas siguientes | pendiente | — | — |
| F6 · Cierre | pendiente | — | — |

**Baseline de deuda visual** (se llena en F0):

| Métrica | Valor | Fecha |
|---|---|---|
| `Color(0x` en `features/**/presentation` | — | — |
| `TextStyle(` en `lib/features` | — | — |
| `EdgeInsets.` en `lib/features` | — | — |
| `BoxShadow(` en `lib/features` | — | — |
| `flutter analyze` (issues) | — | — |
| `flutter test` (passed) | — | — |

---

## 10. Bitácora (append-only)

| Fecha | Fase / lote | Qué pasó | Decisión o desvío |
|---|---|---|---|
| 2026-11-17 | — | Plan abierto y aprobado. Fases sin iniciar. | D-R1–D-R4 firmadas en §1 |
| 2026-11-17 | — | Rama de trabajo definida: `rework/ui` desde `main`; prohibido commitear el rework en `main`. | §0.1 y invariante §3.11 |

---

## 11. Riesgos

| Riesgo | Mitigación |
|---|---|
| El rework se convierte en reescritura del design system sin control | §2.3 obliga a evidencia por veredicto; F1 requiere aprobación explícita |
| Deriva estética sin objetivo | Cada cambio debe resolver un problema de F0 o de F1 |
| Romper tests por textos/Keys | Invariante §3.3; test actualizado en el mismo commit |
| Goldens actualizados "a ciegas" | G2 exige revisar los PNG del diff, no solo regenerarlos |
| Quedarme sin verificación visual | `flutter run` en `emulator-5554` con backend local; capturas en la bitácora |
| Las skills web/iOS empujan patrones ajenos a Flutter | El "cómo" sale del stack `flutter` de `ui-ux-pro-max` y de las reglas del repo; las referencias informan, no se copian |
| Deuda de migración acumulada | Olas cerradas con `gate verde`; nada de features a medio migrar al cerrar una fase |
| Contexto inflado por cargar 5 skills | Regla de carga: una principal + una de apoyo por fase (§6) |

---

## 12. Lo que este plan no hace

- No cambia contratos, endpoints, DTOs, fórmulas ni lógica de negocio.
- No reescribe la arquitectura feature-first ni el esquema de Riverpod.
- No introduce dependencias nuevas de UI sin decisión anotada (p. ej. otro paquete de charts).
- No promete que la app se vea igual en iOS: iOS se verifica cuando haya target disponible;
  el criterio primario es Android (emulador) + los 3 temas.
