import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/time/business_month.dart';
import 'package:saveup_app/features/reportes/data/dio_reportes_repository.dart';
import 'package:saveup_app/features/reportes/data/reporte_sharer.dart';
import 'package:saveup_app/features/reportes/domain/reporte_movimientos.dart';
import 'package:saveup_app/features/reportes/presentation/controllers/reporte_export_controller.dart';

import 'reportes_fixtures.dart';

void main() {
  late FakeReportesRepository repo;
  late FakeReporteSharer sharer;
  late ProviderContainer container;

  void montar({
    FakeReportesRepository? repository,
    FakeReporteSharer? compartidor,
  }) {
    repo = repository ?? FakeReportesRepository();
    sharer = compartidor ?? FakeReporteSharer();
    container = ProviderContainer(
      overrides: [
        reportesRepositoryProvider.overrideWithValue(repo),
        reporteSharerProvider.overrideWithValue(sharer),
      ],
    );
    addTearDown(container.dispose);
  }

  ReporteExportController controller() =>
      container.read(reporteExportProvider.notifier);
  ReporteExportState estado() => container.read(reporteExportProvider);

  test('exporta, comparte y deja el archivo en el estado', () async {
    montar();
    const ReporteSolicitud solicitud = ReporteSolicitud(
      alcance: ReporteAlcance.completo,
      formato: ReporteFormato.csv,
    );
    final ui.Rect origen = ui.Rect.fromLTWH(0, 0, 100, 100);

    final AppFailure? failure = await controller().exportar(
      solicitud,
      origen: origen,
    );

    expect(failure, isNull);
    expect(repo.solicitud, same(solicitud));
    expect(sharer.compartido!.nombre, 'reporte_saveup_completo.csv');
    expect(sharer.origen, origen);
    expect(estado().archivo!.nombre, 'reporte_saveup_completo.csv');
    expect(estado().enviando, isFalse);
    expect(estado().error, isNull);
  });

  test('un error del repositorio no comparte y queda en el estado', () async {
    montar(
      repository: FakeReportesRepository(
        error: const BadRequestFailure(
          codigo: 'DATOS_INVALIDOS',
          detail: 'El mes debe estar entre 1 y 12.',
        ),
      ),
    );

    final AppFailure? failure = await controller().exportar(
      ReporteSolicitud(
        alcance: ReporteAlcance.mensual,
        formato: ReporteFormato.pdf,
        periodo: const BusinessMonth(2026, 11),
      ),
    );

    expect(failure, isA<BadRequestFailure>());
    expect(sharer.compartido, isNull);
    expect(estado().error, isA<BadRequestFailure>());
    expect(estado().enviando, isFalse);
  });

  test('un fallo del sharer se reporta como UnknownFailure', () async {
    montar(
      compartidor: FakeReporteSharer()..error = StateError('sin share sheet'),
    );

    final AppFailure? failure = await controller().exportar(
      const ReporteSolicitud(
        alcance: ReporteAlcance.completo,
        formato: ReporteFormato.pdf,
      ),
    );

    expect(failure, isA<UnknownFailure>());
    expect(
      (failure! as UnknownFailure).detail,
      'No se pudo compartir el archivo.',
    );
    expect(estado().error, isA<UnknownFailure>());
  });

  test('ignora una segunda exportación mientras la primera corre', () async {
    final Completer<ReporteArchivo> pendiente = Completer<ReporteArchivo>();
    montar(
      repository: FakeReportesRepository()..respuestaFutura = pendiente.future,
    );
    const ReporteSolicitud solicitud = ReporteSolicitud(
      alcance: ReporteAlcance.completo,
      formato: ReporteFormato.csv,
    );

    final Future<AppFailure?> primera = controller().exportar(solicitud);
    expect(estado().enviando, isTrue);
    final AppFailure? segunda = await controller().exportar(solicitud);
    expect(segunda, isNull);
    expect(repo.llamadas, 1);

    pendiente.complete(archivoDePrueba());
    expect(await primera, isNull);
    expect(estado().enviando, isFalse);
  });
}
