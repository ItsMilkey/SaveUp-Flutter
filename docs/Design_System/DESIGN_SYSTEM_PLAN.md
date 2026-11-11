# SaveUp — Plan de Design System Neo-Brutalista (propuesta refinada)

> **Estado:** implementado. Este documento se conserva como contrato del design
> system: tokens, componentes y fases ejecutadas. Las fases 0–8 están cerradas y el
> pulido posterior se registra en «Migración incremental».
>
> Base actual: F1–F8, F10 y F11 cerradas; el rediseño se hizo solo en
> `presentation/`, sin tocar dominio, data, controladores ni contratos.

## 1. Qué conservar del borrador y qué falta

**Se conserva**
- Dirección neo-brutalista: bordes gruesos, sombras duras (`blurRadius: 0`),
  alto contraste, tipografía pesada y acentos vibrantes.
- Regla de oro: **solo presentación**; no se tocan controladores, repositorios,
  DTOs, Riverpod ni contratos.
- Proteger `Key`s y textos exactos usados por widget tests; si un cambio visual
  obliga a romper un test, se avisa y se actualiza el test en el mismo PR.
- Ejecución por pasos con confirmación.

**Falta para que sea un plan de design system y no una lista de pasos**
- Tokens (color, tipografía, espaciado, radios, bordes, sombras, motion).
- Modo oscuro y accesibilidad (contraste, text scaling, semántica, color + signo).
- Inventario de componentes con estados y API.
- Navegación (la AppBar actual ya tiene 6 iconos y no escala).
- Patrones de datos: dinero, fechas, sliders, gráficos, estados vacío/error/loading.
- Ubicación modular (`lib/core/design_system/`, no mezclar atoms con features).
- Estrategia de migración incremental y criterios de aceptación.
- Gobernanza: nombres, tokens obligatorios, review checklist, pruebas visuales.

**Ambigüedades a resolver**
- El borrador dice `lib/core/theme/` y `lib/core/presentation/widgets/`; hoy el
  tema vive en `lib/app/theme.dart`. Propuesta: el design system vive en
  `lib/core/design_system/` y `lib/app/theme.dart` solo compone `SaveUpTheme`.
- Material 3 usa `FilledButton`/`TextButton`, no `ElevatedButton` como primario.
  El theme debe cubrir `FilledButtonTheme`, `OutlinedButtonTheme`,
  `TextButtonTheme`, `InputDecorationTheme`, `CardTheme`, `DialogTheme`,
  `SnackBarTheme`, `ChipTheme`, `NavigationBarTheme`, `SegmentedButtonTheme`.
- `NeoBadge` sirve para estados (BAJO/CERCA/SOBRE, PENDIENTE/PAGADA) y para
  categorías; conviene separar `NeoBadge` (genérico) de `NeoStatusBadge`
  (semántico por color/icono) en el feature o en patterns.
- No empezar por el theme sin aprobar paleta, fuentes, modo oscuro y navegación.

## 2. Principios de diseño

1. **Claridad financiera primero.** El estilo puede ser audaz, pero el saldo, los
   montos, las fechas y los estados deben leerse en <2 s. El color no es la única
   señal: siempre hay signo, etiqueta o icono.
2. **Contraste y jerarquía.** Tinta oscura sobre papel claro; acentos para
   acciones y datos, no para párrafos largos.
3. **Modularidad real.** `tokens → theme → atoms → molecules → patterns →
   pantallas`. Las features solo importan el barrel del design system; el design
   system no conoce ninguna feature.
4. **Una sola fuente de verdad.** Ningún `Color(0x…)`, `TextStyle`, `EdgeInsets`
   o `BoxShadow` suelto en features: todo sale de tokens/theme o de un componente.
5. **Incremental y reversible.** Migración pantalla por pantalla con wrappers;
   sin big-bang, sin congelar features.

## 3. Dirección visual

### 3.1 Paleta aprobada

Base “papel + tinta” con acentos vibrantes; el texto sobre acentos es **tinta**,
nunca blanco (mejor contraste en amarillo/cian/verde). Se mantiene el color, sin
sobriedad en esta etapa.

| Token | Hex | Uso |
|---|---|---|
| `ink` | `#111111` | texto, bordes, sombras |
| `paper` | `#FFFDF7` | superficie de tarjetas/inputs |
| `canvas` | `#F7F1E3` | fondo de pantalla |
| `yellow` | `#FFD43B` | acción primaria / marca |
| `cyan` | `#57D9E8` | secundario / info |
| `magenta` | `#F45B9A` | acento / deseos |
| `orange` | `#FF8A3D` | alerta / gasto variable |
| `green` | `#3DDC97` | éxito / ahorro |
| `lavender` | `#B79CFF` | acento suave / metas |
| `danger` | `#E5484D` | error/destructivo (texto tinta) |
| `muted` | `#6B6B6B` | texto secundario |
| `line` | `#111111` | bordes (mismo que ink) |

- **Semántica:** `success`, `warning`, `danger`, `info` se mapean a `ColorScheme`
  y a un `ThemeExtension`; no se reutilizan acentos de marca para errores.
- **Contraste:** validar 4.5:1 para cuerpo y 3:1 para texto grande/UI. El
  amarillo/cian/verde llevan texto tinta. El rojo `danger` con tinta también.
- **Modo oscuro:** fondo `#0E0E0E`, superficie `#1A1A1A`, tarjeta `#232323`,
  texto `#F7F1E3`, bordes crema; las sombras duras pasan a un tono claro/acento
  con opacidad controlada. Validar contraste; no invertir los acentos.
- **Patrón de puntos:** `CustomPainter` solo en auth/home hero, nunca detrás de
  formularios o listas densas.

### 3.2 Tipografía

- **Display:** `Archivo Black` (títulos gigantes, saldo, cifras).
- **Texto/UI:** `Space Grotesk` (400/500/600/700) para títulos, cuerpo y labels.
- **Números:** `FontFeature.tabularFigures()` en tablas/saldos.
- **Escala:** display 32/40, headline 24/28, title 18/24, body 14/20, label 12/14
  (uppercase, tracking 0.5).
- **Licencia:** ambas son SIL OFL; **se bundlean** `.ttf` en `assets/fonts/` (no
  `google_fonts` en runtime). Space Grotesk se usa como fuente variable con
  `FontVariation('wght', …)`.
- **Text scaling:** probar 1.0/1.3/2.0; los componentes no deben fijar alturas
  rígidas que recorten texto.

### 3.3 Forma y profundidad

| Token | Valor |
|---|---|
| `radius.sm` | 8 |
| `radius.md` | 12 (tarjetas/inputs) |
| `radius.lg` | 16 (hero) |
| `radius.pill` | 999 (chips/botones/nav) |
| `border.sm` | 1.5 (listas densas) |
| `border.md` | 2 (tarjetas/inputs/botones) |
| `border.lg` | 3 (hero/diálogos) |
| `shadow.sm` | `Offset(2,2)`, blur 0 |
| `shadow.md` | `Offset(4,4)`, blur 0 |
| `shadow.lg` | `Offset(6,6)`, blur 0 |
| `space` | 4, 8, 12, 16, 24, 32, 48 |

- Interacción: al presionar, el componente se desplaza `(2,2)` y reduce la
  sombra; no hay “escala” ni bounce.
- Motion: 120 ms press, 200 ms fades, 300 ms páginas; `easeOutCubic`; respetar
  `MediaQuery.disableAnimations`.
- Iconos: Material outlined, 20/24 px, tinta; no mezclar estilos.

### 3.4 Densidad variable (aprobada)

“Si todo es denso, nada lo es”: la densidad se elige por jerarquía, no por
pantalla.

| Nivel | Uso | Padding | Borde | Sombra |
|---|---|---|---|---|
| `hero` | saldo, auth, empty state, resumen | 24–32 | 3 | `lg` |
| `section` | formularios, detalle, tarjetas | 16–24 | 2 | `md` |
| `list` | movimientos, deudas, metas | 12–16 | 1.5 | `sm` |
| `table` | leyendas de charts, filas densas | 8–12 | 1 | ninguna |

Los componentes reciben `density` (default `section`); las listas usan `list` y
los resúmenes `hero`. No se mezcla `hero` dentro de una lista ni `table` en un
formulario.

## 4. Arquitectura modular

```
lib/core/design_system/
├── design_system.dart          # barrel público
├── tokens/
│   ├── app_colors.dart
│   ├── app_typography.dart
│   ├── app_spacing.dart
│   ├── app_radii.dart
│   ├── app_borders.dart
│   ├── app_shadows.dart
│   └── app_motion.dart
├── theme/
│   ├── saveup_theme.dart       # light/dark + ThemeData
│   ├── saveup_colors.dart      # ThemeExtension
│   └── saveup_shadows.dart     # ThemeExtension
├── components/
│   ├── atoms/
│   │   ├── neo_surface.dart
│   │   ├── neo_card.dart
│   │   ├── neo_button.dart
│   │   ├── neo_icon_button.dart
│   │   ├── neo_input.dart
│   │   ├── neo_badge.dart
│   │   ├── neo_chip.dart
│   │   ├── neo_avatar.dart
│   │   ├── neo_divider.dart
│   │   ├── neo_progress.dart
│   │   ├── neo_segmented.dart
│   │   ├── neo_switch.dart
│   │   ├── neo_checkbox.dart
│   │   └── neo_radio.dart
│   ├── molecules/
│   │   ├── neo_list_item.dart
│   │   ├── neo_stat.dart
│   │   ├── neo_money_text.dart
│   │   ├── neo_section_header.dart
│   │   ├── neo_empty_state.dart
│   │   ├── neo_error_state.dart
│   │   ├── neo_loading.dart
│   │   ├── neo_dialog.dart
│   │   ├── neo_confirm_dialog.dart
│   │   └── neo_snackbar.dart
│   └── navigation/
│       ├── neo_scaffold.dart
│       ├── neo_app_bar.dart
│       ├── neo_bottom_nav.dart
│       └── neo_more_menu.dart
├── patterns/
│   ├── neo_form_field.dart
│   ├── neo_money_field.dart
│   ├── neo_date_field.dart
│   ├── neo_month_picker.dart
│   ├── neo_filter_bar.dart
│   ├── neo_chart_card.dart
│   └── neo_destructive_action.dart
└── showcase/
    └── design_system_showcase_screen.dart  # solo debug
```

Reglas:
- `design_system` **no importa** `features/` ni `data/domain`.
- Las features importan `package:saveup_app/core/design_system/design_system.dart`.
- Componentes específicos de negocio (tarjeta de deuda, tile de movimiento, torta
  de analítica) viven en `features/<feature>/presentation/widgets/` y se
  componen con primitivas; no se meten en el core.
- `lib/app/theme.dart` solo hace `SaveUpTheme.light()` / `SaveUpTheme.dark()`.
- `ThemeExtension<SaveUpColors>` y `ThemeExtension<SaveUpShadows>` para tokens
  que Material no cubre (sombras duras, borde, colores de categoría/charts).
- Barrel con API pública explícita; nada de exponer tokens internos por accidente.

## 5. Componentes y estados (contrato mínimo)

Cada átomo/mólécula debe definir: **default, hover/focus (si aplica), pressed,
disabled, loading, error**, light/dark, semántica y test.

| Componente | API mínima (idea) |
|---|---|
| `NeoSurface` | `child`, `color`, `border`, `shadow`, `radius`, `padding` |
| `NeoCard` | `child`, `accent`, `onTap`, `elevated` |
| `NeoButton` | `label`, `onPressed`, `variant` (primary/secondary/ghost/danger), `icon`, `loading`, `expanded` |
| `NeoIconButton` | `icon`, `tooltip`, `onPressed`, `variant` |
| `NeoInput` | `controller`, `label`, `hint`, `error`, `helper`, `prefix`, `suffix`, `keyboardType`, `textInputAction`, `inputFormatters` |
| `NeoBadge` | `label`, `color`, `icon`, `compact` |
| `NeoChip` | `label`, `selected`, `onSelected` |
| `NeoSegmented` | `values`, `selected`, `onChanged`, `labels` |
| `NeoSwitch` | `value`, `onChanged`, `label`, `description` |
| `NeoProgress` | `value`, `color`, `height`, `label` |
| `NeoListItem` | `leading`, `title`, `subtitle`, `trailing`, `onTap` |
| `NeoStat` | `label`, `value`, `delta`, `accent`, `icon` |
| `NeoMoneyText` | `amount` (`Decimal`), `size`, `signed`, `color` |
| `NeoEmptyState` | `icon`, `title`, `message`, `action` |
| `NeoErrorState` | `message`, `onRetry` |
| `NeoLoading` | `message`, `skeletonRows` |
| `NeoDialog` / `NeoConfirmDialog` | `title`, `message`, `confirmLabel`, `destructive`, `onConfirm` |
| `NeoScaffold` | `title`, `actions`, `bottomNav`, `body`, `pattern` |
| `NeoAppBar` / `NeoSliverAppBar` | `title`, `brand`, `centerTitle`, `leading`, `actions`, `floating`, `pinned`, `snap` |
| `NeoBottomNav` | `destinations`, `selectedIndex`, `onSelected` |
| `NeoChartCard` | `title`, `subtitle`, `legend`, `child`, `empty` |
| `NeoMonthPicker` | `month`, `onChanged`, `min`, `max` |
| `NeoFilterBar` | `filters`, `onChanged`, `onClear` |

Reglas de estilo:
- El botón primario es amarillo con borde tinta y sombra; el secundario es papel
  con borde tinta; el destructivo es `danger` con texto tinta; el ghost no tiene
  sombra.
- Inputs: fondo papel, borde 2, foco amarillo/cian y sombra `sm`; error rojo con
  icono y texto, no solo color.
- Tarjetas: papel, borde 2, sombra `md`, radio 12; hero con borde 3 y sombra `lg`.
- Listas densas: borde 1.5 y sombra `sm` para no comer espacio.
- Diálogos: fondo papel, borde 3, sombra `lg`, botones apilados en mobile.

## 6. Navegación aprobada (Opción B)

`NeoBottomNav` con 5 destinos:
`Inicio · Deudas · Plan · Presupuesto · Más`.

«Más» abre `NeoMoreMenu` con Metas, Analítica, Reportes, Cuenta y Cerrar sesión.
La AppBar queda con título + acciones contextuales (filtros, refresh, cuenta).
No se agrega un séptimo icono al AppBar.

## 7. Patrones de datos y finanzas

- **Dinero:** `NeoMoneyText` recibe `Decimal`; formatea con `Money.formatClp`;
  nunca `double`. Signo/color: ingreso positivo verde/ink, gasto negativo rojo,
  ahorro cian/verde; siempre con signo visible además del color.
- **Formularios:** label arriba, ayuda debajo, error inline con icono; el error
  del backend (`detail` de `DATOS_INVALIDOS`) se muestra en una banda de error,
  no en un toast esquivo.
- **Entrada formateada:** `MoneyInputFormatter` agrupa miles con punto y acepta
  coma decimal (máximo 2) en todos los campos de dinero; `RutInputFormatter`
  normaliza el RUT a `12345678-9` mientras se escribe. Son utilidades de
  presentación (ver D9 de `docs/CONTEXT.md`).
- **Fechas:** `NeoDateField` + `showDatePicker` localizado (ya está `es`);
  `NeoMonthPicker` para plan/presupuesto/analítica.
- **Sliders:** pista gruesa, thumb cuadrado/redondo con borde y sombra; valor
  numérico visible; el `double` solo en la posición visual.
- **Estados:** loading con skeleton en listas, no spinner de pantalla completa
  cuando ya hay datos; empty con ilustración geométrica simple; error con
  reintento.
- **Confirmación destructiva:** `NeoConfirmDialog` con consecuencia explícita
  (p. ej. «sus $80.000 vuelven al saldo»).
- **Reportes/compartir:** botón primario con icono; snackbar con el nombre del
  archivo; hoja de compartir nativa.
- **Gráficos (F10):** `NeoChartCard` con borde/sombra; torta con separadores de
  papel, leyenda con monto/porcentaje y resumen textual; barras con colores de
  categoría y etiquetas; sin gradientes. Librería elegida: **`fl_chart`** (más
  barato y de mayor calidad para torta/barras: tooltips, animación y theming);
  se envuelve en `NeoChartCard` y se personaliza. `CustomPainter` solo si algún
  detalle brutalista (borde negro de cada barra/porción) no se logra con la
  librería. El detalle vive en `features/analitica/presentation/widgets`, no en
  el core.

## 8. Accesibilidad y confianza

- Contraste 4.5:1 cuerpo / 3:1 grande; probar con un checker y en modo oscuro.
- No usar solo color: signos +/-, iconos y texto en estados y gráficos.
- Touch targets ≥ 48 dp; separación mínima 8 dp.
- Text scaling hasta 2.0 sin overflow; `Flexible`/`Wrap` en labels.
- Semántica: `Semantics(label: …)` en botones icónicos, montos y charts;
  `ExcludeSemantics` en decoraciones.
- Reduce motion: desactivar animaciones no esenciales.
- Errores de finanzas: tono claro y directo, sin humor; el rojo no es decorativo.
- No sacrificar densidad útil por sombras: las listas usan borde 1.5/sombra `sm`.

## 9. Pruebas y calidad

- Widget tests por componente (estados, light/dark, text scale 1.0/2.0).
- Golden tests **adoptados** para átomos y `NeoChartCard`; fijar plataforma y
  fuentes, y actualizarlos solo con revisión visual (no en cada PR menor).
- `Semantics` tests para botones icónicos, montos y charts.
- Los tests de features existentes deben seguir verdes; **no** cambiar textos/Keys
  salvo necesidad visual justificada y en el mismo PR.
- Performance: `const` donde aplique, `RepaintBoundary` en listas con sombras,
  evitar `ClipPath`/`BackdropFilter` masivos.
- Checklist de PR: tokens (sin colores sueltos), light/dark, estados, semántica,
  tests, captura de pantalla antes/después, sin cambios de lógica.

## 10. Migración incremental

| Fase | Alcance | Criterio de cierre |
|---|---|---|
| 0 | Decisiones (paleta, fuentes, nav, dark, charts) + inventario + showcase | Documento aprobado |
| 1 | Tokens + `SaveUpTheme` + `ThemeExtension` + atoms base | Átomos en showcase + tests |
| 2 | Molecules (list item, stat, money, empty/error/loading, dialog, snackbar) | Tests y estados |
| 3 | Navegación (`NeoScaffold`, `NeoBottomNav`, `NeoMoreMenu`) | Home/auth usables |
| 4 | Auth + Home (hero de saldo, filtros, lista, FAB) | Tests verdes + manual |
| 5 | Movimientos + Deudas | Tests verdes + manual |
| 6 | Presupuesto + Plan + Metas + Reportes | Tests verdes + manual |
| 7 | Analítica (F10) + asignaciones (F11) con el sistema | Charts + tests |
| 8 | Dark mode, accesibilidad, goldens, pulido | Checklist completo |

Cada fase = un PR/commit; sin big-bang. Se puede usar un wrapper temporal
(`NeoLegacyCard`) para migrar una pantalla sin reescribir su lógica.

**Avance (2026-11-07):** Fases 1 a 8 completadas. Incluye tokens/theme,
átomos, moléculas/patrones, la navegación B (`NeoScaffold`, `NeoAppBar`,
`NeoBottomNav`, `NeoMoreMenu`) con barra inferior Inicio/Deudas/Plan/Presupuesto/
Más y menú «Más» para Metas, Analítica, Reportes, cuenta y Design System;
Auth + Home; movimientos + deudas; presupuesto + plan + metas + reportes; F10
(analítica con `fl_chart`) y F11 (distribución del ahorro entre metas). La Fase 8
migró las últimas pantallas de cuenta y el bloqueo por actualización, habilitó
el modo oscuro del sistema y verificó dark mode y contraste en el emulador.
Además, las tarjetas usan color por rol (amarillo, cian, magenta, verde,
lavanda y naranja) con tinta oscura sobre color, para aprovechar la paleta sin
perder legibilidad.

**Pulido posterior:** `NeoSliverAppBar` para el encabezado de marca con scroll
(floating/snap) y saludo personalizado en Inicio; plan con grupos plegables,
resumen con CTA a Presupuesto y estado «Pagado» derivado de `real ≥ planificado`;
selector de categorías con recientes/frecuentes, iconos y agrupación por tipo;
regla con estado de suma, ayuda contextual y edición precisa de porcentajes; y
formateadores de entrada de dinero y RUT. Tests y goldens claro/oscuro (469
tests verdes).

## 11. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Neo-brutalismo percibido como poco serio para finanzas | Base papel/tinta, acentos solo en acciones/datos, errores sobrios, tipografía clara |
| Contraste insuficiente (amarillo/cian/verde) | Texto tinta sobre acentos; validar con checker; no texto blanco |
| Modo oscuro complejo | Tokens separados por brightness; probar cada componente |
| Romper tests por textos/Keys | Preservar Keys/textos; cambios justificados y test actualizado en el PR |
| Pantallas densas con bordes/sombras | Borde 1.5/sombra `sm` en listas; hero solo en resumen |
| Librería de charts no respeta bordes | `NeoChartCard` + `fl_chart`; si no alcanza, `CustomPainter` solo para el gráfico |
| Fuentes/assets pesados | Bundlear solo 2 familias; subset si aplica; fallback del sistema |
| Deuda de migración | Strangler + showcase + checklist; no tocar lógica |

## 12. Decisiones aprobadas (2026-11-07)

1. **Paleta:** se mantiene la propuesta vívida (papel + tinta + amarillo/cian/
   magenta/naranja/verde); **sin sobriedad** en esta etapa.
2. **Tipografía:** se bundlean **Archivo Black** + **Space Grotesk** (OFL, assets
   locales, sin `google_fonts` en runtime).
3. **Modo oscuro:** se piensa desde el inicio, con **prioridad al claro**. Los
   tokens se definen por `Brightness` y los átomos se prueban en ambos modos.
4. **Navegación:** **Opción B** (`Inicio · Deudas · Plan · Presupuesto · Más`).
5. **Gráficos:** **`fl_chart`** por costo/calidad; `CustomPainter` solo si un
   detalle brutalista no se logra.
6. **Ilustraciones:** formas geométricas y dot grid, sin mascotas.
7. **Densidad:** variable por jerarquía (`hero`, `section`, `list`, `table`).
8. **Goldens:** adoptados para átomos y charts, con plataforma/fuente fijas.

**Fases 0–8 cerradas.** El mantenimiento del sistema es incremental: cualquier
pantalla nueva usa tokens/átomos existentes, y un componente nuevo entra al
showcase con sus estados y tests antes de usarse en features.
