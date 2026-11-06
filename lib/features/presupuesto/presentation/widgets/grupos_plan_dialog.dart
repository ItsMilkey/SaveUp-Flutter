import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return AlertDialog(
      title: const Text('Grupos del plan'),
      content: SizedBox(
        width: 420,
        height: 380,
        child: grupos.when(
          loading: () => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          error: (Object error, StackTrace stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  error is AppFailure
                      ? failureMessage(error)
                      : 'No se pudieron cargar los grupos.',
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(gruposPlanProvider.notifier).refrescar(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
          data: (List<GrupoPlan> lista) => Column(
            children: <Widget>[
              Expanded(
                child: lista.isEmpty
                    ? const Center(
                        child: Text('Todavía no hay grupos.'),
                      )
                    : ListView.builder(
                        itemCount: lista.length,
                        itemBuilder: (BuildContext context, int index) {
                          final GrupoPlan grupo = lista[index];
                          return ListTile(
                            dense: true,
                            title: Text(grupo.nombre),
                            subtitle: Text('Orden ${grupo.orden}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Renombrar',
                                  onPressed: () => _editar(context, ref, grupo),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Eliminar grupo',
                                  onPressed: () => _eliminar(context, ref, grupo),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo grupo'),
                  onPressed: () => _crear(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
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
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('¿Eliminar «${grupo.nombre}»?'),
        content: const Text(
          'Las partidas del grupo quedarán sin grupo (no se borran).',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
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
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            helperText: 'Entre 1 y 60 caracteres',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final String valor = controller.text.trim();
              if (valor.isEmpty) {
                return;
              }
              Navigator.of(dialogContext).pop(valor);
            },
            child: const Text('Guardar'),
          ),
        ],
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failureMessage(failure))));
  }
}
