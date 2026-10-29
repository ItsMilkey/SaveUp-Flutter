import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/errors/problem_details.dart';

String _problem(
  String codigo,
  int status, {
  List<Map<String, String>>? errores,
  String? idError,
  String detail = 'detalle del backend',
}) {
  return jsonEncode(<String, Object?>{
    'type': 'about:blank',
    'title': 'Error',
    'status': status,
    'detail': detail,
    'instance': '/api/v1/recurso',
    'codigo': codigo,
    'errores': ?errores,
    'idError': ?idError,
  });
}

void main() {
  group('mapeo por codigo', () {
    final List<(String, int, Matcher)> cases = <(String, int, Matcher)>[
      ('VALIDACION_FALLIDA', 400, isA<ValidationFailure>()),
      ('SOLICITUD_INVALIDA', 400, isA<BadRequestFailure>()),
      ('PARAMETRO_INVALIDO', 400, isA<BadRequestFailure>()),
      ('DATOS_INVALIDOS', 400, isA<BadRequestFailure>()),
      ('NO_AUTENTICADO', 401, isA<NotAuthenticatedFailure>()),
      ('TOKEN_EXPIRADO', 401, isA<TokenExpiredFailure>()),
      ('REFRESH_INVALIDO', 401, isA<RefreshInvalidFailure>()),
      ('TOKEN_VERIFICACION_INVALIDO', 400, isA<BadRequestFailure>()),
      ('CREDENCIALES_INVALIDAS', 401, isA<CredentialsInvalidFailure>()),
      ('INTENTOS_LOGIN_EXCEDIDOS', 429, isA<LoginBlockedFailure>()),
      ('PROHIBIDO', 403, isA<ForbiddenFailure>()),
      ('NO_ENCONTRADO', 404, isA<NotFoundFailure>()),
      ('CONFLICTO_REGLA_NEGOCIO', 409, isA<ConflictFailure>()),
      ('USUARIO_YA_REGISTRADO', 409, isA<ConflictFailure>()),
      ('DEUDA_SOBREPAGO', 409, isA<ConflictFailure>()),
      ('ERROR_INTERNO', 500, isA<ServerFailure>()),
    ];

    for (final (String codigo, int status, Matcher matcher) in cases) {
      test('mapea $codigo', () {
        final AppFailure failure = failureFromProblemDetails(
          statusCode: status,
          body: _problem(codigo, status),
        );

        expect(failure, matcher);
      });
    }

    test('conserva el codigo en las fallas de conflicto', () {
      final AppFailure failure = failureFromProblemDetails(
        statusCode: 409,
        body: _problem('DEUDA_SOBREPAGO', 409),
      );

      expect(failure, isA<ConflictFailure>());
      expect((failure as ConflictFailure).codigo, 'DEUDA_SOBREPAGO');
    });

    test('parsea errores[] de validación', () {
      final AppFailure failure = failureFromProblemDetails(
        statusCode: 400,
        body: _problem(
          'VALIDACION_FALLIDA',
          400,
          errores: <Map<String, String>>[
            <String, String>{
              'campo': 'email',
              'mensaje': 'El correo no es válido',
            },
            <String, String>{
              'campo': 'contrasena',
              'mensaje': 'Debe tener al menos un número',
            },
          ],
        ),
      );

      final ValidationFailure validation = failure as ValidationFailure;
      expect(validation.errors, hasLength(2));
      expect(validation.errors.first.field, 'email');
      expect(validation.errors.last.message, 'Debe tener al menos un número');
    });

    test('un VALIDACION_FALLIDA sin errores queda con lista vacía', () {
      final AppFailure failure = failureFromProblemDetails(
        statusCode: 400,
        body: _problem('VALIDACION_FALLIDA', 400),
      );

      expect((failure as ValidationFailure).errors, isEmpty);
    });

    test('conserva idError en ERROR_INTERNO', () {
      final AppFailure failure = failureFromProblemDetails(
        statusCode: 500,
        body: _problem('ERROR_INTERNO', 500, idError: 'uuid-123'),
      );

      expect((failure as ServerFailure).idError, 'uuid-123');
    });

    test('conserva detail en DATOS_INVALIDOS', () {
      final AppFailure failure = failureFromProblemDetails(
        statusCode: 400,
        body: _problem('DATOS_INVALIDOS', 400, detail: 'Monto inválido'),
      );

      expect((failure as BadRequestFailure).detail, 'Monto inválido');
    });
  });

  group('casos degradados', () {
    test('código desconocido conserva status y codigo', () {
      final AppFailure failure = failureFromProblemDetails(
        statusCode: 418,
        body: _problem('SOY_UNA_TETERA', 418),
      );

      expect(failure, isA<UnknownFailure>());
      final UnknownFailure unknown = failure as UnknownFailure;
      expect(unknown.status, 418);
      expect(unknown.codigo, 'SOY_UNA_TETERA');
    });

    test('cuerpo vacío conserva el status', () {
      final AppFailure failure = failureFromProblemDetails(
        statusCode: 502,
        body: '',
      );

      expect(failure, isA<UnknownFailure>());
      expect((failure as UnknownFailure).status, 502);
    });

    test('cuerpo no JSON conserva el status', () {
      final AppFailure failure = failureFromProblemDetails(
        statusCode: 500,
        body: '<html>Bad Gateway</html>',
      );

      expect(failure, isA<UnknownFailure>());
      expect((failure as UnknownFailure).status, 500);
    });

    test('cuerpo null conserva el status', () {
      final AppFailure failure = failureFromProblemDetails(
        statusCode: 503,
        body: null,
      );

      expect(failure, isA<UnknownFailure>());
      expect((failure as UnknownFailure).status, 503);
    });

    test('acepta un cuerpo ya decodificado (Map)', () {
      final AppFailure failure = failureFromProblemDetails(
        statusCode: 404,
        body: <String, Object?>{'codigo': 'NO_ENCONTRADO'},
      );

      expect(failure, isA<NotFoundFailure>());
    });
  });
}
