import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account_controllers.dart';

/// Diálogo defensivo de eliminación de cuenta, en dos pasos:
///
/// 1. Advertencia explícita de irreversibilidad (se pierden movimientos,
///    planes, deudas y metas).
/// 2. Confirmación por contraseña ("Eliminar mi cuenta definitivamente").
///
/// `CREDENCIALES_INVALIDAS` u otro error dejan el diálogo abierto con el
/// mensaje; al 204 el controlador cierra la sesión local y el router lleva
/// a `/login` con el aviso.
class EliminarCuentaDialog extends ConsumerStatefulWidget {
  const EliminarCuentaDialog({super.key});

  /// Abre el diálogo reiniciando el estado del controlador.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const EliminarCuentaDialog(),
    );
  }

  @override
  ConsumerState<EliminarCuentaDialog> createState() =>
      _EliminarCuentaDialogState();
}

class _EliminarCuentaDialogState extends ConsumerState<EliminarCuentaDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _contrasenaController = TextEditingController();
  bool _mostrar = false;

  /// `false`: paso 1 (advertencia); `true`: paso 2 (confirmación).
  bool _pasoConfirmacion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(eliminarCuentaProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EliminarCuentaUiState ui = ref.watch(eliminarCuentaProvider);
    final bool submitting = ui is EliminarCuentaSubmitting;

    // Al 204: cerrar el diálogo; el router ya lleva a /login con el aviso.
    ref.listen<EliminarCuentaUiState>(eliminarCuentaProvider, (
      _,
      EliminarCuentaUiState next,
    ) {
      if (next is EliminarCuentaSuccess) {
        final NavigatorState root = Navigator.of(context, rootNavigator: true);
        if (root.canPop()) {
          root.pop();
        }
      }
    });

    final String? errorContrasena = switch (ui) {
      EliminarCuentaContrasenaInvalida(:final String message) => message,
      _ => null,
    };

    return AlertDialog(
      title: Text(_pasoConfirmacion ? 'Eliminar cuenta' : '¿Eliminar tu cuenta?'),
      content: _pasoConfirmacion
          ? Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Ingresa tu contraseña actual para confirmar. Esta '
                    'acción no se puede deshacer.',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contrasenaController,
                    obscureText: !_mostrar,
                    enableSuggestions: false,
                    autocorrect: false,
                    autofocus: true,
                    autofillHints: const <String>[AutofillHints.password],
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrar ? Icons.visibility_off : Icons.visibility,
                        ),
                        tooltip: _mostrar ? 'Ocultar' : 'Mostrar',
                        onPressed: () => setState(() => _mostrar = !_mostrar),
                      ),
                      errorText: errorContrasena,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Se eliminarán permanentemente tus datos: movimientos, '
                    'planes, deudas y metas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : const Text(
              'Tu cuenta y todos tus datos se eliminarán de forma '
              'permanente: movimientos, planes, deudas y metas. No podrán '
              'recuperarse.',
            ),
      actions: <Widget>[
        // Errores de red/servidor: el diálogo sigue abierto para reintentar.
        if (!submitting && ui is EliminarCuentaError)
          Text(
            ui.message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        TextButton(
          onPressed: submitting
              ? null
              : () {
                  final NavigatorState root = Navigator.of(
                    context,
                    rootNavigator: true,
                  );
                  if (root.canPop()) {
                    root.pop();
                  }
                },
          child: const Text('Cancelar'),
        ),
        if (!submitting)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed:
                _pasoConfirmacion ? _confirmar : () => setState(
                  () => _pasoConfirmacion = true,
                ),
            child: Text(
              _pasoConfirmacion
                  ? 'Eliminar mi cuenta definitivamente'
                  : 'Continuar',
            ),
          ),
        if (submitting)
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LinearProgressIndicator(),
              SizedBox(height: 8),
              Text('Esperando al servidor…'),
            ],
          ),
      ],
    );
  }

  /// Paso 2: valida el formulario y envía la confirmación con la contraseña.
  void _confirmar() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    ref
        .read(eliminarCuentaProvider.notifier)
        .submit(contrasena: _contrasenaController.text);
  }
}
