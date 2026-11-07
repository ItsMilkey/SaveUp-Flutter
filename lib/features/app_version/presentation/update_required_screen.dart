import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/url_opener.dart';
import '../../../core/design_system/design_system.dart';
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
      child: NeoScaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: NeoSurface(
                density: AppDensity.hero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: AppRadii.mdAll,
                        border: Border.all(
                          color: Theme.of(context)
                              .extension<SaveUpColors>()!
                              .border,
                          width: AppBorders.regular,
                        ),
                      ),
                      child: const Icon(
                        Icons.system_update_alt,
                        size: 32,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Actualización requerida',
                      style: textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      info.mensaje,
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    NeoButton(
                      label: 'Actualizar',
                      icon: Icons.open_in_new,
                      expanded: true,
                      onPressed: () => _openStore(context, ref, info.urlTienda),
                    ),
                  ],
                ),
              ),
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
      NeoSnackbar.show(
        context,
        'No se pudo abrir la tienda.',
        tone: NeoSnackbarTone.danger,
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
      NeoSnackbar.show(
        context,
        'No se pudo abrir la tienda.',
        tone: NeoSnackbarTone.danger,
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
