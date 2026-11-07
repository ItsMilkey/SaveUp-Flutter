# F10 — Analítica de gastos (propuesta)

> **Estado: propuesta de diseño (2026-11-07), sin implementar.** No requiere
> cambios de contrato ni endpoints nuevos: se alimenta de endpoints existentes,
> verificados contra el backend local y producción.

## Objetivo
Una pantalla que responda de un vistazo: **¿cuánto gasté, en qué categorías y
cómo evoluciona mes a mes?** Debe ser rápida, legible y sin configurar nada
(no exige haber creado un plan ni una regla de presupuesto).

## Fuentes de datos (todas existentes)

| Endpoint | Uso | Verificación |
|---|---|---|
| `GET /planes/{mes}` | `resumen` (ingresos, gasto real, ahorro, disponible), `porCategoria[].real`, `repartoPorTipo[].real`, `sinPlanificar` | Con `existe=false` y sin plan, devuelve `porCategoria` con el gasto real por categoría |
| `GET /presupuestos/historial/me?desde&hasta` | Tendencia mensual: `totalIngresos`, `gastoNecesidades`, `gastoDeseos`, `ahorroRealizado` | Devuelve gastos reales y presupuestos 50/30/20 por defecto aunque no haya regla guardada |
| `GET /categorias` | Nombre y `colorHex` por `codigo` para la torta | Catálogo de 18 categorías, cacheable |

### Hallazgos de borde (importantes)
- **Gasto sin categoría**: `gastoRealTotal` incluye un `GASTO_GENERAL` sin
  `categoriaId`, pero `porCategoria` no lo lista. La torta debe añadir una
  porción **«Sin categoría»** con `gastoRealTotal − Σ(porCategoria.real)` cuando
  sea positiva, para que el total del gráfico cuadre con el KPI.
- **Sin plan guardado**: el endpoint del plan igual calcula `resumen` y
  `porCategoria` a partir de los movimientos; no hay que crear un plan.
- **Sin regla de presupuesto**: el historial usa la guía por defecto 50/30/20
  para `presupuesto*`, pero los `gasto*` son reales.
- **PAGO_DEUDA** suma al gasto real; si no tiene categoría, cae en «Sin
  categoría».

## UX propuesta

### Entrada
La barra del home ya tiene 6 acciones; un séptimo icono la desborda en pantallas
angostas. Para el MVP:
- Entrada provisional desde el **Plan** (icono `insights_outlined`) o una tarjeta
  «Ver analítica» en el home.
- La navegación definitiva (barra inferior / drawer) se decide en el **rediseño
  UI/UX** que está en preparación. Si el rediseño está cerca, conviene implementar
  esta pantalla **como primera pantalla del nuevo diseño** para no rehacerla.

### Pantalla `/analitica`
1. **Selector de mes** (BusinessMonth, chevrons), por defecto el mes actual.
2. **KPIs** en grilla 2×2: Ingresos, Gastos, Ahorro, Disponible.
3. **Torta «Gastos por categoría»**:
   - Top 6 categorías por `real` + «Otros» + «Sin categoría» si aplica.
   - Colores desde `Categoria.colorHex`; fallback a una paleta del tema.
   - Centro: total de gastos. Leyenda con monto y porcentaje.
   - Tocar una porción resalta su categoría en la leyenda (sin navegación).
4. **Barras «Últimos 6 meses»**:
   - Ingresos vs gastos (necesidades + deseos) por mes; el ahorro puede ir como
     línea o tercera barra.
   - El rango termina en el mes seleccionado y usa el historial (máx. 6–12).
5. **Reparto por tipo** del mes: barra apilada o tres barras pequeñas
   (Necesidades / Deseos / Otros) con montos y porcentajes.
6. **Top categorías** en lista debajo: punto de color, nombre, monto, % y barra
   fina de proporción. Sirve de tabla accesible cuando la torta no basta.
7. **Estados**: cargando, sin movimientos en el mes (mensaje y selector), error
   con `failureMessage` y reintento; pull-to-refresh.

### Accesibilidad y legibilidad
- No depender solo del color: leyenda con nombre y monto.
- Números con `Money.formatClp`; porcentajes con 1 decimal.
- Torta con máximo 8 porciones (Top 6 + Otros + Sin categoría).
- Textos en español; fechas con el patrón `yyyy-MM` o el mes abreviado.

## Arquitectura propuesta
- **Sin capa data nueva**: reutilizar
  `planMensualRepositoryProvider` (`GET /planes/{mes}`),
  `presupuestoRepositoryProvider.historial(...)` y
  `categoriasRepositoryProvider.listar()`.
- Dominio puro `analitica.dart`:
  - `ResumenAnalitica` (KPIs), `GastoCategoria` (id, codigo, nombre, color,
    monto `Decimal`, porcentaje `Decimal`), `PuntoMensual` (mes, ingresos,
    gastos, ahorro).
  - Agregador con `Decimal`: filtra `real > 0`, ordena desc, top 6, agrega
    «Otros» y «Sin categoría». El `double` aparece **solo** al pasar valores a
    `fl_chart`.
- `AnaliticaController` (Notifier): mes seleccionado, carga en paralelo del plan,
  historial de 6 meses y catálogo; estado `cargando/error/datos`; reintento.
- `AnaliticaScreen` + widgets `_TortaGastos`, `_BarrasMensuales`,
  `_RepartoPorTipo`, `_TopCategorias`.
- **Librería de gráficos**: `fl_chart` (torta y barras, tooltips, animación,
  themable). Alternativa sin dependencia: `CustomPainter` para torta y barras,
  más trabajo y menos accesible. Recomendación: `fl_chart`, decidir junto con el
  rediseño para que encaje en el theme.

## Pruebas
- Agregador: top 6 + Otros, «Sin categoría» cuando el total no cuadra,
  porcentajes que suman 100 (con redondeo controlado), mes vacío.
- Controlador: carga plan + historial + catálogo; error de cualquiera; cambio de
  mes; reintento.
- Widget: KPIs, torta y barras presentes; estado vacío; error; cambio de mes.
- No se necesitan tests de contrato nuevos: los repositorios de F6a/F6 ya los
  cubren.

## Fuera de alcance
- Rangos de fecha personalizados, comparación año contra año, proyecciones y
  presupuestos sugeridos.
- Agregación del lado del servidor (no hay endpoint de analítica; no se inventa).
- Exportar el análisis (F8 ya exporta movimientos).
- Rediseño UI/UX y themes (tarea aparte, en preparación).

## Riesgos y decisiones
- **Dependencia de `fl_chart`**: nueva dependencia pura Dart; si el rediseño
  define otra librería o gráficos propios, se ajusta antes de implementar.
- **`porCategoria` y gastos sin categoría**: resuelto con la porción «Sin
  categoría» (verificado).
- **Entrada en la navegación**: no agregar un séptimo icono al AppBar; definirlo
  con el rediseño.
- **Rendimiento**: 2–3 peticiones por mes (no se pagina todo el historial de
  movimientos); el catálogo se puede cachear en el provider.

## Plan sugerido (si se aprueba)
1. Dominio agregador + controlador + tests (sin UI).
2. Pantalla con `fl_chart` + tests de widget.
3. Verificación manual con un mes con datos, un mes vacío y un gasto sin
   categoría.

**Recomendación de secuencia:** si el plan de rediseño UI/UX está cerca,
implementar F10 **con el nuevo diseño** (evita rehacer la pantalla); si se quiere
valor inmediato, hacer solo el dominio/controlador ahora y dejar la UI para el
rediseño.
