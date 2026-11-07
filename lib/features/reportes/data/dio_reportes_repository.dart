import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/time/business_month.dart';
import '../domain/reporte_movimientos.dart';
import '../domain/reportes_repository.dart';

final Provider<ReportesRepository> reportesRepositoryProvider =
    Provider<ReportesRepository>((Ref ref) {
      return DioReportesRepository(client: ref.watch(apiClientProvider));
    });

/// Reportes sobre el cliente HTTP de la app.
class DioReportesRepository implements ReportesRepository {
  const DioReportesRepository({required this.client});

  final ApiClient client;

  @override
  Future<ReporteArchivo> exportar(ReporteSolicitud solicitud) async {
    final Response<List<int>> response = await client.getBytes(
      '/reportes/movimientos/exportar',
      queryParameters: _query(solicitud),
      headers: const <String, dynamic>{
        'Accept': 'text/csv, application/pdf, application/problem+json',
      },
    );
    final List<int>? data = response.data;
    if (data == null || data.isEmpty) {
      throw const UnknownFailure(
        detail: 'El servidor no devolvió el archivo.',
      );
    }
    return ReporteArchivo(
      bytes: Uint8List.fromList(data),
      nombre:
          _nombreDesde(response.headers.value('content-disposition')) ??
          _nombreFallback(solicitud),
      contentType:
          _contentType(response.headers.value('content-type')) ??
          solicitud.formato.contentType,
    );
  }

  Map<String, dynamic> _query(ReporteSolicitud solicitud) {
    final BusinessMonth? periodo = solicitud.periodo;
    return <String, dynamic>{
      'alcance': solicitud.alcance.codigo,
      'formato': solicitud.formato.codigo,
      if (solicitud.alcance == ReporteAlcance.mensual && periodo != null) ...{
        'mes': periodo.month,
        'anio': periodo.year,
      },
    };
  }

  String? _contentType(String? header) {
    if (header == null || header.isEmpty) {
      return null;
    }
    return header.split(';').first.trim();
  }

  String? _nombreDesde(String? header) {
    if (header == null || header.isEmpty) {
      return null;
    }
    final RegExpMatch? quoted = RegExp(
      r'filename="([^"]+)"',
    ).firstMatch(header);
    if (quoted != null) {
      return quoted.group(1);
    }
    final RegExpMatch? plain = RegExp(r'filename=([^;]+)').firstMatch(header);
    return plain?.group(1)?.trim();
  }

  String _nombreFallback(ReporteSolicitud solicitud) {
    final String alcance =
        solicitud.alcance == ReporteAlcance.mensual
            ? '${solicitud.periodo!.month}-${solicitud.periodo!.year}'
            : 'completo';
    return 'reporte_saveup_$alcance.${solicitud.formato.extension}';
  }
}
