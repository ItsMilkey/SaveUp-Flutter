import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/dio_reportes_repository.dart';
import '../../data/reporte_sharer.dart';
import '../../domain/reporte_movimientos.dart';

/// Estado de la exportación de un reporte.
class ReporteExportState {
  const ReporteExportState({
    this.enviando = false,
    this.archivo,
    this.error,
  });

  final bool enviando;
  final ReporteArchivo? archivo;
  final AppFailure? error;
}

final NotifierProvider<ReporteExportController, ReporteExportState>
reporteExportProvider =
    NotifierProvider<ReporteExportController, ReporteExportState>(
      ReporteExportController.new,
    );

class ReporteExportController extends Notifier<ReporteExportState> {
  bool _enCurso = false;
  int _version = 0;

  @override
  ReporteExportState build() => const ReporteExportState();

  /// Descarga el reporte y abre la hoja de compartir.
  ///
  /// Devuelve la falla para que la pantalla la muestre; `null` = éxito.
  Future<AppFailure?> exportar(
    ReporteSolicitud solicitud, {
    ui.Rect? origen,
  }) async {
    if (_enCurso) {
      return null;
    }
    _enCurso = true;
    final int version = _version;
    state = const ReporteExportState(enviando: true);
    try {
      final ReporteArchivo archivo = await ref
          .read(reportesRepositoryProvider)
          .exportar(solicitud);
      if (version != _version) {
        return null;
      }
      await ref
          .read(reporteSharerProvider)
          .compartir(archivo, origen: origen);
      if (version != _version) {
        return null;
      }
      state = ReporteExportState(archivo: archivo);
      return null;
    } on AppFailure catch (failure) {
      if (version != _version) {
        return null;
      }
      state = ReporteExportState(error: failure);
      return failure;
    } catch (_) {
      if (version != _version) {
        return null;
      }
      const AppFailure failure = UnknownFailure(
        detail: 'No se pudo compartir el archivo.',
      );
      state = const ReporteExportState(error: failure);
      return failure;
    } finally {
      _enCurso = false;
      if (version != _version) {
        state = const ReporteExportState();
      }
    }
  }

  void reset() {
    _version += 1;
    state = ReporteExportState(enviando: _enCurso);
  }
}
