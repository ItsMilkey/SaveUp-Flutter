import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/core/time/business_month.dart';
import 'package:saveup_app/features/reportes/data/dio_reportes_repository.dart';
import 'package:saveup_app/features/reportes/domain/reporte_movimientos.dart';

import '../../support/fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

ResponseBody archivoResponse(
  String contenido, {
  required String contentType,
  String? filename,
  String? contentDisposition,
}) {
  final Map<String, List<String>> headers = <String, List<String>>{
    Headers.contentTypeHeader: <String>[contentType],
    if (filename != null)
      'content-disposition': <String>['attachment; filename="$filename"'],
    if (contentDisposition != null) 'content-disposition': <String>[contentDisposition],
  };
  return ResponseBody.fromBytes(
    utf8.encode(contenido),
    200,
    headers: headers,
  );
}

ResponseBody problemaEnBytes(String codigo, String detail) {
  final String body = jsonEncode(<String, Object?>{
    'type': 'about:blank',
    'title': 'Error',
    'status': 400,
    'detail': detail,
    'codigo': codigo,
  });
  return ResponseBody.fromBytes(
    utf8.encode(body),
    400,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['application/problem+json'],
    },
  );
}

void main() {
  late FakeHttpAdapter adapter;
  late DioReportesRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    repository = DioReportesRepository(client: ApiClient(dio));
  });

  test('exporta CSV completo con query exacta y nombre del header', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'GET');
      expect(
        options.path.endsWith('/reportes/movimientos/exportar'),
        isTrue,
      );
      expect(options.responseType, ResponseType.bytes);
      expect(options.queryParameters, <String, Object?>{
        'alcance': 'COMPLETO',
        'formato': 'CSV',
      });
      expect(options.headers['Accept'], contains('text/csv'));
      return archivoResponse(
        'fecha,monto\n2026-11-07,1000\n',
        contentType: 'text/csv;charset=UTF-8',
        filename: 'reporte_saveup_completo.csv',
      );
    };

    final ReporteArchivo archivo = await repository.exportar(
      const ReporteSolicitud(
        alcance: ReporteAlcance.completo,
        formato: ReporteFormato.csv,
      ),
    );

    expect(archivo.nombre, 'reporte_saveup_completo.csv');
    expect(archivo.contentType, 'text/csv');
    expect(utf8.decode(archivo.bytes), contains('2026-11-07'));
  });

  test('exporta PDF mensual con mes y anio', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.queryParameters, <String, Object?>{
        'alcance': 'MENSUAL',
        'formato': 'PDF',
        'mes': 11,
        'anio': 2026,
      });
      return archivoResponse(
        '%PDF-1.7',
        contentType: 'application/pdf',
        filename: 'reporte_saveup_11-2026.pdf',
      );
    };

    final ReporteArchivo archivo = await repository.exportar(
      ReporteSolicitud(
        alcance: ReporteAlcance.mensual,
        formato: ReporteFormato.pdf,
        periodo: const BusinessMonth(2026, 11),
      ),
    );

    expect(archivo.nombre, 'reporte_saveup_11-2026.pdf');
    expect(archivo.contentType, 'application/pdf');
  });

  test('usa fallback de nombre si falta Content-Disposition', () async {
    adapter.handler = (RequestOptions options) async {
      return archivoResponse(
        'a,b',
        contentType: 'text/csv',
      );
    };

    final ReporteArchivo archivo = await repository.exportar(
      ReporteSolicitud(
        alcance: ReporteAlcance.mensual,
        formato: ReporteFormato.csv,
        periodo: const BusinessMonth(2026, 5),
      ),
    );

    expect(archivo.nombre, 'reporte_saveup_5-2026.csv');
  });

  test('un 400 en bytes conserva codigo y detail', () async {
    adapter.handler = (RequestOptions options) async {
      return problemaEnBytes(
        'DATOS_INVALIDOS',
        'El mes debe estar entre 1 y 12.',
      );
    };

    await expectLater(
      repository.exportar(
        ReporteSolicitud(
          alcance: ReporteAlcance.mensual,
          formato: ReporteFormato.csv,
          periodo: const BusinessMonth(2026, 11),
        ),
      ),
      throwsA(
        isA<BadRequestFailure>()
            .having((BadRequestFailure f) => f.codigo, 'codigo', 'DATOS_INVALIDOS')
            .having(
              (BadRequestFailure f) => f.detail,
              'detail',
              'El mes debe estar entre 1 y 12.',
            ),
      ),
    );
  });

  test('un cuerpo vacío se reporta como falla desconocida', () async {
    adapter.handler = (RequestOptions options) async {
      return ResponseBody.fromBytes(
        Uint8List(0),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['text/csv'],
        },
      );
    };

    await expectLater(
      repository.exportar(
        const ReporteSolicitud(
          alcance: ReporteAlcance.completo,
          formato: ReporteFormato.csv,
        ),
      ),
      throwsA(isA<UnknownFailure>()),
    );
  });
}
