import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/reportes/data/reporte_sharer.dart';
import 'package:saveup_app/features/reportes/domain/reporte_movimientos.dart';
import 'package:saveup_app/features/reportes/domain/reportes_repository.dart';

ReporteArchivo archivoDePrueba({
  String nombre = 'reporte_saveup_completo.csv',
  String contentType = 'text/csv',
  String contenido = 'fecha,monto\n2026-11-07,1000\n',
}) {
  return ReporteArchivo(
    bytes: Uint8List.fromList(utf8.encode(contenido)),
    nombre: nombre,
    contentType: contentType,
  );
}

class FakeReportesRepository implements ReportesRepository {
  FakeReportesRepository({this.respuesta, this.error});

  ReporteArchivo? respuesta;
  AppFailure? error;
  Future<ReporteArchivo>? respuestaFutura;
  ReporteSolicitud? solicitud;
  int llamadas = 0;

  @override
  Future<ReporteArchivo> exportar(ReporteSolicitud solicitud) async {
    this.solicitud = solicitud;
    llamadas += 1;
    if (error != null) {
      throw error!;
    }
    if (respuestaFutura != null) {
      return respuestaFutura!;
    }
    return respuesta ?? archivoDePrueba();
  }
}

class FakeReporteSharer implements ReporteArchivoSharer {
  ReporteArchivo? compartido;
  ui.Rect? origen;
  Object? error;

  @override
  Future<void> compartir(ReporteArchivo archivo, {ui.Rect? origen}) async {
    compartido = archivo;
    this.origen = origen;
    if (error != null) {
      throw error!;
    }
  }
}
