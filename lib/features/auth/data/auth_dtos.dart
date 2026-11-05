import '../../../core/time/instants.dart';
import '../domain/user_profile.dart';

/// DTOs escritos a mano para los endpoints de cuenta y sesión.
///
/// La forma de cada campo viene de `docs/contrato/openapi.json`; cualquier
/// campo obligatorio ausente se reporta como [FormatException] y la capa de
/// datos lo traduce a una falla de la app.

/// Cuerpo de `POST /usuarios/register`.
class RegisterRequestDto {
  const RegisterRequestDto({
    required this.rut,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.contrasena,
  });

  final String rut;
  final String nombre;
  final String apellido;
  final String email;
  final String contrasena;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'rut': rut,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'contrasena': contrasena,
    };
  }
}

/// Cuerpo de `POST /usuarios/login`.
class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.contrasena});

  final String email;
  final String contrasena;

  Map<String, Object?> toJson() {
    return <String, Object?>{'email': email, 'contrasena': contrasena};
  }
}

/// Respuesta de `POST /usuarios/login` y de `POST /auth/refresh`.
///
/// `expiraEn` no se guarda: el interceptor de sesión reacciona al
/// `401 TOKEN_EXPIRADO` y refresca una sola vez, sin depender del reloj local.
class LoginResponseDto {
  const LoginResponseDto({required this.token, required this.refreshToken});

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      token: _requireString(json, 'token'),
      refreshToken: _requireString(json, 'refreshToken'),
    );
  }

  final String token;
  final String refreshToken;
}

/// Respuesta de `GET /usuarios/me`.
class UserProfileDto {
  const UserProfileDto({
    required this.rut,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.fechaRegistro,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      rut: _requireString(json, 'rut'),
      nombre: _requireString(json, 'nombre'),
      apellido: _requireString(json, 'apellido'),
      email: _requireString(json, 'email'),
      fechaRegistro: parseInstant(_requireString(json, 'fechaRegistro')),
    );
  }

  final String rut;
  final String nombre;
  final String apellido;
  final String email;
  final DateTime fechaRegistro;

  UserProfile toDomain() {
    return UserProfile(
      rut: rut,
      nombre: nombre,
      apellido: apellido,
      email: email,
      fechaRegistro: fechaRegistro,
    );
  }
}

String _requireString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Falta el campo obligatorio "$key".');
  }
  return value;
}
