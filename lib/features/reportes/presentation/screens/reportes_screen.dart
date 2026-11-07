import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/time/business_month.dart';
import '../../domain/reporte_movimientos.dart';
import '../controllers/reporte_export_controller.dart';

/// Exportación de movimientos a CSV o PDF.
class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  ReporteAlcance _alcance = ReporteAlcance.completo;
  ReporteFormato _formato = ReporteFormato.csv;
  BusinessMonth _periodo = BusinessMonth.fromInstant(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(reporteExportProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReporteExportState estado = ref.watch(reporteExportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(
            'Descarga tus movimientos y compártelos desde el móvil.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text('Alcance', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ReporteAlcance>(
            segments: const <ButtonSegment<ReporteAlcance>>[
              ButtonSegment<ReporteAlcance>(
                value: ReporteAlcance.completo,
                label: Text('Completo'),
              ),
              ButtonSegment<ReporteAlcance>(
                value: ReporteAlcance.mensual,
                label: Text('Mensual'),
              ),
            ],
            selected: <ReporteAlcance>{_alcance},
            onSelectionChanged: (Set<ReporteAlcance> seleccion) {
              ref.read(reporteExportProvider.notifier).reset();
              setState(() => _alcance = seleccion.first);
            },
          ),
          if (_alcance == ReporteAlcance.mensual) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Mes anterior',
                      onPressed: estado.enviando
                          ? null
                          : () => _cambiarMes(-1),
                    ),
                    Text(
                      '$_periodo',
                      style: theme.textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Mes siguiente',
                      onPressed: estado.enviando ? null : () => _cambiarMes(1),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Formato', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ReporteFormato>(
            segments: const <ButtonSegment<ReporteFormato>>[
              ButtonSegment<ReporteFormato>(
                value: ReporteFormato.csv,
                label: Text('CSV'),
              ),
              ButtonSegment<ReporteFormato>(
                value: ReporteFormato.pdf,
                label: Text('PDF'),
              ),
            ],
            selected: <ReporteFormato>{_formato},
            onSelectionChanged: (Set<ReporteFormato> seleccion) {
              ref.read(reporteExportProvider.notifier).reset();
              setState(() => _formato = seleccion.first);
            },
          ),
          const SizedBox(height: 8),
          Text(
            _formato == ReporteFormato.csv
                ? 'Ideal para planillas (Excel, Google Sheets).'
                : 'Ideal para compartir o imprimir.',
            style: theme.textTheme.bodySmall,
          ),
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                failureMessage(estado.error!),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (estado.archivo != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Archivo listo: ${estado.archivo!.nombre}',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          const SizedBox(height: 24),
          if (estado.enviando)
            const LinearProgressIndicator()
          else
            FilledButton.icon(
              onPressed: _exportar,
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Exportar'),
            ),
        ],
      ),
    );
  }

  void _cambiarMes(int delta) {
    final DateTime siguiente = DateTime(
      _periodo.year,
      _periodo.month + delta,
    );
    ref.read(reporteExportProvider.notifier).reset();
    setState(() {
      _periodo = BusinessMonth(siguiente.year, siguiente.month);
    });
  }

  Future<void> _exportar() async {
    final ReporteSolicitud solicitud = ReporteSolicitud(
      alcance: _alcance,
      formato: _formato,
      periodo: _alcance == ReporteAlcance.mensual ? _periodo : null,
    );
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Rect? origen = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final failure = await ref
        .read(reporteExportProvider.notifier)
        .exportar(solicitud, origen: origen);
    if (!mounted) {
      return;
    }
    final ReporteArchivo? archivo = ref.read(reporteExportProvider).archivo;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? 'Reporte listo: ${archivo?.nombre ?? 'archivo'}'
              : failureMessage(failure),
        ),
      ),
    );
  }
}
