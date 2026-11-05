import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/url_opener.dart';
import '../domain/app_version_info.dart';
import 'app_version_controller.dart';

/// Pantalla bloqueante con `actualizacionObligatoria=true`.
///
/// No se navega a ninguna otra ruta: el router redirige here mientras el
/// estado de versión sea [AppVersionBlocked]. "Actualizar" abre `urlTienda`
/// fuera de la app.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppVersionInfo info = ref.watch(appVersionProvider).infoOrThrow();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.system_update_alt,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Actualización requerida',
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  info.mensaje,
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _openStore(context, ref, info.urlTienda),
                  child: const Text('Actualizar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(
    BuildContext context,
    WidgetRef ref,
    String url,
  ) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.isScheme('https') && !uri.isScheme('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la tienda.')),
      );
      return;
    }
    try {
      final bool opened = await ref.read(urlOpenerProvider)(uri);
      if (!opened) {
        throw StateError('No se abrió la URL.');
      }
      return;
    } on Object {
      // Sin URL externa accesible: se informa sin cerrar la pantalla
      // bloqueante.
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la tienda.')),
      );
    }
  }
}

extension on AppVersionState {
  AppVersionInfo infoOrThrow() {
    return switch (this) {
      AppVersionBlocked(:final info) => info,
      AppVersionSuggested(:final info) => info,
      AppVersionSuggestedDismissed(:final info) => info,
      // El router solo llega a esta pantalla con bloqueo vigente.
      _ => throw StateError('Versión mínima sin resolver.'),
    };
  }
}
