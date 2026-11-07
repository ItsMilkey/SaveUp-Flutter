import 'dart:typed_data';

import '../../../core/time/business_month.dart';

/// Alcance del reporte (`alcance` del contrato).
enum ReporteAlcance {
  completo('COMPLETO'),
  mensual('MENSUAL');

  const ReporteAlcance(this.codigo);

  final String codigo;
}

/// Formato de exportación (`formato` del contrato).
enum ReporteFormato {
  csv('CSV', 'text/csv', 'csv'),
  pdf('PDF', 'application/pdf', 'pdf');

  const ReporteFormato(this.codigo, this.contentType, this.extension);

  final String codigo;
  final String contentType;
  final String extension;
}

/// Parámetros de `GET /reportes/movimientos/exportar`.
class ReporteSolicitud {
  const ReporteSolicitud({
    required this.alcance,
    required this.formato,
    this.periodo,
  }) : assert(
         alcance == ReporteAlcance.completo
             ? periodo == null
             : periodo != null,
         'El alcance mensual requiere periodo y el completo lo omite.',
       );

  final ReporteAlcance alcance;
  final ReporteFormato formato;

  /// Solo con [ReporteAlcance.mensual].
  final BusinessMonth? periodo;
}

/// Archivo descargado, listo para compartir.
class ReporteArchivo {
  const ReporteArchivo({
    required this.bytes,
    required this.nombre,
    required this.contentType,
  });

  final Uint8List bytes;
  final String nombre;
  final String contentType;
}
