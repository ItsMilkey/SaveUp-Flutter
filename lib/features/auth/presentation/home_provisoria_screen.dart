import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
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
            : Text(
                'Hola, ${user.fullName}',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
      ),
    );
  }
}
