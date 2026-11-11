Contexto:
Tenemos una aplicación en Flutter de finanzas personales (SaveUp) con su lógica de negocio, integración con backend y tests E2E completamente terminados (Fases 1 a 8 cerradas, 382 tests en verde). La arquitectura actual usa DDD.

Objetivo:
Vamos a aplicar un rediseño total de UI/UX utilizando un estilo Neo-Brutalista. Por favor, revisa la carpeta frontend/docs/design_system/references donde encontrarás imágenes de referencia y el archivo neo_brutalism_guidelines.md con las reglas de diseño (colores, bordes gruesos, sombras sin desenfoque, tipografía).

Reglas Críticas de Refactorización:

    Cero impacto en la lógica: NO modifiques controladores, repositorios, DTOs ni el estado de Riverpod. Solo tocaremos la capa de presentación (presentation/).

    Protección de Tests: Intenta no eliminar Keys (por ejemplo Key('login_button')) ni textos exactos que puedan romper los Widget Tests existentes. Si un cambio visual requiere romper un test, avísame para actualizar el test.

    Sombras Neo-Brutalistas en Flutter: Recuerda que para lograr este efecto, los BoxShadow deben tener SIEMPRE blurRadius: 0 y un offset claro (ej. Offset(4, 4)), con colores sólidos (negro o colores oscuros).

Plan de Ejecución Paso a Paso (Espera mi confirmación para avanzar al siguiente paso):

Paso 1: Core Theme (lib/core/theme/)
Crea/actualiza saveup_theme.dart. Define la paleta de colores vibrantes neo-brutalistas, la tipografía (sans-serif gruesa), los InputDecorationTheme, ElevatedButtonThemeData y CardTheme globales con bordes negros (por ejemplo, BorderSide(width: 2)) y sombras sólidas.

Paso 2: Componentes Atómicos (Basekit)
Crea widgets base reutilizables en lib/core/presentation/widgets/:

    NeoCard: Contenedor base con borde grueso y sombra dura.

    NeoButton: Botón primario y secundario neo-brutalista.

    NeoBadge: Para estados de presupuesto y categorías.

    NeoInputField: Campos de texto estructurados.

Paso 3: Refactor del Dashboard / Home
Aplica el Theme y los componentes atómicos a la pantalla principal. Transforma la tarjeta de Saldo actual en un "Hero Card" neo-brutalista y dale estilo a la lista de movimientos.

¿Entendido? Si es así, responde con "Contexto asimilado" y genera el código para el Paso 1: Core Theme.