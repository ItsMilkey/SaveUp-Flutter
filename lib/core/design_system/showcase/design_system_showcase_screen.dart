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
              ],
            ),
          );
        },
      ),
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
