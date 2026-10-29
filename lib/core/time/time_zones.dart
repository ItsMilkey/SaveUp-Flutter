import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Nombre de la zona del negocio. Los meses de presupuesto, resúmenes y
/// recordatorios se calculan aquí, no en la zona del dispositivo.
const String businessTimeZoneName = 'America/Santiago';

bool _initialized = false;

/// Carga la base de datos de zonas horarias de IANA.
///
/// Se llama en `main()` antes de `runApp`. Es idempotente.
void initializeTimeZones() {
  if (_initialized) {
    return;
  }
  tzdata.initializeTimeZones();
  _initialized = true;
}

/// Zona horaria del negocio (`America/Santiago`).
///
/// Inicializa la base si hace falta, para que las utilidades de tiempo
/// funcionen también en pruebas sin un `setUpAll` manual.
tz.Location get businessTimeZone {
  initializeTimeZones();
  return tz.getLocation(businessTimeZoneName);
}
