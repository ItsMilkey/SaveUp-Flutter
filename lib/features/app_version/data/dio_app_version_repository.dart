import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../domain/app_platform.dart';
import '../domain/app_version_info.dart';
import '../domain/app_version_repository.dart';

/// Respuesta de `GET /app/version`.
///
/// La forma de cada campo viene de `AppVersionResponseDTO` en
/// `docs/contrato/openapi.json`; los seis campos son obligatorios.
class AppVersionResponseDto {
  const AppVersionResponseDto({
    required this.actualizacionObligatoria,
    required this.actualizacionSugerida,
    required this.mensaje,
    required this.urlTienda,
    required this.versionTerminos,
    required this.versionPrivacidad,
  });

  factory AppVersionResponseDto.fromJson(Map<String, dynamic> json) {
    return AppVersionResponseDto(
      actualizacionObligatoria: _requireBool(json, 'actualizacionObligatoria'),
      actualizacionSugerida: _requireBool(json, 'actualizacionSugerida'),
      mensaje: _requireString(json, 'mensaje'),
      urlTienda: _requireString(json, 'urlTienda'),
      versionTerminos: _requireString(json, 'versionTerminos'),
      versionPrivacidad: _requireString(json, 'versionPrivacidad'),
    );
  }

  final bool actualizacionObligatoria;
  final bool actualizacionSugerida;
  final String mensaje;
  final String urlTienda;
  final String versionTerminos;
  final String versionPrivacidad;
}

/// Implementación de [AppVersionRepository] sobre el cliente HTTP de la app.
///
/// Los errores llegan ya traducidos a `AppFailure` por `codigo`; el
/// controlador decide degradar cuando la falla es de red o timeout.
class DioAppVersionRepository implements AppVersionRepository {
  const DioAppVersionRepository({required this.client});

  final ApiClient client;

  @override
  Future<AppVersionInfo> fetch({
    required AppPlatform platform,
    required String version,
  }) async {
    final Response<dynamic> response = await client.get<dynamic>(
      '/app/version',
      queryParameters: <String, dynamic>{
        'plataforma': platform.apiValue,
        'version': version,
      },
    );

    final Object? data = response.data;
    if (data is! Map) {
      throw const UnknownFailure(
        detail: 'El servidor devolvió una respuesta inesperada.',
      );
    }
    final Map<String, dynamic> json = data.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );

    final AppVersionResponseDto dto = _parse(
      () => AppVersionResponseDto.fromJson(json),
    );
    return AppVersionInfo(
      actualizacionObligatoria: dto.actualizacionObligatoria,
      actualizacionSugerida: dto.actualizacionSugerida,
      mensaje: dto.mensaje,
      urlTienda: dto.urlTienda,
      versionTerminos: dto.versionTerminos,
      versionPrivacidad: dto.versionPrivacidad,
    );
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw const UnknownFailure(
        detail: 'El servidor devolvió una respuesta inesperada.',
      );
    }
  }
}

final Provider<AppVersionRepository> appVersionRepositoryProvider =
    Provider<AppVersionRepository>((Ref ref) {
      return DioAppVersionRepository(client: ref.watch(apiClientProvider));
    });

String _requireString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! String) {
    throw FormatException('Falta el campo obligatorio "$key".');
  }
  return value;
}

bool _requireBool(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! bool) {
    throw FormatException('Falta el campo obligatorio "$key".');
  }
  return value;
}
