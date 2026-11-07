import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
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

    return NeoScaffold(
      appBar: const NeoAppBar(title: 'Cambiar contraseña'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              if (ui is CambiarContrasenaError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: NeoErrorBand(message: ui.message),
                ),
              if (ui is CambiarContrasenaFieldErrors && ui.global != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: NeoErrorBand(message: ui.global!),
                ),
              const Text(
                'Al cambiar la contraseña se cierra tu sesión en todos los '
                'dispositivos.',
              ),
              const SizedBox(height: AppSpacing.lg),
              NeoInput(
                controller: _actualController,
                obscureText: !_mostrar,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const <String>[AutofillHints.password],
                validator: validateLoginPassword,
                label: 'Contraseña actual',
                prefixIcon: Icons.lock_outline,
                suffixIcon: _suffixVisible(),
                error: errorActual(),
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
                suffixIcon: _suffixVisible(),
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
                validator: _repetidaValidator,
                label: 'Repite la contraseña nueva',
                prefixIcon: Icons.lock_outline,
                suffixIcon: _suffixVisible(),
                error: errorFor('repetirContrasena'),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (submitting)
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    LinearProgressIndicator(),
                    SizedBox(height: AppSpacing.sm),
                    Text('Esperando al servidor…'),
                  ],
                )
              else
                NeoButton(
                  label: 'Guardar nueva contraseña',
                  expanded: true,
                  onPressed: _submit,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suffixVisible() {
    return IconButton(
      icon: Icon(
        _mostrar ? Icons.visibility_off : Icons.visibility,
      ),
      tooltip: _mostrar ? 'Ocultar' : 'Mostrar',
      onPressed: () => setState(() => _mostrar = !_mostrar),
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
