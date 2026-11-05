import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/features/app_version/data/dio_app_version_repository.dart';
import 'package:saveup_app/features/app_version/domain/app_version_info.dart';
import 'package:saveup_app/features/app_version/domain/app_platform.dart';

import '../../support/fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

Map<String, Object?> versionJson({
  bool obligatoria = false,
  bool sugerida = false,
}) => <String, Object?>{
  'actualizacionObligatoria': obligatoria,
  'actualizacionSugerida': sugerida,
  'mensaje': 'Hay una nueva versión.',
  'urlTienda': 'https://play.google.com/store/apps/saveup',
  'versionTerminos': 'v1.2',
  'versionPrivacidad': 'v3',
};

void main() {
  late FakeHttpAdapter adapter;
  late DioAppVersionRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    repository = DioAppVersionRepository(client: ApiClient(dio));
  });

  test('envía plataforma y versión; parsea los seis campos', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.path.endsWith('/app/version'), isTrue);
      expect(options.queryParameters['plataforma'], 'ANDROID');
      expect(options.queryParameters['version'], '1.2.3');
      return jsonResponse(versionJson());
    };

    final AppVersionInfo info = await repository.fetch(
      platform: AppPlatform.android,
      version: '1.2.3',
    );

    expect(info.actualizacionObligatoria, isFalse);
    expect(info.actualizacionSugerida, isFalse);
    expect(info.mensaje, 'Hay una nueva versión.');
    expect(info.urlTienda, endsWith('saveup'));
    expect(info.versionTerminos, 'v1.2');
    expect(info.versionPrivacidad, 'v3');
  });

  test('IOS mapea su valor del enum', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.queryParameters['plataforma'], 'IOS');
      return jsonResponse(versionJson());
    };

    await repository.fetch(platform: AppPlatform.ios, version: '9.9.9');
  });

  test('PARAMETRO_INVALIDO (400) se propaga como AppFailure', () async {
    adapter.handler = (RequestOptions options) async =>
        problemResponse('PARAMETRO_INVALIDO');

    await expectLater(
      repository.fetch(platform: AppPlatform.android, version: '1.2.3'),
      throwsA(isA<AppFailure>()),
    );
  });

  test('cuerpo sin campo obligatorio llega como UnknownFailure', () async {
    adapter.handler = (RequestOptions options) async =>
        jsonResponse(<String, Object?>{'mensaje': 'hola'});

    await expectLater(
      repository.fetch(platform: AppPlatform.android, version: '1.2.3'),
      throwsA(isA<UnknownFailure>()),
    );
  });
}
