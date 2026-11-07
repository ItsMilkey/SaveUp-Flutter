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
  @override
  ReporteExportState build() => const ReporteExportState();

  /// Descarga el reporte y abre la hoja de compartir.
  ///
  /// Devuelve la falla para que la pantalla la muestre; `null` = éxito.
  Future<AppFailure?> exportar(
    ReporteSolicitud solicitud, {
    ui.Rect? origen,
  }) async {
    if (state.enviando) {
      return null;
    }
    state = const ReporteExportState(enviando: true);
    try {
      final ReporteArchivo archivo = await ref
          .read(reportesRepositoryProvider)
          .exportar(solicitud);
      await ref
          .read(reporteSharerProvider)
          .compartir(archivo, origen: origen);
      state = ReporteExportState(archivo: archivo);
      return null;
    } on AppFailure catch (failure) {
      state = ReporteExportState(error: failure);
      return failure;
    } catch (_) {
      const AppFailure failure = UnknownFailure(
        detail: 'No se pudo compartir el archivo.',
      );
      state = const ReporteExportState(error: failure);
      return failure;
    }
  }

  void reset() {
    state = const ReporteExportState();
  }
}
