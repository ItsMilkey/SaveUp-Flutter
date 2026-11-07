import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/reporte_movimientos.dart';

/// Abre la hoja de compartir del sistema con el archivo descargado.
abstract interface class ReporteArchivoSharer {
  Future<void> compartir(ReporteArchivo archivo, {ui.Rect? origen});
}

final Provider<ReporteArchivoSharer> reporteSharerProvider =
    Provider<ReporteArchivoSharer>((Ref ref) {
      return const SharePlusReporteSharer();
    });

class SharePlusReporteSharer implements ReporteArchivoSharer {
  const SharePlusReporteSharer();

  @override
  Future<void> compartir(ReporteArchivo archivo, {ui.Rect? origen}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile.fromData(
            archivo.bytes,
            name: archivo.nombre,
            mimeType: archivo.contentType,
          ),
        ],
        fileNameOverrides: <String>[archivo.nombre],
        subject: archivo.nombre,
        sharePositionOrigin: origen,
      ),
    );
  }
}
