import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../domain/regla_presupuestaria.dart';
import '../controllers/asignaciones_presupuesto_controller.dart';
import '../controllers/regla_presupuestaria_controller.dart';
import '../widgets/distribucion_ahorro_section.dart';

/// Configuración de la regla 50/30/20 (necesidades/deseos/ahorro).
class ConfiguracionReglaScreen extends ConsumerStatefulWidget {
  const ConfiguracionReglaScreen({super.key});

  @override
  ConsumerState<ConfiguracionReglaScreen> createState() =>
      _ConfiguracionReglaScreenState();
}

class _ConfiguracionReglaScreenState
    extends ConsumerState<ConfiguracionReglaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(reglaPresupuestariaProvider.notifier).cargar();
        ref.read(asignacionesPresupuestoProvider.notifier).cargar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ReglaPresupuestariaState estado = ref.watch(
      reglaPresupuestariaProvider,
    );
    final ReglaPresupuestariaController controller = ref.read(
      reglaPresupuestariaProvider.notifier,
    );
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final TextTheme onColorText = theme.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return NeoScaffold(
      appBar: NeoAppBar(
        title: 'Presupuesto',
        actions: <Widget>[
          NeoIconButton(
            icon: Icons.bar_chart_outlined,
            tooltip: 'Ejecución e historial',
            variant: NeoIconButtonVariant.ghost,
            onPressed: () => context.push(AppRoutes.presupuestoEjecucion),
          ),
          NeoIconButton(
            icon: Icons.category_outlined,
            tooltip: 'Límites y tipos',
            variant: NeoIconButtonVariant.ghost,
            onPressed: () => context.push(AppRoutes.presupuestoCategorias),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: estado.cargando
          ? const NeoLoading(rows: 3)
          : estado.errorCarga != null && estado.config == null
          ? NeoErrorState(
              message: failureMessage(estado.errorCarga!),
              onRetry: controller.cargar,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl * 2,
              ),
              children: <Widget>[
                _Sugerencia(estado: estado, onAplicar: controller.aplicarSugerencia),
                const SizedBox(height: AppSpacing.lg),
                NeoSurface(
                  density: AppDensity.section,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const NeoSectionHeader(
                        title: 'Regla mensual',
                        subtitle:
                            'Cómo repartes tu ingreso. Al mover un slider, '
                            'los otros se ajustan para sumar 100.00.',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _SliderRegla(
                        label: 'Necesidades',
                        valor: estado.necesidades,
                        color: AppColors.cyan,
                        onChanged: controller.setNecesidades,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SliderRegla(
                        label: 'Deseos',
                        valor: estado.deseos,
                        color: AppColors.magenta,
                        onChanged: controller.setDeseos,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SliderRegla(
                        label: 'Ahorro',
                        valor: estado.ahorro,
                        color: AppColors.green,
                        onChanged: controller.setAhorro,
                      ),
                      const Divider(),
                      Row(
                        children: <Widget>[
                          Icon(
                            estado.sumaValida
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            size: 18,
                            color: estado.sumaValida
                                ? colors.positiveText
                                : colors.negativeText,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Suma: ${estado.suma} %',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: estado.sumaValida
                                    ? colors.positiveText
                                    : colors.negativeText,
                              ),
                            ),
                          ),
                          Text(
                            estado.sumaValida
                                ? 'Lista para guardar'
                                : 'Debe ser 100.00',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: estado.sumaValida
                                  ? colors.positiveText
                                  : colors.negativeText,
                            ),
                          ),
                        ],
                      ),
                      if (estado.mensajeValidacion != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            estado.mensajeValidacion!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                NeoSurface(
                  density: AppDensity.list,
                  color: AppColors.cyan,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: <Widget>[
                        SwitchListTile(
                          title: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Presupuesto activo',
                                  style: onColorText.titleMedium,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _mostrarInfo(
                                  context,
                                  titulo: 'Presupuesto activo',
                                  mensaje:
                                      'Es el interruptor maestro de tu regla '
                                      '50/30/20. Si está activo, el '
                                      'presupuesto se aplica al registrar '
                                      'ingresos; si lo apagas, la '
                                      'configuración se conserva como '
                                      'referencia pero no se ejecuta.',
                                ),
                                tooltip:
                                    'Información sobre Presupuesto activo',
                                icon: const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                ),
                                color: AppColors.ink,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 40,
                                  height: 40,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          value: estado.activo,
                          onChanged: controller.setActivo,
                        ),
                        SwitchListTile(
                          title: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Automatizar ahorro en metas',
                                  style: onColorText.titleMedium,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _mostrarInfo(
                                  context,
                                  titulo: 'Automatizar ahorro en metas',
                                  mensaje:
                                      'Con el presupuesto activo, el '
                                      'porcentaje de Ahorro se reparte '
                                      'automáticamente entre las metas de la '
                                      'Distribución del ahorro. Si está '
                                      'apagado, el ahorro queda disponible en '
                                      'tu saldo principal y no se abonan '
                                      'metas.',
                                ),
                                tooltip:
                                    'Información sobre Automatizar ahorro en '
                                    'metas',
                                icon: const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                ),
                                color: AppColors.ink,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 40,
                                  height: 40,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Reparte el ahorro automático entre tus metas.',
                            style: onColorText.bodySmall?.copyWith(
                              color: AppColors.ink.withValues(alpha: 0.7),
                            ),
                          ),
                          value: estado.automatizarAhorroEnMetas,
                          onChanged: controller.setAutomatizarAhorroEnMetas,
                        ),
                      ],
                    ),
                  ),
                ),
                if (estado.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: NeoErrorBand(
                      message: failureMessage(estado.error!),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                DistribucionAhorroSection(
                  automatizarAhorroEnMetas: estado.automatizarAhorroEnMetas,
                ),
                if (estado.guardado)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
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
                          Text(
                            'Regla guardada.',
                            style: AppTypography.text(
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (estado.guardando)
                  const LinearProgressIndicator()
                else
                  NeoButton(
                    label: 'Guardar regla',
                    expanded: true,
                    onPressed: estado.sumaValida
                        ? () => _guardar(controller)
                        : null,
                  ),
              ],
            ),
    );
  }

  Future<void> _guardar(ReglaPresupuestariaController controller) {
    final AsignacionesPresupuestoState asignaciones = ref.read(
      asignacionesPresupuestoProvider,
    );
    return controller.guardar(
      asignaciones: asignaciones.cargadas ? asignaciones.datos : null,
    );
  }

  Future<void> _mostrarInfo(
    BuildContext context, {
    required String titulo,
    required String mensaje,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => NeoDialog(
        title: titulo,
        actions: <Widget>[
          NeoButton(
            label: 'Entendido',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
        child: Text(
          mensaje,
          style: Theme.of(dialogContext).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _Sugerencia extends StatelessWidget {
  const _Sugerencia({required this.estado, required this.onAplicar});

  final ReglaPresupuestariaState estado;
  final VoidCallback onAplicar;

  @override
  Widget build(BuildContext context) {
    final SugerenciaRegla? sugerencia = estado.sugerencia;
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    final PorcentajesRegla? propuesta = sugerencia?.sugerencia;

    if (propuesta == null) {
      return NeoSurface(
        density: AppDensity.section,
        color: AppColors.lavender,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const NeoSectionHeader(title: 'Sugerencia'),
            Text(
              sugerencia?.motivo == 'DATOS_INSUFICIENTES'
                  ? 'Aún no hay suficientes meses de historial para sugerir '
                        'una regla. Puedes configurarla manualmente.'
                  : 'No hay una sugerencia disponible; configura tu regla '
                        'manualmente.',
              style: textTheme.bodySmall,
            ),
            if (sugerencia != null &&
                sugerencia.mesesAnalizados.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Meses analizados: ${sugerencia.mesesAnalizados.join(', ')}',
                style: textTheme.bodySmall,
              ),
            ],
          ],
        ),
      );
    }

    return NeoSurface(
      density: AppDensity.section,
      color: AppColors.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NeoSectionHeader(title: 'Sugerencia para ti'),
          Text(
            '${propuesta.necesidades} / ${propuesta.deseos} / '
            '${propuesta.ahorro} · meses: '
            '${sugerencia!.mesesAnalizados.join(', ')}',
            style: textTheme.bodyMedium,
          ),
          if (sugerencia.gastoSuperaIngreso)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Tu gasto de necesidades y deseos supera tus ingresos; la '
                'sugerencia se escaló para sumar 100.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAplicar,
              child: const Text('Aplicar sugerencia'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRegla extends StatelessWidget {
  const _SliderRegla({
    required this.label,
    required this.valor,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final Decimal valor;
  final Color color;
  final ValueChanged<Decimal> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: colors.border,
                  width: AppBorders.thin,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Tooltip(
              message: 'Editar $label',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _editarPorcentaje(context),
                  borderRadius: AppRadii.smAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: AppRadii.smAll,
                      border: Border.all(
                        color: colors.border,
                        width: AppBorders.thin,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '$valor %',
                          style: AppTypography.text(
                            size: 16,
                            weight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: colors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: AppColors.ink,
            inactiveTrackColor: AppColors.ink.withValues(alpha: 0.12),
            thumbColor: AppColors.ink,
            overlayColor: AppColors.ink.withValues(alpha: 0.12),
            valueIndicatorColor: AppColors.ink,
            valueIndicatorTextStyle: AppTypography.text(
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.canvas,
            ),
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
          ),
          child: Slider(
            value: valor.toDouble().clamp(0, 100),
            max: 100,
            divisions: 200,
            label: '$valor %',
            onChanged: (double value) => onChanged(
              Decimal.parse(value.toStringAsFixed(2)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editarPorcentaje(BuildContext context) async {
    final Decimal? nuevo = await _PorcentajeDialog.show(
      context,
      label: label,
      actual: valor,
    );
    if (nuevo != null) {
      onChanged(nuevo);
    }
  }
}

class _PorcentajeDialog extends StatefulWidget {
  const _PorcentajeDialog({required this.label, required this.actual});

  final String label;
  final Decimal actual;

  static Future<Decimal?> show(
    BuildContext context, {
    required String label,
    required Decimal actual,
  }) {
    return showDialog<Decimal>(
      context: context,
      builder: (_) => _PorcentajeDialog(label: label, actual: actual),
    );
  }

  @override
  State<_PorcentajeDialog> createState() => _PorcentajeDialogState();
}

class _PorcentajeDialogState extends State<_PorcentajeDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.actual.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Decimal? _parsear(String raw) {
    final String text = raw.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d{1,3}(\.\d{1,2})?$').hasMatch(text)) {
      return null;
    }
    final Decimal valor = Decimal.parse(text);
    if (valor < Decimal.zero || valor > Decimal.fromInt(100)) {
      return null;
    }
    return valor;
  }

  String? _validar(String? raw) {
    final String text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresa el porcentaje.';
    }
    if (_parsear(text) == null) {
      return 'Entre 0 y 100, con hasta 2 decimales.';
    }
    return null;
  }

  void _aplicar() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(_parsear(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return NeoDialog(
      title: 'Editar ${widget.label}',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        NeoButton(label: 'Aplicar', onPressed: _aplicar),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'El resto se reparte entre los otros dos bloques para sumar '
              '100.00.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            NeoInput(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validar,
              label: 'Porcentaje',
              helper: 'Entre 0 y 100, hasta 2 decimales.',
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(widthFactor: 1, child: Text('%')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
