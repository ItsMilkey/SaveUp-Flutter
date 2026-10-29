import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import '../errors/problem_details.dart';
import 'dio_failure.dart';
import 'session_events.dart';
import 'token_store.dart';

/// Adjunta el access token y gestiona el refresh de sesión.
///
/// - Rutas públicas (login, register, refresh, logout, recuperación y versión)
///   nunca llevan `Authorization`.
/// - Ante `401 TOKEN_EXPIRADO` hace **un solo** refresh (single-flight: las
///   peticiones concurrentes comparten el mismo `Future`) y reintenta la
///   petición original **una sola vez**.
/// - Si el refresh falla con `REFRESH_INVALIDO` o el reintento vuelve a dar
///   401, borra los tokens y emite `SessionExpired`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStore,
    required this.refreshDio,
    required this.sessionEvents,
  });

  /// Marca en `RequestOptions.extra` para no reintentar dos veces.
  static const String retriedExtraKey = 'saveup_auth_retried';

  /// Rutas que no requieren token (comparadas por sufijo).
  static const Set<String> publicPaths = <String>{
    '/usuarios/register',
    '/usuarios/login',
    '/auth/refresh',
    '/auth/logout',
    '/auth/recuperar-contrasena',
    '/auth/restablecer-contrasena',
    '/app/version',
  };

  static bool isPublicPath(String path) =>
      publicPaths.any((String publicPath) => path.endsWith(publicPath));

  final TokenStore tokenStore;
  final Dio refreshDio;
  final SessionEvents sessionEvents;
  Future<AuthTokens?>? _refreshInFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (isPublicPath(options.path)) {
      handler.next(options);
      return;
    }

    final AuthTokens? tokens = await tokenStore.read();
    if (tokens != null && tokens.token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${tokens.token}';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRefresh(err)) {
      handler.next(err);
      return;
    }

    AuthTokens? tokens;
    try {
      tokens = await _refreshOnce();
    } on AppFailure catch (failure) {
      handler.reject(err.copyWith(error: failure));
      return;
    }

    if (tokens == null) {
      handler.reject(err.copyWith(error: const RefreshInvalidFailure()));
      return;
    }

    final RequestOptions request = err.requestOptions;
    request.headers['Authorization'] = 'Bearer ${tokens.token}';
    request.extra[retriedExtraKey] = true;

    try {
      final Response<dynamic> response =
          await refreshDio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await _expireSession();
      }
      handler.reject(retryError);
    }
  }

  bool _shouldRefresh(DioException error) {
    if (error.response?.statusCode != 401) {
      return false;
    }

    final RequestOptions request = error.requestOptions;
    if (isPublicPath(request.path)) {
      return false;
    }
    if (request.extra[retriedExtraKey] == true) {
      return false;
    }

    final AppFailure failure = failureFromProblemDetails(
      statusCode: 401,
      body: error.response?.data,
    );
    return failure is TokenExpiredFailure;
  }

  Future<AuthTokens?> _refreshOnce() {
    final Future<AuthTokens?>? inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final Future<AuthTokens?> future = _performRefresh();
    _refreshInFlight = future;
    future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    }).ignore();
    return future;
  }

  Future<AuthTokens?> _performRefresh() async {
    final AuthTokens? current = await tokenStore.read();
    if (current == null) {
      await _expireSession();
      return null;
    }

    try {
      final Response<dynamic> response = await refreshDio.post<dynamic>(
        '/auth/refresh',
        data: <String, dynamic>{'refreshToken': current.refreshToken},
      );

      final Map<String, dynamic>? body = _asJsonMap(response.data);
      final Object? rawToken = body?['token'];
      final Object? rawRefreshToken = body?['refreshToken'];
      if (rawToken is! String ||
          rawRefreshToken is! String ||
          rawToken.isEmpty ||
          rawRefreshToken.isEmpty) {
        throw const UnknownFailure(detail: 'Respuesta de refresh inválida.');
      }

      await tokenStore.save(token: rawToken, refreshToken: rawRefreshToken);
      return AuthTokens(token: rawToken, refreshToken: rawRefreshToken);
    } on DioException catch (error) {
      final AppFailure failure = failureFromDioException(error);
      if (failure is RefreshInvalidFailure ||
          error.response?.statusCode == 401) {
        await _expireSession();
        return null;
      }
      throw failure;
    }
  }

  Future<void> _expireSession() async {
    await tokenStore.clear();
    sessionEvents.emitExpired();
  }

  Map<String, dynamic>? _asJsonMap(Object? data) {
    if (data is Map) {
      return data.map(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      );
    }
    return null;
  }
}
