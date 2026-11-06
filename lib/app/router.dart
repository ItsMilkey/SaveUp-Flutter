import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/presentation/cambiar_contrasena_screen.dart';
import '../features/account/presentation/legales_screen.dart';
import '../features/account/presentation/recuperacion_screens.dart';
import '../features/app_version/presentation/app_version_controller.dart';
import '../features/app_version/presentation/update_required_screen.dart';
import '../features/auth/presentation/auth_controllers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/deudas/presentation/detalle_deuda_screen.dart';
import '../features/deudas/presentation/deuda_form_screen.dart';
import '../features/deudas/presentation/deudas_screen.dart';
import '../features/deudas/presentation/simulador_screen.dart';
import '../features/deudas/domain/deuda.dart';
import '../features/presupuesto/presentation/screens/plan_screen.dart';
import '../features/movimientos/presentation/movimientos_screen.dart';
import '../features/movimientos/presentation/movimiento_form_screen.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/movimientos/domain/movimiento.dart';
import '../core/network/session_events.dart';
import 'routes.dart';

/// Router de la aplicación con redirección según sesión y versión.
///
/// - Sin versión de sesión (`unknown`): splash en `/`.
/// - Actualización obligatoria: solo `/actualizacion`.
/// - Sin sesión: `/login` y `/registro`; las privadas vuelven a `/login`.
/// - Con sesión: `/home`.
///
/// Se expone como provider para que sea reemplazable en pruebas y para
/// liberar sus recursos cuando el contenedor se destruya.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) => redirectLogic(ref, state),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.actualizacion,
        name: 'actualizacion',
        builder: (_, _) => const UpdateRequiredScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registro,
        name: 'registro',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (_, _) => const MovimientosScreen(),
      ),
      GoRoute(
        path: AppRoutes.cambiarContrasena,
        name: 'cambiarContrasena',
        builder: (_, _) => const CambiarContrasenaScreen(),
      ),
      GoRoute(
        path: AppRoutes.recuperarContrasena,
        name: 'recuperarContrasena',
        builder: (_, _) => const SolicitarRecuperacionScreen(),
      ),
      GoRoute(
        path: AppRoutes.restablecerContrasena,
        name: 'restablecerContrasena',
        builder: (_, _) => const RestablecerContrasenaScreen(),
      ),
      GoRoute(
        path: AppRoutes.legales,
        name: 'legales',
        builder: (_, _) => const LegalesScreen(),
      ),
      GoRoute(
        path: AppRoutes.nuevoMovimiento,
        name: 'nuevoMovimiento',
        builder: (_, _) => const MovimientoFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.editarMovimiento,
        name: 'editarMovimiento',
        builder: (_, GoRouterState state) {
          final Object? extra = state.extra;
          return extra is Movimiento
              ? MovimientoFormScreen(movimiento: extra)
              : const MovimientosScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.deudas,
        name: 'deudas',
        builder: (_, _) => const DeudasScreen(),
      ),
      GoRoute(
        path: AppRoutes.nuevaDeuda,
        name: 'nuevaDeuda',
        builder: (_, _) => const DeudaFormScreen(),
      ),
      GoRoute(
        path: '/deudas/:id/editar',
        name: 'editarDeuda',
        builder: (_, GoRouterState state) {
          final Object? extra = state.extra;
          return extra is Deuda
              ? DeudaFormScreen(deuda: extra)
              : const DeudasScreen();
        },
      ),
      GoRoute(
        path: '/deudas/:id',
        name: 'deudaDetalle',
        builder: (_, GoRouterState state) => DeudaDetalleScreen(
          id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.simulador,
        name: 'simulador',
        builder: (_, _) => const SimuladorScreen(),
      ),
      GoRoute(
        path: AppRoutes.plan,
        name: 'plan',
        builder: (_, _) => const PlanScreen(),
      ),
    ],
  );

  // La sesión puede vencer en cualquier momento (401 no recuperable): el
  // interceptor ya borró los tokens; aquí se navega al login con aviso.
  final StreamSubscription<SessionEvent> expiredSub = ref
      .watch(sessionEventsProvider)
      .events
      .listen((SessionEvent event) {
        ref.read(authSessionProvider.notifier).markSessionExpired();
      });
  ref.onDispose(() => unawaited(expiredSub.cancel()));

  // Redibujar el router cuando cambian sesión o versión.
  ref.listen(authSessionProvider, (_, _) => router.refresh());
  ref.listen(appVersionProvider, (_, _) => router.refresh());

  ref.onDispose(router.dispose);

  return router;
});

/// Decide la ruta según el estado global.
String? redirectLogic(Ref ref, GoRouterState state) {
  final String location = state.matchedLocation;
  final AppVersionState version = ref.read(appVersionProvider);

  // Versión mínima: bloquea todo lo que no sea actualizar.
  if (version is AppVersionBlocked) {
    return location == AppRoutes.actualizacion ? null : AppRoutes.actualizacion;
  }
  if (location == AppRoutes.actualizacion) {
    return AppRoutes.splash;
  }

  final AuthSession session = ref.read(authSessionProvider);
  if (session is SessionUnknown) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  /// Sin sesión: login, registro, recuperación y restablecimiento (el visor
  /// de legales es público también, pero accesible además CON sesión;ver
  /// `esPublico` más abajo).
  final bool isAuthRoute =
      location == AppRoutes.login ||
      location == AppRoutes.registro ||
      location == AppRoutes.recuperarContrasena ||
      location == AppRoutes.restablecerContrasena;

  /// Rutas navegables sin sesión, incluidas las que también sirven con ella.
  final bool esPublico = isAuthRoute || location == AppRoutes.legales;

  if (session is SessionUnauthenticated) {
    if (location == AppRoutes.splash || location == AppRoutes.home) {
      return AppRoutes.login;
    }
    return esPublico ? null : AppRoutes.login;
  }

  // SessionAuthenticated: la sesión sigue válida; las rutas de acceso no
  // tienen nada que hacer aquí y `/legales` queda disponible.
  return isAuthRoute || location == AppRoutes.splash ? AppRoutes.home : null;
}
