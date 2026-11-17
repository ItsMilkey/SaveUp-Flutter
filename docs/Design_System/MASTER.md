# SaveUp · MASTER (rework de UI, 2026-11-17)

Documento operativo de la dirección visual aprobada en F1. Manda para implementar F2–F5.
El contrato completo es `DESIGN_SYSTEM_PLAN.md` (§13 contiene esta evolución) y el plan de
ejecución es `REWORK_UI_PLAN.md`.

> **No se generó con el generador automático de diseño.** Su recomendación por defecto
> (Glassmorphism, azul corporativo, Caveat/Quicksand) contradice la identidad aprobada; se
> usó como menú, no como veredicto. Esto es una desviación consciente del plan, registrada.

## 1. Identidad

«Neo-brutalismo disciplinado»: papel + tinta, acentos vibrantes, bordes gruesos, sombras
duras, tipografía pesada. Se conserva de la etapa 2026-11-07; cambia **cómo se usa**.

Referencias que definen la dirección: `References/Diseño10.jpg` y `References/Diseño11.jpg`
(componentes sticker, labels en mayúsculas, sombra dura). `References/Diseño4.jpg` queda
como alternativa editorial no adoptada. `References/Diseño1.jpg` no pertenece a esta
familia: aporta ideas de layout, no de estilo.

## 2. Tokens que no cambian

| Grupo | Valor |
|---|---|
| Paleta | `ink #111111` · `paper #FFFDF7` · `canvas #F7F1E3` · `yellow #FFD43B` · `cyan #57D9E8` · `magenta #F45B9A` · `orange #FF8A3D` · `green #3DDC97` · `lavender #B79CFF` · `danger #E5484D` |
| Tipografía | Display `ArchivoBlack` · UI `SpaceGrotesk` (variable, `FontVariation('wght')`) |
| Radios | `sm 8` · `md 12` · `lg 16` · `pill 999` |
| Sombras | `sm Offset(2,2)` · `md Offset(4,4)` · `lg Offset(6,6)`, siempre `blurRadius: 0` |
| Espaciado | 4 · 8 · 12 · 16 · 24 · 32 · 48 |
| Motion | press 120 ms · fade 200 ms · página 300 ms · `easeOutCubic` + respeto de `reduce motion` |

## 3. Las seis reglas

**R-1 · Foreground de superficies.** Tinta sobre claros, texto claro del tema sobre oscuros.
`NeoSurface` lo deduce; `SaveUpColors.onAccentSurface` es tinta en los 3 temas. Nunca
`colors.ink` sobre un acento.

**R-2 · Elevación por jerarquía.** `hero` (3 / `lg`) · `section` (2 / `md`) · `list`
(1.5 / `sm`) · `table` (1 / sin sombra). Máximo un `hero` por pantalla; listas y filas usan
`list`, no `section`.

**R-3 · Color semántico.** Amarillo acción · verde éxito/ahorro · naranja aviso · rojo
error/destructivo · cian información. Magenta y lavanda, solo para categorías y charts.
Tarjetas de contenido en papel; el acento va en progreso, estado o icono.

**R-4 · Etiquetas y cifras.** Labels, chips y botones en MAYÚSCULAS, tracking 0.5, peso 600.
Cifras con `tabularFigures()`. Un solo display por pantalla.

**R-5 · Listas densas.** Fila = concepto + monto (derecha) + micro-línea fecha · categoría.
Monto con signo y color semántico. 64–72 dp de alto, sombra `sm`, separación 8 dp. FAB con
inset inferior; la lista reserva padding para no quedar tapada.

**R-6 · Superficie.** Canvas crema, tarjetas papel. Dot-grid solo en hero; nunca en listas,
formularios ni tablas.

## 4. Patrones por pantalla (olas de F4–F5)

| Pantalla | Intención | Notas de dirección |
|---|---|---|
| Inicio | Leer el saldo y el último movimiento en <2 s | Un único `hero` para el saldo; filtros en `section`; lista en `list` con densidad R-5 |
| Movimientos | Escanear y reconocer | Monto a la derecha, signo + color semántico; agrupación por día como `table` |
| Presupuesto | Ajustar la regla sin miedo | Sliders con valor visible; tarjetas en `section`; el color codifica la categoría, no la tarjeta |
| Metas | Saber cuánto falta | Tarjeta papel; acento en el progreso y el estado; sin ciclo de colores por meta |
| Analítica / Reportes | Comparar | `NeoChartCard`; colores de categoría permitidos aquí; sin gradientes |
| Auth | Entrar rápido | `hero` con dot-grid; un solo CTA amarillo |

## 5. Anti-patrones (lo que se destruye)

- Borde 2 + sombra `md` en **todo**: mata la jerarquía.
- Tarjetas de contenido rellenas con un color de la paleta por decoración.
- Labels en caja mixta en contextos donde la referencia usa mayúsculas con tracking.
- Filas de lista a dos líneas con tarjeta y sombra: pierden densidad.
- Texto claro sobre acentos claros, o `colors.ink` como foreground de un acento.
- Más de un `display` compitiendo en la misma pantalla.
- Gradientes y glassmorphism.

## 6. Checklist antes de entregar un lote

- [ ] Un solo `hero` por pantalla; listas en `list`/`table`.
- [ ] Ningún color de tarjeta decorativo; acentos solo semánticos.
- [ ] Labels en MAYÚSCULAS con tracking; cifras tabulares.
- [ ] Filas densas con monto a la derecha y micro-línea.
- [ ] Los 3 temas verificados (claro, oscuro, Bold).
- [ ] Contraste 4.5:1 cuerpo / 3:1 grande; foco visible; `reduce motion` respetado.
- [ ] Text scaling 2.0 sin recortes; targets ≥ 48 dp.
- [ ] Cero `Color(0x…)`, `TextStyle`, `EdgeInsets` o `BoxShadow` sueltos en features.
- [ ] `flutter analyze` y `flutter test` en verde; goldens revisados si cambiaron.

## 7. Fuera de alcance

Contratos, endpoints, DTOs, fórmulas, navegación (Opción B) y arquitectura feature-first.
Este documento no autoriza cambios de lógica: solo de presentación y del contrato del
design system.
