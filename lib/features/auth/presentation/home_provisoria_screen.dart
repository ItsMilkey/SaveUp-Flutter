import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config.dart';
import '../../../app/routes.dart';
import '../../account/presentation/eliminar_cuenta_dialog.dart';
import '../domain/auth_session.dart';
import '../domain/user_profile.dart';
import 'auth_controllers.dart';

/// Pantalla provisoria del usuario autenticado: su nombre y "Cerrar sesión".
///
/// Se reemplaza por la pantalla real (dashboard / navegación) en F3; por eso
/// vive en `lib/features/auth/presentation` y no en `lib/app`.
class HomeProvisoriaScreen extends ConsumerWidget {
  const HomeProvisoriaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthSession session = ref.watch(authSessionProvider);
    final UserProfile? user = switch (session) {
      SessionAuthenticated(:final UserProfile user) => user,
      _ => null,
    };
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authSessionProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: user == null
            ? const CircularProgressIndicator.adaptive()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Hola, ${user.fullName}',
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => GoRouter.of(
                      context,
                    ).push(AppRoutes.cambiarContrasena),
                    child: const Text('Cambiar contraseña'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => EliminarCuentaDialog.show(context),
                    child: const Text('Eliminar cuenta'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => GoRouter.of(context).push(AppRoutes.legales),
                    child: const Text('Términos y privacidad'),
                  ),
                ],
              ),
      ),
    );
  }
}
