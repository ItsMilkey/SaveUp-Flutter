import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design_system/design_system.dart';
import '../../auth/domain/validators.dart';
import '../../auth/presentation/password_policy_checklist.dart';
import 'account_controllers.dart';

/// Paso 1: solicitud de recuperación de contraseña sin sesión
/// (`POST /auth/recuperar-contrasena`).
///
/// La respuesta del backend es **siempre 200 genérico** (anti-enumeración);
/// al éxito se pasa al formulario del token con [mensajeInstruccionesRestablecimiento].
class SolicitarRecuperacionScreen extends ConsumerStatefulWidget {
  const SolicitarRecuperacionScreen({super.key});

  @override
  ConsumerState<SolicitarRecuperacionScreen> createState() =>
      _SolicitarRecuperacionScreenState();
}

class _SolicitarRecuperacionScreenState
    extends ConsumerState<SolicitarRecuperacionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _correoController = TextEditingController();

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SolicitudRecuperacionUiState ui = ref.watch(
      solicitudRecuperacionProvider,
    );
    final bool submitting = ui is SolicitudRecuperacionSubmitting;

    ref.listen<SolicitudRecuperacionUiState>(solicitudRecuperacionProvider, (
      _,
      SolicitudRecuperacionUiState next,
    ) {
      if (next is SolicitudRecuperacionSuccess) {
        GoRouter.of(context).push(AppRoutes.restablecerContrasena);
      }
    });

    return NeoScaffold(
      appBar: const NeoAppBar(title: 'Recuperar contraseña'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              // El envío del token por correo está pendiente de activación
              // (app.mail.enabled=false): no prometer un correo que no llega.
              const _InfoNotice(message: avisoEnvioCorreoPendiente),
              const SizedBox(height: AppSpacing.lg),
              NeoInput(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                validator: validateEmail,
                label: 'Correo',
                prefixIcon: Icons.alternate_email,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (ui is SolicitudRecuperacionError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: NeoErrorBand(message: ui.message),
                ),
              _actionArea(submitting),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionArea(bool submitting) {
    if (submitting) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LinearProgressIndicator(),
          SizedBox(height: AppSpacing.sm),
          Text('Esperando al servidor…', textAlign: TextAlign.center),
        ],
      );
    }
    return NeoButton(
      label: 'Enviar solicitud',
      expanded: true,
      onPressed: _submit,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(solicitudRecuperacionProvider.notifier)
        .submit(email: _correoController.text);
  }
}

/// Paso 2: restablecimiento con el token de un solo uso
/// (`POST /auth/restablecer-contrasena`).
///
/// Al éxito el backend revocó todas las sesiones: se cierra la sesión local
/// (si existía), se precarga el aviso en el login y se redirige con el router.
class RestablecerContrasenaScreen extends ConsumerStatefulWidget {
  const RestablecerContrasenaScreen({super.key});

  @override
  ConsumerState<RestablecerContrasenaScreen> createState() =>
      _RestablecerContrasenaScreenState();
}

class _RestablecerContrasenaScreenState
    extends ConsumerState<RestablecerContrasenaScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _nuevaController = TextEditingController();
  final TextEditingController _repetidaController = TextEditingController();
  bool _mostrar = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _nuevaController.dispose();
    _repetidaController.dispose();
    super.dispose();
  }

  /// Correo capturado en el paso 1 (si la persona vino desde ahí), para
  /// precargar el login final.
  String get _correoSugerido {
    final SolicitudRecuperacionUiState solicitud = ref.read(
      solicitudRecuperacionProvider,
    );
    return switch (solicitud) {
      SolicitudRecuperacionSuccess(:final String correo) => correo,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final RestablecerContrasenaUiState ui = ref.watch(
      restablecerContrasenaProvider,
    );
    final bool submitting = ui is RestablecerContrasenaSubmitting;
    final bool tokenInvalido = ui is RestablecerContrasenaTokenInvalido;

    ref.listen<RestablecerContrasenaUiState>(restablecerContrasenaProvider, (
      _,
      RestablecerContrasenaUiState next,
    ) {
      if (next is RestablecerContrasenaSuccess) {
        GoRouter.of(context).go(AppRoutes.login);
      }
    });

    String? errorFor(String campo) {
      return switch (ui) {
        RestablecerContrasenaFieldErrors(:final Map<String, String> errors) =>
          errors[campo],
        _ => null,
      };
    }

    Widget visibleSuffix() {
      return IconButton(
        icon: Icon(_mostrar ? Icons.visibility_off : Icons.visibility),
        tooltip: _mostrar ? 'Ocultar' : 'Mostrar',
        onPressed: () => setState(() => _mostrar = !_mostrar),
      );
    }

    return NeoScaffold(
      appBar: const NeoAppBar(title: 'Restablecer contraseña'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              const _InfoNotice(message: mensajeInstruccionesRestablecimiento),
              const SizedBox(height: AppSpacing.lg),
              NeoInput(
                controller: _tokenController,
                enableSuggestions: false,
                autocorrect: false,
                label: 'Token',
                prefixIcon: Icons.lock_outline,
                error: tokenInvalido ? ui.message : errorFor('token'),
              ),
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _nuevaController,
                obscureText: !_mostrar,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const <String>[AutofillHints.newPassword],
                validator: validatePassword,
                onChanged: (_) => setState(() {}),
                label: 'Contraseña nueva',
                prefixIcon: Icons.lock_outline,
                suffixIcon: visibleSuffix(),
                errorMaxLines: 3,
                error: errorFor('nuevaContrasena'),
              ),
              const SizedBox(height: AppSpacing.sm),
              PasswordPolicyChecklist(value: _nuevaController.text),
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _repetidaController,
                obscureText: !_mostrar,
                enableSuggestions: false,
                autocorrect: false,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Vuelve a escribir la contraseña nueva.';
                  }
                  if (value != _nuevaController.text) {
                    return 'Las contraseñas no coinciden.';
                  }
                  return null;
                },
                label: 'Repite la contraseña nueva',
                prefixIcon: Icons.lock_outline,
                suffixIcon: visibleSuffix(),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (ui is RestablecerContrasenaError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: NeoErrorBand(message: ui.message),
                ),
              _actionArea(submitting, tokenInvalido: tokenInvalido),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionArea(bool submitting, {required bool tokenInvalido}) {
    if (submitting) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LinearProgressIndicator(),
          SizedBox(height: AppSpacing.sm),
          Text('Esperando al servidor…', textAlign: TextAlign.center),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        NeoButton(
          label: 'Restablecer contraseña',
          expanded: true,
          onPressed: _submit,
        ),
        // Token rechazado: reintento desde el paso 1 (solicitar uno nuevo).
        if (tokenInvalido)
          TextButton(
            onPressed: () =>
                GoRouter.of(context).go(AppRoutes.recuperarContrasena),
            child: const Text('Solicitar uno nuevo'),
          ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(restablecerContrasenaProvider.notifier)
        .submit(
          token: _tokenController.text,
          nuevaContrasena: _nuevaController.text,
          correo: _correoSugerido,
        );
  }
}

/// Aviso informativo con el color de info del sistema.
class _InfoNotice extends StatelessWidget {
  const _InfoNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return NeoSurface(
      density: AppDensity.list,
      color: colors.info,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, size: 20, color: AppColors.ink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.text(size: 14, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
