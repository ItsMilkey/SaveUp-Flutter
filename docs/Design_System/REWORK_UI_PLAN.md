# SaveUp — Plan de rework de UI

> **Estado:** en ejecución — F0 (línea base e inventario) en curso; capturas pendientes.
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

### 2.4 Inventario de línea base (medido 2026-11-17)

**Tokens** — los 8 archivos de `lib/core/design_system/tokens/`

| Token | Evidencia leída | Veredicto |
|---|---|---|
| `app_colors` | 11 colores claros + 5 oscuros, idénticos a la paleta aprobada (§3.1 del contrato) | Conservar |
| `app_typography` | Archivo Black + Space Grotesk con `FontVariation('wght')`; `textTheme()` de 15 estilos | Conservar |
| `app_radii` | `none/sm/md/lg/xl/pill` + aliases `*All` | Conservar |
| `app_spacing` | Escala 4–48 en múltiplos de 4 | Conservar |
| `app_borders` | 1.5 / 2 / 3 | Conservar |
| `app_density` | 4 niveles con padding + borde + sombra (§3.4) | Conservar |
| `app_shadows` | Solo `enum AppShadowLevel`; offsets y color viven en `SaveUpShadows` | **Evolucionar**: la intención y el valor están partidos en dos archivos |
| `app_motion` | 120/200/300 ms + `easeOutCubic` | **Evolucionar**: no hay helper que respete `MediaQuery.disableAnimations` |

**Componentes** — usos = menciones en `lib/features`; tests = menciones en `test/`

| Componente | Usos | Tests | Veredicto |
|---|---|---|---|
| `NeoButton` | 62 | 19 | Conservar |
| `NeoInput` | 52 | 4 | Conservar |
| `NeoSurface` | 49 | 2 | Conservar |
| `NeoErrorBand` | 31 | 2 | Conservar |
| `NeoIconButton` | 25 | **0** | Evolucionar: sin un solo test |
| `NeoScaffold` | 24 | 2 | Conservar |
| `NeoSectionHeader` | 22 | 3 | Conservar |
| `NeoAppBar` | 20 | 3 | Conservar |
| `NeoSnackbar` | 19 | 2 | Conservar |
| `NeoBadge` | 14 | 13 | Conservar |
| `NeoErrorState` | 13 | 1 | Conservar |
| `NeoDialog` | 13 | 6 | Conservar |
| `NeoMoreOption` | 12 | 3 | Conservar |
| `NeoLoading` | 12 | 2 | Conservar |
| `NeoMoneyText` | 9 | 5 | Conservar |
| `NeoBottomDestination` | 7 | 15 | Conservar |
| `NeoProgress` | 7 | 5 | Evolucionar: revisar densidad y semántica del valor |
| `NeoChartCard` | 4 | 3 | Evolucionar: **sin golden**, y el contrato (§9) lo promete |
| `NeoStat` | 4 | 5 | Conservar |
| `NeoEmptyState` | 3 | 1 | Conservar |
| `NeoListItem` | 3 | 5 | Conservar |
| `NeoCard` | 1 | 8 | Evolucionar: solapa con `NeoSurface`; decidir su rol o absorberlo |
| `NeoSliverAppBar` | 1 | **0** | Evolucionar: un solo uso y ningún test |
| `NeoMonthPicker` | **0** | 2 | **Evolucionar o destruir**: el contrato §7 lo exige para plan/presupuesto/analítica y ninguna feature lo usa |
| `NeoSegmented` | **0** | **0** | **Destruir**: ni usos ni tests; si el rework lo necesita, se reconstruye con contrato |

**Deuda visual medida**

| Métrica | Valor | Lectura |
|---|---|---|
| `Color(0x` en `features/**/presentation` | 2 | Ambos son `0xFF000000 \| value` de mapeo de color de charts (excepción documentada) → **0 violaciones reales** |
| `TextStyle(` en features | 5 | 4 fijan peso o tamaño sin pasar por `AppTypography` |
| `fontSize:` en features | 4 (2 archivos) | Tamaño 12 literal en diálogos |
| `EdgeInsets.` en features | 120 (32 archivos) | 84 con token, 15 literales, el resto en líneas partidas |
| `BorderRadius` en features | 27 (14 archivos) | 23 con `AppRadii` |
| `BoxShadow(` en features | **0** | Correcto: toda sombra viene del tema |

### 2.5 Hallazgos visuales de F0 (capturas del 2026-11-17)

Capturas en `C:\Users\hanom\Documents\saveup\.f0-captures\` (local, fuera de los repos):
login, inicio, presupuesto, metas y showcase en **claro, oscuro y Bold**, más la pantalla Tema.

| # | Hallazgo | Evidencia | Tipo |
|---|---|---|---|
| H1 | **Oscuro: título de tarjeta casi invisible.** "Sugerencia" queda en tinta oscura sobre superficie oscura | `dark_presupuesto.png` | Contraste / bug |
| H2 | **Oscuro: texto blanco sobre acentos claros.** En metas, "Notebook nueva" (lavanda) y "Viaje a Japón" (cian) usan texto claro; el contrato §3.1 dice que sobre acentos va **tinta, nunca blanco** | `dark_metas.png` vs `light_metas.png` | Contraste / viola contrato |
| H3 | **El selector del showcase es preview local.** Arranca en "Claro" aunque la app esté en Bold y no cambia la preferencia; el cambio real vive en Más → Tema | `bold_showcase.png`, `dark_showcase.png`, `tema.png` | UX / confusión |
| H4 | **Saldo negativo con datos normales.** Tras abonar a metas el inicio muestra −$1.731.970 y un badge rojo "Saldo negativo": los abonos entran como movimientos negativos y la pantalla no lo explica | `f0_after_login.png` | Contenido / comprensión |
| H5 | **Pluralización cruda**: "13 movimiento(s)" | `f0_after_login.png` | Copy |
| H6 | **Formato de porcentaje inconsistente**: "43.75 %" y "93.33 %" con punto, cuando el resto de la app usa coma decimal | `light_metas.png` | Formato es-CL |
| H7 | **Los FAB flotan sobre el contenido**: en Inicio tapan una fila de la lista | `f0_after_login.png` | Layout |

Estos hallazgos no se arreglan en F0: entran como criterio de F1 (dirección) y F2/F3 (tokens y
componentes). H1, H2 y H7 son de contraste/layout y deben resolverse en el sistema, no pantalla
por pantalla.

**Resueltos antes de F1 (2026-11-17)** — con enmienda al contrato, no parche local:

| # | Cómo se resolvió | Archivos |
|---|---|---|
| H1 | `NeoSurface` ya no fija `AppColors.ink`: deduce el foreground por contraste, así `surfaceAccent` oscuro usa texto claro | `neo_surface.dart` |
| H2 | Token `SaveUpColors.onAccentSurface` (= tinta en los 3 temas) y uso en superficies de acento; `colors.ink` queda prohibido como foreground de un acento | `saveup_colors.dart`, `metas_screen.dart`, `ejecucion_presupuesto_screen.dart` |
| H3 | El showcase ya no tiene selector propio: renderiza con el tema activo y remite a Más → Tema, único dueño de la preferencia | `design_system_showcase_screen.dart` |

Ambas reglas quedaron escritas en `DESIGN_SYSTEM_PLAN.md` (§3.1 regla **R-1** y §4) para que no
se reintroduzcan, y cubiertas por tests en `design_system_test.dart`.

**Promesas del contrato que el código no cumple** (se resuelven en F1/F3, no aquí)

1. Goldens de `NeoChartCard` (§9 del contrato) → no existen.
2. `NeoMonthPicker` (§7) → obligatorio según el contrato, cero usos reales.
3. `NeoIconButton` y `NeoSliverAppBar` → sin tests pese a estar en producción.

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

**Goldens:** los generados el 2026-11-17 pertenecen a **Windows 10 + Flutter 3.47.8**. Son
dependientes del entorno de renderizado, no solo del SDK: no se regeneran sin revisar el diff y
ver §13 (deuda E: llevarlos a contenedor en el cierre).

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
| F0 · Línea base e inventario | **cerrada** | G0 ✅ 0 issues · G1 ✅ 534/534 · deuda visual e inventario medidos (§2.4) · capturas de las 4 pantallas en los 3 temas (§2.5) · 7 hallazgos registrados | 2026-11-17 |
| F1 · Dirección visual | pendiente | — | — |
| F2 · Tokens y tema | pendiente | — | — |
| F3 · Componentes | pendiente | — | — |
| F4 · Piloto (3 pantallas) | pendiente | — | — |
| F5 · Olas siguientes | pendiente | — | — |
| F6 · Cierre | pendiente | — | — |

**Baseline de deuda visual** (medido en F0):

| Métrica | Valor | Fecha |
|---|---|---|
| `Color(0x` en `features/**/presentation` | 2 (excepción de charts) | 2026-11-17 |
| `TextStyle(` en `lib/features` | 5 | 2026-11-17 |
| `fontSize:` en `lib/features` | 4 | 2026-11-17 |
| `EdgeInsets.` en `lib/features` | 120 (84 con token, 15 literales) | 2026-11-17 |
| `BorderRadius` en `lib/features` | 27 (23 con token) | 2026-11-17 |
| `BoxShadow(` en `lib/features` | 0 | 2026-11-17 |
| `flutter analyze` (issues) | 0 | 2026-11-17 |
| `flutter test` (passed / failed) | 534 / 0 (tras regenerar goldens) | 2026-11-17 |

---

## 10. Bitácora (append-only)

| Fecha | Fase / lote | Qué pasó | Decisión o desvío |
|---|---|---|---|
| 2026-11-17 | — | Plan abierto y aprobado. Fases sin iniciar. | D-R1–D-R4 firmadas en §1 |
| 2026-11-17 | — | Rama de trabajo definida: `rework/ui` desde `main`; prohibido commitear el rework en `main`. | §0.1 y invariante §3.11 |
| 2026-11-17 | F0 | Rama `rework/ui` creada; plan commiteado (`f574abd`). | — |
| 2026-11-17 | F0 | G0 verde: `flutter analyze` sin issues (11,5 s). | — |
| 2026-11-17 | F0 | G1 **rojo heredado**: 532 ✓ / 2 ✗. Fallan los goldens de átomos y moléculas; diff 3,9 % **solo de glifos**. Causa: se regeneraron con Flutter 3.47.9 (`819ee09`) y aquí corre 3.47.8. No lo causó el rework. | Decisión pendiente en §13 |
| 2026-11-17 | F0 | Inventario completo: 8 tokens, 27 componentes con veredicto, deuda visual medida (§2.4). | `NeoSegmented` sin usos ni tests; `NeoMonthPicker` lo exige el contrato y no se usa; `NeoChartCard` sin golden |
| 2026-11-17 | F0 | Detectado: `flutter` no está en PATH; se usa `C:\Users\hanom\Downloads\flutter\bin\flutter.bat`. Emulador `emulator-5554` (API 37) disponible. | Reflejado en §4 |
| 2026-11-17 | F0 | D-P1: se intentó **B** (SDK 3.47.9) en un worktree aparte, sin tocar el SDK global. Resultado: **mismo diff exacto** que con 3.47.8. B queda descartada con evidencia. | §13, hecho 1 |
| 2026-11-17 | F0 | Prueba: regenerar los goldens en esta máquina deja el DS en 40/40 verde. Artefactos **restaurados** (`git checkout`) para no commitear cambios sin aprobación. | §13, hecho 4 |
| 2026-11-17 | F0 | Decisión **A** aplicada: 4 goldens regenerados con 3.47.8, revisados visualmente (solo cambia el rasterizado). DS 40/40 y suite **534/534**. | D-P1 resuelta |
| 2026-11-17 | F0 | SDK global quedó sin `engine-dart-sdk.stamp` por el intento de B; se recreó con el contenido de `engine.stamp` y volvió a funcionar. Worktree 3.47.9 eliminado (0,9 GB). | §13, limpieza |
| 2026-11-17 | F0 | Backend local arriba (Postgres en 5433, `saveup-pg`) y app en `emulator-5554`. Seed con datos reales: 11 movimientos, 3 límites, 3 metas con progreso distinto. | `scripts\seed-ui-demo.ps1` (workspace) |
| 2026-11-17 | F0 | Capturas de login, inicio, presupuesto, metas y showcase en claro/oscuro/Bold. | §2.5, evidencia en `.f0-captures\` |
| 2026-11-17 | F0 | 7 hallazgos visuales: contraste en oscuro (H1, H2), selector de tema del showcase engañoso (H3), saldo negativo sin explicación (H4), "13 movimiento(s)" (H5), porcentajes con punto (H6), FAB sobre contenido (H7). | §2.5; alimentan F1–F3 |
| 2026-11-17 | F0 | **F0 cerrada.** Tema de la app restaurado a Sistema. | Siguiente: F1 (dirección), requiere aprobación |
| 2026-11-17 | Pre-F1 | **H1 y H2 resueltos con enmienda al contrato** (§3.1 regla R-1): `NeoSurface` deduce foreground por contraste; `SaveUpColors.onAccentSurface` = tinta en los 3 temas; `colors.ink` prohibido sobre acentos. Verificado en emulador: "Sugerencia" legible en oscuro y metas con tinta sobre acento. | `neo_surface.dart`, `saveup_colors.dart`, `metas_screen.dart`, `ejecucion_presupuesto_screen.dart` |
| 2026-11-17 | Pre-F1 | **H3 resuelto**: el showcase ya no tiene selector de tema propio; renderiza con el tema activo y remite a Más → Tema. | `design_system_showcase_screen.dart` |
| 2026-11-17 | Pre-F1 | Gates: analyze 0 issues, **536/536** tests (2 nuevos de R-1), goldens sin regenerar. | D-P1 sigue válida |

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

---

## 13. Decisiones resueltas

### D-P1 · Estrategia de goldens — **resuelta con A** (2026-11-17)

Los goldens de átomos y moléculas están rojos **antes** de que el rework toque nada.

**Hechos medidos (2026-11-17):**

1. Con Flutter **3.47.8** y con **3.47.9** el resultado es **idéntico**: 3,93 % y 5970 px de
   diferencia en claro, 3,92 % y 5962 px en oscuro. Los mismos píxeles. **El patch del SDK no
   es la variable.**
2. Las fuentes bundleadas no cambiaron desde `9806456` (2026-11-07), el mismo commit que creó
   tokens, tema y goldens.
3. El diff es **exclusivamente de glifos**: ni una diferencia de geometría, color o tamaño.
4. Regenerando en esta máquina, el directorio del design system queda **40/40 en verde**
   (experimento revertido a propósito: los artefactos siguen intactos).

**Conclusión:** los goldens están atados al **entorno de renderizado** (SO / motor tipográfico),
no al código ni a la versión del SDK. Generados en otra máquina, no van a cuadrar aquí nunca.
Eso hace que G2 sea frágil por diseño: cualquier compañero en otro SO verá el mismo rojo.

| Opción | Qué implica | Coste |
|---|---|---|
| **A · Regenerar aquí** (recomendada para desbloquear) | `--update-goldens` sobre los 4 PNG, dejando constancia de SO + SDK dueños en este documento | 4 PNG + nota; otro SO volverá a ver rojo |
| **E · Goldens en contenedor** (durable, para F6) | Generar y comparar goldens dentro de una imagen Linux fija; Docker ya está disponible | Script + imagen; no bloquea el rework |
| B · Alinear SDK a 3.47.9 | **Descartada con evidencia** (hecho 1) | — |
| C · Comparador con tolerancia | Cubrir 3,9 % obliga a aflojar tanto que el gate deja de detectar cambios reales | Descartada |

**Resolución (A, aplicada el 2026-11-17):** se regeneraron los 4 PNG y se revisó la imagen
resultante: borde 2, sombra dura sin blur, radio pill y tipografía Archivo Black / Space Grotesk
intactos; sin desplazamientos ni corrupción, solo difiere el rasterizado. Suite completa en
**534/534**. Dueños del golden: **Windows 10 + Flutter 3.47.8 (Dart 3.13.7)**.

**Deuda derivada para F6 (opción E):** si alguien trabaja en otro SO, los goldens volverán a
discrepar. En el cierre, el gate de goldens debería correr en contenedor para no depender de la
máquina de turno.

**Limpieza hecha:** el worktree `flutter-3.47.9` (0,9 GB) se eliminó; el SDK global quedó en
3.47.8. Durante la comprobación de B su caché se quedó sin `engine-dart-sdk.stamp`; se recreó con
el contenido de `engine.stamp` (lo mismo que escribe `update_dart_sdk.ps1` al instalar) y el SDK
volvió a funcionar.
