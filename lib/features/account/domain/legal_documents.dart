/// Textos provisionales de los documentos legales (F2).
///
/// El contrato solo entrega los **números de versión** vigentes
/// (`versionTerminos`/`versionPrivacidad` en `GET /app/version`); no existe
/// aún endpoint ni URL del contenido en el backend. Decisión aprobada: dejar
/// la interfaz funcional con un texto provisional claro y pendiente del
/// texto legal definitivo.
///
/// TODO(F2+/legal): reemplazar por el contenido oficial cuando exista su
/// fuente (backend, asset o web).
library;

/// Texto provisional de los Términos y Condiciones de Uso.
const String textoProvisionalTerminos = '''
Términos y Condiciones de Uso de SaveUp

1. Este es un documento provisional.
2. La versión vigente se informa en la pantalla y proviene del backend.
3. El texto definitivo aún no está disponible; se agregará cuando la
   fuente legal esté definida.

TEXTO PROVISIONAL — no constituye el documento legal oficial.
''';

/// Texto provisional de la Política de Privacidad.
const String textoProvisionalPrivacidad = '''
Política de Privacidad de SaveUp

1. Este es un documento provisional.
2. La versión vigente se informa en la pantalla y proviene del backend.
3. El texto definitivo aún no está disponible; se agregará cuando la
   fuente legal esté definida.

TEXTO PROVISIONAL — no constituye el documento legal oficial.
''';
