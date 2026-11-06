import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/validators.dart';
import '../../auth/presentation/password_policy_checklist.dart';
import 'account_controllers.dart';

/// Cambio de contraseña con sesión activa (`PUT /usuarios/me/contrasena`).
///
/// Al éxito el backend revoca todas las sesiones del usuario: el controlador
/// cierra la sesión local y el router lleva a `/login` con el aviso; esta
/// pantalla no navega por su cuenta.
class CambiarContrasenaScreen extends ConsumerStatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  ConsumerState<CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState
    extends ConsumerState<CambiarContrasenaScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _actualController = TextEditingController();
  final TextEditingController _nuevaController = TextEditingController();
  final TextEditingController _repetidaController = TextEditingController();
  bool _mostrar = false;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _repetidaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CambiarContrasenaUiState ui = ref.watch(cambiarContrasenaProvider);
    final bool submitting = ui is CambiarContrasenaSubmitting;

    String? errorFor(String campo) {
      return switch (ui) {
        CambiarContrasenaFieldErrors(:final Map<String, String> errors) =>
          errors[campo],
        _ => null,
      };
    }

    // CREDENCIALES_INVALIDAS: el mensaje va inline en "Contraseña actual".
    String? errorActual() {
      if (ui is CambiarContrasenaCurrentPasswordWrong) {
        return ui.message;
      }
      return errorFor('contrasenaActual');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              if (ui is CambiarContrasenaError) _errorText(context, ui.message),
              if (ui is CambiarContrasenaFieldErrors && ui.global != null)
                _errorText(context, ui.global!),
              const Text(
                'Al cambiar la contraseña se cierra tu sesión en todos los '
                'dispositivos.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _actualController,
                obscureText: !_mostrar,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const <String>[AutofillHints.password],
                validator: validateLoginPassword,
                decoration: decoration(
                  'Contraseña actual',
                  errorText: errorActual(),
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
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 8),
              PasswordPolicyChecklist(value: _nuevaController.text),
              const SizedBox(height: 12),
              TextFormField(
                controller: _repetidaController,
                obscureText: !_mostrar,
                enableSuggestions: false,
                autocorrect: false,
                validator: _repetidaValidator,
                decoration: decoration(
                  'Repite la contraseña nueva',
                  errorText: errorFor('repetirContrasena'),
                ),
              ),
              const SizedBox(height: 16),
              if (submitting)
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Esperando al servidor…'),
                  ],
                )
              else
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Guardar nueva contraseña'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration decoration(
    String label, {
    String? errorText,
    int errorMaxLines = 1,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(
          _mostrar ? Icons.visibility_off : Icons.visibility,
        ),
        tooltip: _mostrar ? 'Ocultar' : 'Mostrar',
        onPressed: () => setState(() => _mostrar = !_mostrar),
      ),
      errorText: errorText,
      errorMaxLines: errorMaxLines,
    );
  }

  String? _repetidaValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vuelve a escribir la contraseña nueva.';
    }
    if (value != _nuevaController.text) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  Widget _errorText(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(cambiarContrasenaProvider.notifier)
        .submit(
          contrasenaActual: _actualController.text,
          nuevaContrasena: _nuevaController.text,
        );
  }
}
