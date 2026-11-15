import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/appearance_preference.dart';
import 'appearance_controller.dart';

/// Pantalla para comparar y seleccionar la apariencia de SaveUp.
class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final AppearancePreference selected = ref.watch(appearanceProvider);
    final Brightness systemBrightness = MediaQuery.platformBrightnessOf(
      context,
    );

    return NeoScaffold(
      appBar: NeoAppBar(
        title: 'Tema',
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          const NeoSectionHeader(title: 'Elige tu estilo'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Compara las vistas y selecciona la que prefieras. El cambio se '
            'aplica al instante y se guarda en este dispositivo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_saving) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: AppSpacing.lg),
          for (final AppearancePreference preference
              in AppearancePreference.values) ...<Widget>[
            _AppearanceOptionCard(
              key: ValueKey<String>('appearance-option-${preference.name}'),
              preference: preference,
              selected: preference == selected,
              enabled: !_saving,
              systemBrightness: systemBrightness,
              onTap: () => _select(preference),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  Future<void> _select(AppearancePreference preference) async {
    if (_saving || preference == ref.read(appearanceProvider)) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(appearanceProvider.notifier).select(preference);
    } on Exception {
      if (mounted) {
        NeoSnackbar.show(
          context,
          'No se pudo guardar el tema. Se mantiene el que ya estaba seleccionado.',
          tone: NeoSnackbarTone.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _AppearanceOptionCard extends StatelessWidget {
  const _AppearanceOptionCard({
    super.key,
    required this.preference,
    required this.selected,
    required this.enabled,
    required this.systemBrightness,
    required this.onTap,
  });

  final AppearancePreference preference;
  final bool selected;
  final bool enabled;
  final Brightness systemBrightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    final String estado = selected ? 'Seleccionado' : 'Tocar para seleccionar';
    final String detalle = preference == AppearancePreference.system
        ? 'Actualmente: ${systemBrightness == Brightness.dark ? 'oscuro' : 'claro'}'
        : preference.description;

    return Semantics(
      label: '${preference.label}. $detalle. $estado.',
      button: true,
      selected: selected,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: NeoSurface(
          color: selected ? colors.surfaceAccent : colors.surface,
          textColor: colors.ink,
          borderWidth: selected ? AppBorders.bold : AppBorders.regular,
          onTap: enabled ? onTap : null,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      preference.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (selected) ...<Widget>[
                    const NeoBadge(label: 'Seleccionado', compact: true),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? colors.primary : colors.muted,
                    semanticLabel: selected ? 'Seleccionado' : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                detalle,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AppearancePreview(
                key: ValueKey<String>('appearance-preview-${preference.name}'),
                preference: preference,
                systemBrightness: systemBrightness,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearancePreview extends StatelessWidget {
  const _AppearancePreview({
    super.key,
    required this.preference,
    required this.systemBrightness,
  });

  final AppearancePreference preference;
  final Brightness systemBrightness;

  @override
  Widget build(BuildContext context) {
    final ThemeData previewTheme = switch (preference) {
      AppearancePreference.system =>
        systemBrightness == Brightness.dark
            ? SaveUpTheme.dark()
            : SaveUpTheme.light(),
      AppearancePreference.light => SaveUpTheme.light(),
      AppearancePreference.dark => SaveUpTheme.dark(),
      AppearancePreference.bold => SaveUpTheme.bold(),
    };
    final SaveUpColors colors = previewTheme.extension<SaveUpColors>()!;

    return Theme(
      data: previewTheme,
      child: Container(
        height: 124,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.canvas,
          borderRadius: AppRadii.smAll,
          border: Border.all(color: colors.border, width: AppBorders.regular),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'SAVEUP',
                  style: AppTypography.text(
                    size: 10,
                    weight: FontWeight.w700,
                    color: colors.ink,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                Icon(Icons.more_horiz, size: 16, color: colors.ink),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: NeoSurface(
                density: AppDensity.table,
                color: colors.surface,
                textColor: colors.ink,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Resumen', style: previewTheme.textTheme.labelSmall),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        for (final Color accent in <Color>[
                          colors.primary,
                          colors.secondary,
                          colors.tertiary,
                          colors.accent,
                        ])
                          Expanded(
                            child: Container(
                              height: 16,
                              margin: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: AppRadii.smAll,
                                border: Border.all(
                                  color: colors.border,
                                  width: AppBorders.thin,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
