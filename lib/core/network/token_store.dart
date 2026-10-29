import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Par de tokens de sesión que entrega `login`/`refresh`.
class AuthTokens {
  const AuthTokens({
    required this.token,
    required this.refreshToken,
    this.expiresAt,
  });

  /// Access token (JWT), válido 15 minutos.
  final String token;

  /// Refresh token rotativo, válido 90 días.
  final String refreshToken;

  /// Cuándo expira [token], si el backend lo informó (`expiraEn`).
  final DateTime? expiresAt;
}

/// Almacenamiento de la sesión.
///
/// Los tokens viven **solo** en `flutter_secure_storage` (Keychain/Keystore);
/// nunca en `SharedPreferences`, logs ni código fuente.
abstract interface class TokenStore {
  Future<AuthTokens?> read();

  Future<void> save({required String token, required String refreshToken});

  Future<void> clear();
}

/// Implementación real sobre `flutter_secure_storage`.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  /// Clave del access token.
  static const String tokenKey = 'saveup_jwt';

  /// Clave del refresh token.
  static const String refreshKey = 'saveup_refresh';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final String? token = await _storage.read(key: tokenKey);
    final String? refresh = await _storage.read(key: refreshKey);
    if (token == null || refresh == null || token.isEmpty) {
      return null;
    }
    return AuthTokens(token: token, refreshToken: refresh);
  }

  @override
  Future<void> save({
    required String token,
    required String refreshToken,
  }) async {
    await _storage.write(key: tokenKey, value: token);
    await _storage.write(key: refreshKey, value: refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: refreshKey);
  }
}

/// Implementación en memoria, solo para pruebas.
class InMemoryTokenStore implements TokenStore {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> save({
    required String token,
    required String refreshToken,
  }) async {
    _tokens = AuthTokens(token: token, refreshToken: refreshToken);
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}

final Provider<TokenStore> tokenStoreProvider = Provider<TokenStore>(
  (Ref ref) => SecureTokenStore(),
);
