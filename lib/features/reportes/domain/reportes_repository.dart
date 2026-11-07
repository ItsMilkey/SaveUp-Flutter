import 'reporte_movimientos.dart';

/// Contrato de datos de reportes (F8).
abstract interface class ReportesRepository {
  /// `GET /reportes/movimientos/exportar` (binario).
  Future<ReporteArchivo> exportar(ReporteSolicitud solicitud);
}
