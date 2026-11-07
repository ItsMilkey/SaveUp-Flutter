import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../app_version/presentation/app_version_controller.dart';
import 'auth_brand_hero.dart';
import 'auth_controllers.dart';

/// Arranque de la app.
///
/// 1. Consulta `GET /app/version` **antes de cualquier login**; si la
///    actualización es obligatoria, se muestra la pantalla bloqueante.
/// 2. Valida la sesión guardada (`GET /usuarios/me`): el router lleva a
///    `/home` o a `/login` según el resultado.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  AppFailure? _startupFailure;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_running) {
      return;
    }
    _running = true;
    setState(() => _startupFailure = null);

    await ref.read(appVersionProvider.notifier).check();
    final AppVersionState version = ref.read(appVersionProvider);
    if (version is AppVersionBlocked) {
      // El router redirige a la pantalla bloqueante; sin más peticiones.
      return;
    }

    final AppFailure? failure = await ref
        .read(authSessionProvider.notifier)
        .bootstrap();
    if (failure != null) {
      setState(() {
        _startupFailure = failure;
        _running = false;
      });
      return;
    }
    _running = false;
    // El estado de sesión cambió: el router navega a `/home` o `/login`.
  }

  @override
  Widget build(BuildContext context) {
    final AppFailure? failure = _startupFailure;
    return NeoScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const AuthBrandHero(),
                const SizedBox(height: AppSpacing.xl),
                if (failure == null)
                  const _Loading()
                else
                  NeoErrorState(
                    title: 'No pudimos iniciar',
                    message: failureMessage(failure),
                    onRetry: _start,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Preparando tu cuenta',
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: LinearProgressIndicator(),
      ),
    );
  }
}
