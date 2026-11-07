import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/url_opener.dart';
import '../../../core/design_system/design_system.dart';
import '../../app_version/domain/app_version_info.dart';
import '../../app_version/presentation/app_version_controller.dart';
import '../domain/auth_session.dart';
import '../domain/validators.dart';
import 'auth_brand_hero.dart';
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

    return NeoScaffold(
      appBar: const NeoAppBar(title: 'Inicia sesión'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              const AuthBrandHero(),
              const SizedBox(height: AppSpacing.lg),
              const _SuggestedUpdateBanner(),
              _preloadNotice(ui),
              NeoInput(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                validator: validateEmail,
                label: 'Correo',
                prefixIcon: Icons.alternate_email,
              ),
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _contrasenaController,
                obscureText: !_mostrarContrasena,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const <String>[AutofillHints.password],
                validator: validateLoginPassword,
                label: 'Contraseña',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarContrasena
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  tooltip: _mostrarContrasena
                      ? 'Ocultar contraseña'
                      : 'Mostrar contraseña',
                  onPressed: _toggleMostrar,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _actionArea(context, ui),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: ui is LoginSubmitting
                    ? null
                    : () => GoRouter.of(
                        context,
                      ).push(AppRoutes.recuperarContrasena),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
              TextButton(
                onPressed: ui is LoginSubmitting ? null : _goRegistro,
                child: const Text('¿No tienes cuenta? Crea una aquí'),
              ),
              TextButton(
                onPressed: ui is LoginSubmitting
                    ? null
                    : () => GoRouter.of(context).push(AppRoutes.legales),
                child: const Text('Términos y privacidad'),
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
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: NeoSurface(
        density: AppDensity.list,
        color: colors.info,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.info_outline, size: 20, color: AppColors.ink),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                ui.message,
                style: AppTypography.text(size: 14, color: AppColors.ink),
              ),
            ),
          ],
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
          SizedBox(height: AppSpacing.sm),
          Text('Esperando al servidor…', textAlign: TextAlign.center),
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
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: NeoErrorBand(message: message),
          ),
        NeoButton(
          // Ante 429 el reenvío automático está prohibido: se inhabilita el
          // botón y el reintento es manual ("Reintentar", tras unos minutos).
          label: 'Iniciar sesión',
          expanded: true,
          onPressed: blocked ? null : _submit,
        ),
        if (blocked) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          NeoButton(
            label: 'Reintentar',
            variant: NeoButtonVariant.secondary,
            expanded: true,
            onPressed: () => ref
                .read(loginProvider.notifier)
                .retryAfterBlock(correo: _correoController.text),
          ),
        ],
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
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: NeoSurface(
        density: AppDensity.list,
        color: colors.surfaceAlt,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.system_update_alt,
                  size: 20,
                  color: colors.ink,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(mensaje)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                NeoButton(
                  label: 'Más tarde',
                  variant: NeoButtonVariant.ghost,
                  onPressed: () => ref
                      .read(appVersionProvider.notifier)
                      .dismissSuggestion(),
                ),
                const SizedBox(width: AppSpacing.sm),
                NeoButton(
                  label: 'Actualizar',
                  variant: NeoButtonVariant.secondary,
                  onPressed: _abrirTienda,
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
