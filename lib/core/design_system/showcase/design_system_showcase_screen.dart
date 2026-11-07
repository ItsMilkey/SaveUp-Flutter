import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../design_system.dart';

/// Galería interna (solo debug) para revisar tokens y átomos.
class DesignSystemShowcaseScreen extends StatefulWidget {
  const DesignSystemShowcaseScreen({super.key});

  @override
  State<DesignSystemShowcaseScreen> createState() =>
      _DesignSystemShowcaseScreenState();
}

class _DesignSystemShowcaseScreenState
    extends State<DesignSystemShowcaseScreen> {
  bool _dark = false;
  String _segment = 'Semana';
  DateTime _periodo = DateTime(2026, 11);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _dark ? SaveUpTheme.dark() : SaveUpTheme.light(),
      child: Builder(
        builder: (BuildContext context) {
          final ThemeData theme = Theme.of(context);
          return Scaffold(
            appBar: AppBar(
              title: const Text('Design System'),
              actions: <Widget>[
                Switch(
                  value: _dark,
                  onChanged: (bool value) => setState(() => _dark = value),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
                Text(
                  'SaveUp Design System',
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Neo-brutalismo modular: tokens → theme → átomos.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                _section(
                  context,
                  'Paleta',
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: const <Widget>[
                      _Swatch('Ink', AppColors.ink),
                      _Swatch('Paper', AppColors.paper),
                      _Swatch('Canvas', AppColors.canvas),
                      _Swatch('Yellow', AppColors.yellow),
                      _Swatch('Cyan', AppColors.cyan),
                      _Swatch('Magenta', AppColors.magenta),
                      _Swatch('Orange', AppColors.orange),
                      _Swatch('Green', AppColors.green),
                      _Swatch('Lavender', AppColors.lavender),
                      _Swatch('Danger', AppColors.danger),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Tipografía',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Display Archivo Black',
                        style: theme.textTheme.displaySmall,
                      ),
                      Text(
                        'Headline Space Grotesk',
                        style: theme.textTheme.headlineMedium,
                      ),
                      Text('Title', style: theme.textTheme.titleLarge),
                      Text(
                        'Body: texto de apoyo para explicar una acción.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'LABEL / METADATA',
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Botones',
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: <Widget>[
                      NeoButton(
                        label: 'Primario',
                        icon: Icons.add,
                        onPressed: () {},
                      ),
                      NeoButton(
                        label: 'Secundario',
                        variant: NeoButtonVariant.secondary,
                        onPressed: () {},
                      ),
                      NeoButton(
                        label: 'Ghost',
                        variant: NeoButtonVariant.ghost,
                        onPressed: () {},
                      ),
                      NeoButton(
                        label: 'Eliminar',
                        variant: NeoButtonVariant.danger,
                        onPressed: () {},
                      ),
                      const NeoButton(
                        label: 'Deshabilitado',
                        onPressed: null,
                      ),
                      const NeoButton(
                        label: 'Cargando',
                        loading: true,
                        onPressed: null,
                      ),
                      const NeoButton(
                        label: 'Ancho',
                        expanded: true,
                        onPressed: _noop,
                      ),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Icon buttons',
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: <Widget>[
                      NeoIconButton(
                        icon: Icons.add,
                        tooltip: 'Agregar',
                        onPressed: () {},
                      ),
                      NeoIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: 'Editar',
                        variant: NeoIconButtonVariant.secondary,
                        onPressed: () {},
                      ),
                      NeoIconButton(
                        icon: Icons.more_horiz,
                        tooltip: 'Más',
                        variant: NeoIconButtonVariant.ghost,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Inputs',
                  Column(
                    children: <Widget>[
                      const NeoInput(
                        label: 'Nombre',
                        hint: 'Ej. Viaje a Japón',
                        prefixIcon: Icons.label_outline,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const NeoInput(
                        label: 'Monto',
                        hint: r'$ 0',
                        helper: 'Máximo 13 enteros y 2 decimales.',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const NeoInput(
                        label: 'Con error',
                        error: 'Ingresa un monto válido.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const NeoInput(
                        label: 'Deshabilitado',
                        enabled: false,
                      ),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Badges y progreso',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: const <Widget>[
                          NeoBadge(label: 'Necesidad'),
                          NeoBadge(
                            label: 'Deseo',
                            color: AppColors.magenta,
                          ),
                          NeoBadge(
                            label: 'Cerca del plan',
                            color: AppColors.cyan,
                            icon: Icons.trending_up,
                          ),
                          NeoBadge(
                            label: 'Sobre el plan',
                            color: AppColors.danger,
                            icon: Icons.warning_amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const NeoProgress(
                        value: 0.72,
                        label: 'Ahorro · 72 %',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const NeoProgress(
                        value: 1,
                        color: AppColors.green,
                        label: 'Meta cumplida',
                      ),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Segmentado',
                  NeoSegmented<String>(
                    values: const <String>['Día', 'Semana', 'Mes'],
                    labels: const <String>['Día', 'Semana', 'Mes'],
                    selected: _segment,
                    onChanged: (String value) =>
                        setState(() => _segment = value),
                  ),
                ),
                _section(
                  context,
                  'Tarjetas y densidad',
                  Column(
                    children: <Widget>[
                      NeoCard(
                        density: AppDensity.hero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Hero / saldo',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              r'$1.234.567',
                              style: theme.textTheme.displaySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NeoCard(
                        child: const Text(
                          'Section / formulario o tarjeta de detalle.',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NeoCard(
                        density: AppDensity.list,
                        child: const Text(
                          'List / movimiento o deuda.',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NeoCard(
                        density: AppDensity.table,
                        child: const Text(
                          'Table / leyenda de gráfico o fila densa.',
                        ),
                      ),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Dinero y stat',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      NeoMoneyText(
                        amount: Decimal.fromInt(1234567),
                        size: NeoMoneySize.display,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        children: <Widget>[
                          NeoMoneyText(
                            amount: Decimal.fromInt(25000),
                            tone: NeoMoneyTone.income,
                            signed: true,
                          ),
                          NeoMoneyText(
                            amount: Decimal.fromInt(-25000),
                            tone: NeoMoneyTone.expense,
                          ),
                          NeoMoneyText(
                            amount: Decimal.fromInt(120000),
                            tone: NeoMoneyTone.savings,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: NeoStat(
                              label: 'Ingresos',
                              icon: Icons.trending_up,
                              value: NeoMoneyText(
                                amount: Decimal.fromInt(1234567),
                                size: NeoMoneySize.headline,
                                tone: NeoMoneyTone.income,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: NeoStat(
                              label: 'Gastos',
                              icon: Icons.trending_down,
                              value: NeoMoneyText(
                                amount: Decimal.fromInt(456789),
                                size: NeoMoneySize.headline,
                                tone: NeoMoneyTone.expense,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _section(
                  context,
                  'List item y encabezado',
                  Column(
                    children: <Widget>[
                      const NeoSectionHeader(
                        title: 'Movimientos',
                        subtitle: 'Últimos del mes',
                        action: Text('Ver todo'),
                      ),
                      NeoListItem(
                        leading: const Icon(Icons.shopping_bag_outlined),
                        title: 'Supermercado',
                        subtitle: 'Alimentación · Hoy',
                        trailing: NeoMoneyText(
                          amount: Decimal.fromInt(-25000),
                          tone: NeoMoneyTone.expense,
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Estados',
                  Column(
                    children: <Widget>[
                      const NeoErrorState(
                        message: 'No se pudieron cargar los datos.',
                        onRetry: _noop,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const NeoLoading(rows: 2),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Patrones',
                  Column(
                    children: <Widget>[
                      NeoMonthPicker(
                        label: _mesLabel(_periodo),
                        onPrevious: () => _moverMes(-1),
                        onNext: () => _moverMes(1),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NeoChartCard(
                        title: 'Gastos por mes',
                        subtitle: 'Últimos 6 meses',
                        legend: const Wrap(
                          spacing: 8,
                          children: <Widget>[
                            NeoBadge(label: 'Gastos', color: AppColors.orange),
                            NeoBadge(label: 'Ahorro', color: AppColors.green),
                          ],
                        ),
                        child: SizedBox(
                          height: 120,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              for (int i = 0; i < 6; i++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Container(
                                      height: 40.0 + (i * 12),
                                      decoration: BoxDecoration(
                                        color: i.isEven
                                            ? AppColors.orange
                                            : AppColors.green,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(AppRadii.sm),
                                        ),
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).extension<SaveUpColors>()!.border,
                                          width: AppBorders.regular,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Diálogos y snackbar',
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: <Widget>[
                      NeoButton(
                        label: 'Abrir diálogo',
                        variant: NeoButtonVariant.secondary,
                        onPressed: () => NeoDialog.show<void>(
                          context,
                          title: 'Título del diálogo',
                          child: const Text('Contenido de ejemplo.'),
                          actions: <Widget>[
                            NeoButton(
                              label: 'Cerrar',
                              variant: NeoButtonVariant.secondary,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      NeoButton(
                        label: 'Confirmar',
                        onPressed: () => _confirmar(context),
                      ),
                      NeoButton(
                        label: 'Snack success',
                        variant: NeoButtonVariant.secondary,
                        onPressed: () => NeoSnackbar.show(
                          context,
                          'Guardado correctamente.',
                          tone: NeoSnackbarTone.success,
                        ),
                      ),
                      NeoButton(
                        label: 'Snack error',
                        variant: NeoButtonVariant.secondary,
                        onPressed: () => NeoSnackbar.show(
                          context,
                          'No se pudo guardar.',
                          tone: NeoSnackbarTone.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _mesLabel(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  void _moverMes(int delta) {
    setState(() {
      _periodo = DateTime(_periodo.year, _periodo.month + delta);
    });
  }

  Future<void> _confirmar(BuildContext context) async {
    final bool? confirmado = await NeoConfirmDialog.show(
      context,
      title: '¿Eliminar meta?',
      message: 'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!mounted || !context.mounted) {
      return;
    }
    NeoSnackbar.show(
      context,
      confirmado == true ? 'Confirmado.' : 'Cancelado.',
      tone: confirmado == true
          ? NeoSnackbarTone.success
          : NeoSnackbarTone.neutral,
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Container(
          width: 72,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadii.smAll,
            border: Border.all(
              color: theme.extension<SaveUpColors>()!.border,
              width: AppBorders.regular,
            ),
            boxShadow: theme
                .extension<SaveUpShadows>()!
                .forLevel(AppShadowLevel.sm),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

void _noop() {}
