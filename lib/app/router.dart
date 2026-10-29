import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'home_screen.dart';

/// Nombres de ruta centralizados para evitar strings sueltos en la app.
abstract final class AppRoutes {
  static const String home = '/';
  static const String homeName = 'home';
}

/// Router de la aplicación.
///
/// Se expone como provider para que sea reemplazable en pruebas y para
/// liberar sus recursos cuando el contenedor se destruya.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (_, _) => const HomeScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);

  return router;
});
