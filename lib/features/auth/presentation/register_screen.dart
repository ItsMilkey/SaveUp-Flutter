import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design_system/design_system.dart';
import '../domain/validators.dart';
import 'auth_controllers.dart';
import 'password_policy_checklist.dart';

/// Creación de cuenta: RUT, nombre, apellido, correo y contraseña.
///
/// `register` **no inicia sesión**: al éxito se lleva al login con el correo
/// precargado y un aviso de cuenta creada (un solo intento, hecho por la
/// persona).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _rutController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  @override
  void dispose() {
    _rutController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RegisterUiState ui = ref.watch(registerProvider);

    // Al éxito: llevar al login (register no inicia sesión).
    ref.listen(registerProvider, (_, RegisterUiState next) {
      if (next is RegisterSuccess) {
        GoRouter.of(context).go(AppRoutes.login);
      }
    });

    String? errorFor(String campo) {
      return switch (ui) {
        RegisterFieldErrors(:final Map<String, String> errors) => errors[campo],
        _ => null,
      };
    }

    return NeoScaffold(
      appBar: NeoAppBar(
        title: 'Crea tu cuenta',
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: () => GoRouter.of(context).go(AppRoutes.login),
              child: const Text('Ya tengo cuenta'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              if (ui is RegisterError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: NeoErrorBand(message: ui.message),
                ),
              if (ui is RegisterFieldErrors && ui.global != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: NeoErrorBand(message: ui.global!),
                ),
              NeoInput(
                controller: _rutController,
                keyboardType: TextInputType.text,
                autofillHints: const <String>[AutofillHints.username],
                validator: validateRut,
                label: 'RUT',
                hint: '12345678-9',
                prefixIcon: Icons.badge_outlined,
                error: errorFor('rut'),
              ),
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _nombreController,
                keyboardType: TextInputType.name,
                validator: (String? value) =>
                    validateName(value, label: 'El nombre'),
                label: 'Nombre',
                prefixIcon: Icons.person_outline,
                error: errorFor('nombre'),
              ),
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _apellidoController,
                keyboardType: TextInputType.name,
                validator: (String? value) =>
                    validateName(value, label: 'El apellido'),
                label: 'Apellido',
                prefixIcon: Icons.person_outline,
                error: errorFor('apellido'),
              ),
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                validator: validateEmail,
                label: 'Correo',
                prefixIcon: Icons.alternate_email,
                error: errorFor('email'),
              ),
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _contrasenaController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const <String>[AutofillHints.newPassword],
                validator: validatePassword,
                onChanged: (_) => setState(() {}),
                label: 'Contraseña',
                prefixIcon: Icons.lock_outline,
                errorMaxLines: 3,
                error: errorFor('contrasena'),
              ),
              const SizedBox(height: AppSpacing.sm),
              PasswordPolicyChecklist(value: _contrasenaController.text),
              const SizedBox(height: AppSpacing.lg),
              if (ui is RegisterSubmitting)
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    LinearProgressIndicator(),
                    SizedBox(height: AppSpacing.sm),
                    Text('Esperando al servidor…', textAlign: TextAlign.center),
                  ],
                )
              else
                NeoButton(
                  label: 'Crear cuenta',
                  expanded: true,
                  onPressed: _submit,
                ),
              const SizedBox(height: AppSpacing.md),
              if (ui is RegisterSuccess)
                const Column(
                  children: <Widget>[
                    LinearProgressIndicator(),
                    SizedBox(height: AppSpacing.sm),
                    Text('Cuenta creada. Llevando al inicio de sesión…'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(registerProvider.notifier)
        .submit(
          rut: _rutController.text,
          nombre: _nombreController.text,
          apellido: _apellidoController.text,
          email: _correoController.text,
          contrasena: _contrasenaController.text,
        );
  }
}
