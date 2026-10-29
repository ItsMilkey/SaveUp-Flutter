# Reglas Flutter/Dart — saveup_app (siempre activas)

Antes de escribir código, lee `docs/CONTEXT.md` y la tarea en `docs/tareas/`.
El contrato del backend está en `docs/contrato/` y manda sobre cualquier suposición.

## Alcance y honestidad
- Implementa solo lo que pide la tarea. No agregues funcionalidades "de paso".
- No inventes endpoints, campos ni códigos de error. Si falta algo, déjalo como `TODO` y repórtalo.
- No digas que algo funciona si no lo ejecutaste. Si no pudiste correr la app en un
  dispositivo, dilo explícitamente.

## Dinero y tiempo
- Prohibido `double` para dinero en dominio, estado y UI. Usa `Decimal`.
- `num`/`double` solo en `lib/core/money/money_json.dart` (borde de serialización).
- Porcentajes: tal como llegan (1.5 = 1,5 %). No dividir ni multiplicar por 100.
- La app no recalcula saldos, intereses, cuotas ni CAE: muestra lo que entrega el backend.
- Instantes en UTC; fechas de calendario `yyyy-MM-dd` sin zona; mes de negocio en America/Santiago.

## Arquitectura
- `domain` no importa Flutter ni Dio. `presentation` no habla con `data` directamente.
- Nada de lógica de negocio en widgets. Un widget público por archivo.
- Estado solo con Riverpod. Sin generadores de código (freezed, build_runner, openapi-generator).
- Archivos `snake_case.dart`. Símbolos en inglés; textos de UI y docs en español.

## Red y errores
- Todo acceso HTTP pasa por el cliente de `lib/core/network/`. No crear `Dio()` sueltos.
- Los errores se traducen a `AppFailure` por `codigo`; nunca decidir mensajes con `detail`.
- Nunca registrar en logs el header `Authorization`, tokens, contraseñas ni cuerpos de auth.
- Los tokens viven solo en `flutter_secure_storage`.
- Sin `print`. Sin reintentos automáticos en bucle (excepto el refresh único documentado).

## Calidad
- Cada módulo nuevo trae pruebas en `test/` espejando `lib/`.
- Cierra cada tarea con `flutter analyze` (sin issues) y `flutter test` (en verde).
- No agregues dependencias que la tarea no mencione sin justificarlo en el resumen final.
- No hagas `git push` ni comandos destructivos. Commits locales en español.
