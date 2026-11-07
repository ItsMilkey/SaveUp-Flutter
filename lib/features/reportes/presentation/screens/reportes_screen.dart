import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
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

    return NeoScaffold(
      appBar: const NeoAppBar(title: 'Reportes'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Text(
            'Descarga tus movimientos y compártelos desde el móvil.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          const NeoSectionHeader(title: 'Alcance'),
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
            const SizedBox(height: AppSpacing.md),
            NeoSurface(
              density: AppDensity.list,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  NeoIconButton(
                    icon: Icons.chevron_left,
                    tooltip: 'Mes anterior',
                    variant: NeoIconButtonVariant.ghost,
                    onPressed: estado.enviando
                        ? null
                        : () => _cambiarMes(-1),
                  ),
                  Text(
                    '$_periodo',
                    style: theme.textTheme.titleMedium,
                  ),
                  NeoIconButton(
                    icon: Icons.chevron_right,
                    tooltip: 'Mes siguiente',
                    variant: NeoIconButtonVariant.ghost,
                    onPressed: estado.enviando ? null : () => _cambiarMes(1),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          const NeoSectionHeader(title: 'Formato'),
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            _formato == ReporteFormato.csv
                ? 'Ideal para planillas (Excel, Google Sheets).'
                : 'Ideal para compartir o imprimir.',
            style: theme.textTheme.bodySmall,
          ),
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: NeoErrorBand(message: failureMessage(estado.error!)),
            ),
          if (estado.archivo != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: NeoSurface(
                density: AppDensity.table,
                color: theme.extension<SaveUpColors>()!.success,
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Archivo listo: ${estado.archivo!.nombre}',
                        style: AppTypography.text(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          if (estado.enviando)
            const LinearProgressIndicator()
          else
            NeoButton(
              onPressed: _exportar,
              icon: Icons.file_download_outlined,
              label: 'Exportar',
              expanded: true,
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
    NeoSnackbar.show(
      context,
      failure == null
          ? 'Reporte listo: ${archivo?.nombre ?? 'archivo'}'
          : failureMessage(failure),
      tone: failure == null
          ? NeoSnackbarTone.success
          : NeoSnackbarTone.danger,
    );
  }
}
