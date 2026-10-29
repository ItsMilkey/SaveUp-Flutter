import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/errors/failure_messages.dart';

void main() {
  test('toda falla tiene un mensaje no vacío', () {
    final List<AppFailure> failures = <AppFailure>[
      const ValidationFailure(<FieldError>[]),
      const TokenExpiredFailure(),
      const RefreshInvalidFailure(),
      const NotAuthenticatedFailure(),
      const CredentialsInvalidFailure(),
      const LoginBlockedFailure(),
      const ForbiddenFailure(),
      const NotFoundFailure(),
      const ConflictFailure(codigo: 'CONFLICTO_REGLA_NEGOCIO'),
      const ConflictFailure(codigo: 'USUARIO_YA_REGISTRADO'),
      const ConflictFailure(codigo: 'DEUDA_SOBREPAGO'),
      const BadRequestFailure(codigo: 'SOLICITUD_INVALIDA'),
      const BadRequestFailure(codigo: 'PARAMETRO_INVALIDO'),
      const BadRequestFailure(codigo: 'DATOS_INVALIDOS'),
      const BadRequestFailure(codigo: 'TOKEN_VERIFICACION_INVALIDO'),
      const ServerFailure(),
      const NetworkFailure(),
      const TimeoutFailure(),
      const UnknownFailure(),
    ];

    for (final AppFailure failure in failures) {
      expect(
        failureMessage(failure),
        isNotEmpty,
        reason: '${failure.runtimeType} sin mensaje',
      );
    }
  });

  test('CREDENCIALES_INVALIDAS usa el mensaje genérico', () {
    expect(
      failureMessage(const CredentialsInvalidFailure()),
      'Correo o contraseña incorrectos.',
    );
  });

  test('el login bloqueado pide esperar', () {
    expect(
      failureMessage(const LoginBlockedFailure()),
      contains('Demasiados intentos'),
    );
  });

  test('ERROR_INTERNO incluye el idError para soporte', () {
    expect(
      failureMessage(const ServerFailure(idError: 'uuid-123')),
      contains('uuid-123'),
    );
  });

  test('ERROR_INTERNO sin idError no menciona soporte', () {
    expect(
      failureMessage(const ServerFailure()),
      isNot(contains('soporte')),
    );
  });

  test('USUARIO_YA_REGISTRADO sugiere iniciar sesión', () {
    expect(
      failureMessage(
        const ConflictFailure(codigo: 'USUARIO_YA_REGISTRADO'),
      ),
      contains('Inicia sesión'),
    );
  });

  test('CONFLICTO_REGLA_NEGOCIO muestra el detail', () {
    expect(
      failureMessage(
        const ConflictFailure(
          codigo: 'CONFLICTO_REGLA_NEGOCIO',
          detail: 'La deuda ya está pagada',
        ),
      ),
      'La deuda ya está pagada',
    );
  });

  test('DATOS_INVALIDOS muestra el detail', () {
    expect(
      failureMessage(
        const BadRequestFailure(
          codigo: 'DATOS_INVALIDOS',
          detail: 'El monto debe ser mayor que cero',
        ),
      ),
      'El monto debe ser mayor que cero',
    );
  });

  test('TOKEN_VERIFICACION_INVALIDO pide solicitar uno nuevo', () {
    expect(
      failureMessage(
        const BadRequestFailure(codigo: 'TOKEN_VERIFICACION_INVALIDO'),
      ),
      contains('Solicita uno nuevo'),
    );
  });

  test('UnknownFailure usa el detail cuando existe', () {
    expect(
      failureMessage(const UnknownFailure(detail: 'Algo raro pasó')),
      'Algo raro pasó',
    );
  });

  test('NetworkFailure y TimeoutFailure son distinguibles', () {
    expect(
      failureMessage(const NetworkFailure()),
      isNot(failureMessage(const TimeoutFailure())),
    );
  });
}
