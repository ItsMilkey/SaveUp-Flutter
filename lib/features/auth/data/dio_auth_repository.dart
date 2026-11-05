import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_store.dart';
import '../domain/auth_repository.dart';
import '../domain/user_profile.dart';
import 'auth_dtos.dart';

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) {
      return DioAuthRepository(
        client: ref.watch(apiClientProvider),
        tokenStore: ref.watch(tokenStoreProvider),
      );
    });

/// Implementación de [AuthRepository] sobre el cliente HTTP de la app.
///
/// Todas las llamadas pasan por [ApiClient], así que los errores llegan ya
/// traducidos a `AppFailure` por `codigo`.
class DioAuthRepository implements AuthRepository {
  const DioAuthRepository({required this.client, required this.tokenStore});

  final ApiClient client;
  final TokenStore tokenStore;

  @override
  Future<void> register({
    required String rut,
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    // El contrato responde 200 {message}: no hay tokens que guardar.
    await _readObject(
      () => client.post<dynamic>(
        '/usuarios/register',
        data: RegisterRequestDto(
          rut: rut,
          nombre: nombre,
          apellido: apellido,
          email: email,
          contrasena: password,
        ).toJson(),
      ),
    );
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> body = await _readObject(
      () => client.post<dynamic>(
        '/usuarios/login',
        data: LoginRequestDto(email: email, contrasena: password).toJson(),
      ),
    );

    final LoginResponseDto tokens = _parse(
      () => LoginResponseDto.fromJson(body),
    );
    await tokenStore.save(
      token: tokens.token,
      refreshToken: tokens.refreshToken,
    );

    final UserProfile? profile = await currentUser();
    if (profile == null) {
      throw const UnknownFailure(detail: 'No se pudo cargar el perfil.');
    }
    return profile;
  }

  @override
  Future<void> logout() async {
    final AuthTokens? tokens = await tokenStore.read();
    try {
      if (tokens != null && tokens.refreshToken.isNotEmpty) {
        await _readObject(
          () => client.post<dynamic>(
            '/auth/logout',
            data: <String, Object?>{'refreshToken': tokens.refreshToken},
          ),
        );
      }
    } on AppFailure {
      // Cerrar sesión es local: si el backend no responde, los tokens se
      // borran igual (ver `docs/CONTEXT.md`, sección Autenticación y sesión).
    } finally {
      await tokenStore.clear();
    }
  }

  @override
  Future<UserProfile?> currentUser() async {
    if (!await hasSession()) {
      return null;
    }

    final Map<String, dynamic> body = await _readObject(
      () => client.get<dynamic>('/usuarios/me'),
    );
    return _parse(() => UserProfileDto.fromJson(body).toDomain());
  }

  @override
  Future<bool> hasSession() async {
    final AuthTokens? tokens = await tokenStore.read();
    return tokens != null;
  }

  /// Ejecuta la petición y devuelve su cuerpo como objeto JSON.
  Future<Map<String, dynamic>> _readObject(
    Future<Response<dynamic>> Function() request,
  ) async {
    final Response<dynamic> response = await request();
    final Map<String, dynamic>? body = _asJsonMap(response.data);
    if (body == null) {
      throw const UnknownFailure(
        detail: 'El servidor devolvió una respuesta inesperada.',
      );
    }
    return body;
  }

  /// Traduce un cuerpo con forma inválida a [UnknownFailure].
  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw const UnknownFailure(
        detail: 'El servidor devolvió una respuesta inesperada.',
      );
    }
  }

  Map<String, dynamic>? _asJsonMap(Object? data) {
    if (data is Map) {
      return data.map(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      );
    }
    if (data is String) {
      final String text = data.trim();
      if (text.isEmpty) {
        return null;
      }
      try {
        final Object? decoded = jsonDecode(text);
        if (decoded is Map) {
          return decoded.map(
            (Object? key, Object? value) => MapEntry(key.toString(), value),
          );
        }
      } on FormatException {
        return null;
      }
    }
    return null;
  }
}
