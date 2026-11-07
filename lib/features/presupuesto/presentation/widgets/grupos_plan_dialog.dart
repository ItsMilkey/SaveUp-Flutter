import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../domain/plan_mensual.dart';
import '../controllers/grupos_plan_controller.dart';

/// Gestión básica de grupos del plan (crear, renombrar, eliminar).
class GruposPlanDialog extends ConsumerWidget {
  const GruposPlanDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<GrupoPlan>> grupos = ref.watch(gruposPlanProvider);

    return NeoDialog(
      title: 'Grupos del plan',
      actions: <Widget>[
        NeoButton(
          label: 'Cerrar',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: SizedBox(
        width: 420,
        height: 380,
        child: grupos.when(
          loading: () => const NeoLoading(rows: 2),
          error: (Object error, StackTrace stack) => NeoErrorState(
            message: error is AppFailure
                ? failureMessage(error)
                : 'No se pudieron cargar los grupos.',
            onRetry: () => ref.read(gruposPlanProvider.notifier).refrescar(),
          ),
          data: (List<GrupoPlan> lista) => Material(
            type: MaterialType.transparency,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: lista.isEmpty
                      ? const Center(
                          child: Text('Todavía no hay grupos.'),
                        )
                      : ListView.separated(
                          itemCount: lista.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (BuildContext context, int index) {
                            final GrupoPlan grupo = lista[index];
                            return NeoListItem(
                              density: AppDensity.list,
                              title: grupo.nombre,
                              subtitle: 'Orden ${grupo.orden}',
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  NeoIconButton(
                                    icon: Icons.edit_outlined,
                                    tooltip: 'Renombrar',
                                    variant: NeoIconButtonVariant.ghost,
                                    onPressed: () =>
                                        _editar(context, ref, grupo),
                                  ),
                                  NeoIconButton(
                                    icon: Icons.delete_outline,
                                    tooltip: 'Eliminar grupo',
                                    variant: NeoIconButtonVariant.ghost,
                                    onPressed: () =>
                                        _eliminar(context, ref, grupo),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: NeoButton(
                    icon: Icons.add,
                    label: 'Nuevo grupo',
                    variant: NeoButtonVariant.secondary,
                    onPressed: () => _crear(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _crear(BuildContext context, WidgetRef ref) async {
    final String? nombre = await _pedirNombre(context, titulo: 'Nuevo grupo');
    if (nombre == null) {
      return;
    }
    final AppFailure? failure = await ref
        .read(gruposPlanProvider.notifier)
        .crear(nombre);
    if (!context.mounted) {
      return;
    }
    _mostrarFalla(context, failure);
  }

  Future<void> _editar(
    BuildContext context,
    WidgetRef ref,
    GrupoPlan grupo,
  ) async {
    final String? nombre = await _pedirNombre(
      context,
      titulo: 'Renombrar grupo',
      inicial: grupo.nombre,
    );
    if (nombre == null) {
      return;
    }
    final AppFailure? failure = await ref
        .read(gruposPlanProvider.notifier)
        .editar(grupo.id, nombre: nombre);
    if (!context.mounted) {
      return;
    }
    _mostrarFalla(context, failure);
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    GrupoPlan grupo,
  ) async {
    final bool? confirmado = await NeoConfirmDialog.show(
      context,
      title: '¿Eliminar «${grupo.nombre}»?',
      message: 'Las partidas del grupo quedarán sin grupo (no se borran).',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (confirmado != true) {
      return;
    }
    final AppFailure? failure = await ref
        .read(gruposPlanProvider.notifier)
        .eliminar(grupo.id);
    if (!context.mounted) {
      return;
    }
    _mostrarFalla(context, failure);
  }

  Future<String?> _pedirNombre(
    BuildContext context, {
    required String titulo,
    String? inicial,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: inicial ?? '',
    );
    final String? resultado = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => NeoDialog(
        title: titulo,
        actions: <Widget>[
          NeoButton(
            label: 'Cancelar',
            variant: NeoButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          NeoButton(
            label: 'Guardar',
            onPressed: () {
              final String valor = controller.text.trim();
              if (valor.isEmpty) {
                return;
              }
              Navigator.of(dialogContext).pop(valor);
            },
          ),
        ],
        child: NeoInput(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          label: 'Nombre',
          helper: 'Entre 1 y 60 caracteres',
        ),
      ),
    );
    // El diálogo interno sigue en su animación de salida cuando `showDialog`
    // resuelve; liberar el controller en el siguiente frame evita usarlo
    // mientras el TextField aún está montado.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.dispose(),
    );
    return resultado;
  }
  void _mostrarFalla(BuildContext context, AppFailure? failure) {
    if (failure == null) {
      return;
    }
    NeoSnackbar.show(
      context,
      failureMessage(failure),
      tone: NeoSnackbarTone.danger,
    );
  }
}
