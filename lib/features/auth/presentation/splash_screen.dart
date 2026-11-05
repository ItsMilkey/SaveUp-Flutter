import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../app_version/presentation/app_version_controller.dart';
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
    final Widget body;
    if (_startupFailure == null) {
      body = const CircularProgressIndicator.adaptive();
    } else {
      final AppFailure failure = _startupFailure!;
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(failureMessage(failure), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _start, child: const Text('Reintentar')),
        ],
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'SaveUp',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              body,
            ],
          ),
        ),
      ),
    );
  }
}
