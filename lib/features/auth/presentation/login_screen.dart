import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/url_opener.dart';
import '../../app_version/domain/app_version_info.dart';
import '../../app_version/presentation/app_version_controller.dart';
import '../domain/auth_session.dart';
import '../domain/validators.dart';
import 'auth_controllers.dart';

/// Inicio de sesión: correo y contraseña.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  bool _mostrarContrasena = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // Aviso de sesión expirada: una sola vez, luego se limpia la marca.
      final AuthSession session = ref.read(authSessionProvider);
      final bool expired =
          session is SessionUnauthenticated && session.sessionExpired;
      if (expired) {
        ref.read(authSessionProvider.notifier).clearExpiredNotice();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu sesión expiró. Inicia sesión nuevamente.'),
          ),
        );
      }
      // Correo precargado que ya estaba en el estado (p. ej. tras registro).
      final LoginUiState login = ref.read(loginProvider);
      if (login is LoginNotice && _correoController.text.isEmpty) {
        _correoController.text = login.correo;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final LoginUiState ui = ref.watch(loginProvider);

    // Precarga el correo cuando otra pantalla avisa (cuenta creada).
    ref.listen(loginProvider, (_, LoginUiState next) {
      if (next is LoginNotice && _correoController.text.isEmpty) {
        _correoController.text = next.correo;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Inicia sesión')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              const _SuggestedUpdateBanner(),
              _preloadNotice(ui),
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                validator: validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contrasenaController,
                obscureText: !_mostrarContrasena,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const <String>[AutofillHints.password],
                validator: validateLoginPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarContrasena
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _toggleMostrar,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _actionArea(context, ui),
              const SizedBox(height: 12),
              TextButton(
                onPressed: ui is LoginSubmitting ? null : _goRegistro,
                child: const Text('¿No tienes cuenta? Crea una aquí'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aviso precargado desde otra pantalla (p. ej. cuenta creada).
  Widget _preloadNotice(LoginUiState ui) {
    if (ui is! LoginNotice) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(ui.message),
        ),
      ),
    );
  }

  Widget _actionArea(BuildContext context, LoginUiState ui) {
    if (ui is LoginSubmitting) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LinearProgressIndicator(),
          SizedBox(height: 8),
          Text(
            'Esperando al servidor…',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    final bool blocked = ui is LoginBlocked;
    final String message;
    if (ui is LoginError) {
      message = ui.message;
    } else if (blocked) {
      message = blockedMessage;
    } else {
      message = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        FilledButton(
          // Ante 429 el reenvío automático está prohibido: se inhabilita el
          // botón y el reintento es manual ("Reintentar", tras unos minutos).
          onPressed: blocked ? null : _submit,
          child: const Text('Iniciar sesión'),
        ),
        if (blocked)
          OutlinedButton(
            onPressed: () => ref
                .read(loginProvider.notifier)
                .retryAfterBlock(correo: _correoController.text),
            child: const Text('Reintentar'),
          ),
      ],
    );
  }

  static const String blockedMessage =
      'Demasiados intentos; espera unos minutos.';

  void _toggleMostrar() {
    setState(() => _mostrarContrasena = !_mostrarContrasena);
  }

  void _goRegistro() {
    GoRouter.of(context).go(AppRoutes.registro);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(loginProvider.notifier)
        .submit(
          correo: _correoController.text,
          contrasena: _contrasenaController.text,
        );
  }
}

/// Aviso no intrusivo de `actualizacionSugerida=true`, descartable.
class _SuggestedUpdateBanner extends ConsumerStatefulWidget {
  const _SuggestedUpdateBanner();

  @override
  ConsumerState<_SuggestedUpdateBanner> createState() =>
      _SuggestedUpdateBannerState();
}

class _SuggestedUpdateBannerState
    extends ConsumerState<_SuggestedUpdateBanner> {
  @override
  Widget build(BuildContext context) {
    final AppVersionState version = ref.watch(appVersionProvider);
    return switch (version) {
      AppVersionSuggested(:final AppVersionInfo info) => _banner(info.mensaje),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _banner(String mensaje) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(mensaje),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                TextButton(
                  onPressed: () =>
                      ref.read(appVersionProvider.notifier).dismissSuggestion(),
                  child: const Text('Más tarde'),
                ),
                TextButton(
                  onPressed: _abrirTienda,
                  child: const Text('Actualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirTienda() async {
    final AppVersionState version = ref.read(appVersionProvider);
    final String? url = switch (version) {
      AppVersionSuggested(:final AppVersionInfo info) => info.urlTienda,
      _ => null,
    };
    final Uri? uri = Uri.tryParse(url ?? '');
    if (uri == null) {
      return;
    }
    await ref.read(urlOpenerProvider)(uri);
  }
}
