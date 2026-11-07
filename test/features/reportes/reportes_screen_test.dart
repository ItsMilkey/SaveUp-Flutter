import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/features/reportes/data/dio_reportes_repository.dart';
import 'package:saveup_app/features/reportes/data/reporte_sharer.dart';
import 'package:saveup_app/features/reportes/domain/reporte_movimientos.dart';
import 'package:saveup_app/features/reportes/presentation/screens/reportes_screen.dart';

import 'reportes_fixtures.dart';

Future<void> montar(
  WidgetTester tester, {
  required FakeReportesRepository repo,
  required FakeReporteSharer sharer,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reportesRepositoryProvider.overrideWithValue(repo),
        reporteSharerProvider.overrideWithValue(sharer),
      ],
      child: MaterialApp(
        theme: SaveUpTheme.light(),
        home: const ReportesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('exporta CSV completo y comparte el archivo', (
    WidgetTester tester,
  ) async {
    final FakeReportesRepository repo = FakeReportesRepository();
    final FakeReporteSharer sharer = FakeReporteSharer();
    await montar(tester, repo: repo, sharer: sharer);

    expect(find.text('Completo'), findsOneWidget);
    expect(find.text('Mensual'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);

    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();

    expect(repo.solicitud!.alcance, ReporteAlcance.completo);
    expect(repo.solicitud!.formato, ReporteFormato.csv);
    expect(repo.solicitud!.periodo, isNull);
    expect(sharer.compartido!.nombre, 'reporte_saveup_completo.csv');
    expect(
      find.text('Archivo listo: reporte_saveup_completo.csv'),
      findsOneWidget,
    );
    expect(
      find.text('Reporte listo: reporte_saveup_completo.csv'),
      findsOneWidget,
    );
  });

  testWidgets('exporta PDF mensual con el periodo elegido', (
    WidgetTester tester,
  ) async {
    final FakeReportesRepository repo = FakeReportesRepository(
      respuesta: archivoDePrueba(
        nombre: 'reporte_saveup_11-2026.pdf',
        contentType: 'application/pdf',
        contenido: '%PDF-1.7',
      ),
    );
    final FakeReporteSharer sharer = FakeReporteSharer();
    await montar(tester, repo: repo, sharer: sharer);

    await tester.tap(find.text('Mensual'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);

    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();

    expect(repo.solicitud!.alcance, ReporteAlcance.mensual);
    expect(repo.solicitud!.formato, ReporteFormato.pdf);
    expect(repo.solicitud!.periodo, isNotNull);
    expect(sharer.compartido!.contentType, 'application/pdf');
    expect(
      find.text('Archivo listo: reporte_saveup_11-2026.pdf'),
      findsOneWidget,
    );
  });

  testWidgets('muestra el detail del backend y no comparte', (
    WidgetTester tester,
  ) async {
    final FakeReportesRepository repo = FakeReportesRepository(
      error: const BadRequestFailure(
        codigo: 'DATOS_INVALIDOS',
        detail: 'El mes debe estar entre 1 y 12.',
      ),
    );
    final FakeReporteSharer sharer = FakeReporteSharer();
    await montar(tester, repo: repo, sharer: sharer);

    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();

    expect(
      find.text('El mes debe estar entre 1 y 12.'),
      findsWidgets,
    );
    expect(sharer.compartido, isNull);
  });
}
