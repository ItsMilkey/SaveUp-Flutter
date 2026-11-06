import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              // El envío del token por correo está pendiente de activación
              // (app.mail.enabled=false): no prometer un correo que no llega.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text(avisoEnvioCorreoPendiente)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              if (ui is SolicitudRecuperacionError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    ui.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              _actionArea(submitting),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionArea(bool submitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (submitting)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LinearProgressIndicator(),
              SizedBox(height: 8),
              Text('Esperando al servidor…'),
            ],
          )
        else
          FilledButton(
            onPressed: _submit,
            child: const Text('Enviar solicitud'),
          ),
      ],
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

    InputDecoration decoration(String label, {String? errorText}) {
      return InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_mostrar ? Icons.visibility_off : Icons.visibility),
          tooltip: _mostrar ? 'Ocultar' : 'Mostrar',
          onPressed: () => setState(() => _mostrar = !_mostrar),
        ),
        errorText: errorText,
        errorMaxLines: 3,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(mensajeInstruccionesRestablecimiento),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tokenController,
                enableSuggestions: false,
                autocorrect: false,
                decoration: decoration(
                  'Token',
                  errorText: ui is RestablecerContrasenaTokenInvalido
                      ? ui.message
                      : errorFor('token'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nuevaController,
                obscureText: !_mostrar,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const <String>[AutofillHints.newPassword],
                validator: validatePassword,
                onChanged: (_) => setState(() {}),
                decoration: decoration(
                  'Contraseña nueva',
                  errorText: errorFor('nuevaContrasena'),
                ),
              ),
              const SizedBox(height: 8),
              PasswordPolicyChecklist(value: _nuevaController.text),              const SizedBox(height: 12),
              TextFormField(
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
                decoration: decoration('Repite la contraseña nueva'),
              ),
              const SizedBox(height: 16),
              if (ui is RestablecerContrasenaError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    ui.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              _actionArea(submitting, tokenInvalido: ui is RestablecerContrasenaTokenInvalido),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionArea(bool submitting, {required bool tokenInvalido}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (submitting)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LinearProgressIndicator(),
              SizedBox(height: 8),
              Text('Esperando al servidor…'),
            ],
          )
        else
          FilledButton(
            onPressed: _submit,
            child: const Text('Restablecer contraseña'),
          ),
        // Token rechazado: reintento desde el paso 1 (solicitar uno nuevo).
        if (tokenInvalido)
          TextButton(
            onPressed: () => GoRouter.of(context).go(AppRoutes.recuperarContrasena),
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
