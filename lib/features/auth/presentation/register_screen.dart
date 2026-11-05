import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../domain/validators.dart';
import 'auth_controllers.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Crea tu cuenta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              if (ui is RegisterError) _errorText(context, ui.message),
              if (ui is RegisterFieldErrors && ui.global != null)
                _errorText(context, ui.global!),
              TextFormField(
                controller: _rutController,
                keyboardType: TextInputType.text,
                autofillHints: const <String>[AutofillHints.username],
                validator: validateRut,
                decoration: InputDecoration(
                  labelText: 'RUT',
                  hintText: '12345678-9',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  errorText: errorFor('rut'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                keyboardType: TextInputType.name,
                validator: (String? value) =>
                    validateName(value, label: 'El nombre'),
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: const Icon(Icons.person_outline),
                  errorText: errorFor('nombre'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apellidoController,
                keyboardType: TextInputType.name,
                validator: (String? value) =>
                    validateName(value, label: 'El apellido'),
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: const Icon(Icons.person_outline),
                  errorText: errorFor('apellido'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                validator: validateEmail,
                decoration: InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: const Icon(Icons.alternate_email),
                  errorText: errorFor('email'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contrasenaController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const <String>[AutofillHints.newPassword],
                validator: validatePassword,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                  errorMaxLines: 3,
                  errorText: errorFor('contrasena'),
                ),
              ),
              const SizedBox(height: 8),
              _PasswordChecklist(value: _contrasenaController.text),
              const SizedBox(height: 16),
              if (ui is RegisterSubmitting)
                const LinearProgressIndicator()
              else
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Crear cuenta'),
                ),
              const SizedBox(height: 12),
              if (ui is RegisterSuccess)
                const Column(
                  children: <Widget>[
                    LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Cuenta creada. Llevando al inicio de sesión…'),
                  ],
                ),
              TextButton(
                onPressed: () => GoRouter.of(context).go(AppRoutes.login),
                child: const Text('Ya tengo cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
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

/// Checklist visible de la política de contraseña.
class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final PasswordCheck check = PasswordCheck.evaluate(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _check(context, check.hasLength, 'Entre 8 y 64 caracteres'),
        _check(context, check.hasLetter, 'Al menos una letra'),
        _check(context, check.hasNumber, 'Al menos un número'),
        _check(
          context,
          check.hasByteLimit,
          'Máximo 72 bytes en UTF-8 (tildes y ñ cuentan doble)',
        ),
      ],
    );
  }

  Widget _check(BuildContext context, bool ok, String label) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(
            ok ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: ok ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
