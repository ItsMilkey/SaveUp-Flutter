import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../domain/account_repository.dart';
import 'account_dtos.dart';

final Provider<AccountRepository> accountRepositoryProvider =
    Provider<AccountRepository>((Ref ref) {
      return DioAccountRepository(client: ref.watch(apiClientProvider));
    });

/// Implementación de [AccountRepository] sobre el cliente HTTP de la app.
///
/// Todas las llamadas pasan por [ApiClient], así que los errores llegan ya
/// traducidos a `AppFailure` por `codigo`.
class DioAccountRepository implements AccountRepository {
  const DioAccountRepository({required this.client});

  final ApiClient client;

  @override
  Future<void> cambiarContrasena({
    required String contrasenaActual,
    required String nuevaContrasena,
  }) async {
    // El contrato responde 200 {message} (y revoca todas las sesiones).
    await _readObject(
      () => client.put<dynamic>(
        '/usuarios/me/contrasena',
        data: CambioContrasenaRequestDto(
          contrasenaActual: contrasenaActual,
          nuevaContrasena: nuevaContrasena,
        ).toJson(),
      ),
    );
  }

  @override
  Future<void> solicitarRecuperacion({required String email}) async {
    // Contrato: siempre 200 {message}, genérico (anti-enumeración).
    await _readObject(
      () => client.post<dynamic>(
        '/auth/recuperar-contrasena',
        data: SolicitudRecuperacionRequestDto(email: email.trim()).toJson(),
      ),
    );
  }

  @override
  Future<void> restablecerContrasena({
    required String token,
    required String nuevaContrasena,
  }) async {
    // Contrato: 200 {message}; el backend revoca todas las sesiones.
    await _readObject(
      () => client.post<dynamic>(
        '/auth/restablecer-contrasena',
        data: RestablecerContrasenaRequestDto(
          token: token.trim(),
          nuevaContrasena: nuevaContrasena,
        ).toJson(),
      ),
    );
  }

  @override
  Future<void> eliminarCuenta({required String contrasena}) async {
    // Contrato: 204 SIN cuerpo (a diferencia de los 200 {message}); por eso
    // aquí se descarta la respuesta sin exigir un objeto JSON.
    await client.delete<dynamic>(
      '/usuarios/me',
      data: EliminacionCuentaRequestDto(contrasena: contrasena).toJson(),
    );
  }

  /// Ejecuta la petición y descarta su cuerpo (`{message}`), exigiendo que
  /// sea un objeto JSON bien formado.
  Future<Map<String, dynamic>> _readObject(
    Future<Response<dynamic>> Function() request,
  ) async {
    final Response<dynamic> response = await request();
    final Object? data = response.data;
    if (data is! Map) {
      throw const UnknownFailure(
        detail: 'El servidor devolvió una respuesta inesperada.',
      );
    }
    return data.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
  }
}
