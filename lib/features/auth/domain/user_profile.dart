/// Perfil del usuario autenticado (`GET /usuarios/me`).
///
/// Nunca incluye la contraseña; el backend la omite a propósito.
class UserProfile {
  const UserProfile({
    required this.rut,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.fechaRegistro,
  });

  /// RUT normalizado, con guion y dígito verificador (`12345678-9`).
  final String rut;

  /// Nombre de pila.
  final String nombre;

  /// Apellido.
  final String apellido;

  /// Correo electrónico de la cuenta.
  final String email;

  /// Instante UTC en que se registró la cuenta.
  final DateTime fechaRegistro;

  /// Nombre completo listo para mostrar.
  String get fullName => '$nombre $apellido'.trim();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserProfile &&
            other.rut == rut &&
            other.nombre == nombre &&
            other.apellido == apellido &&
            other.email == email &&
            other.fechaRegistro == fechaRegistro;
  }

  @override
  int get hashCode => Object.hash(rut, nombre, apellido, email, fechaRegistro);

  @override
  String toString() => 'UserProfile(rut: $rut, email: $email)';
}
