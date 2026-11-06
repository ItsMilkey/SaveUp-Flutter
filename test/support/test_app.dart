import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saveup_app/app/router.dart';
import 'package:saveup_app/app/theme.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/core/network/session_events.dart';
import 'package:saveup_app/core/network/token_store.dart';
import 'package:saveup_app/features/app_version/data/app_version_sources.dart';
import 'package:saveup_app/features/app_version/domain/app_platform.dart';

import 'fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

/// Arma la app completa (router + splash + providers) sobre un Dio falso,
/// tokens en memoria y versión compilada fija `1.2.0`.
ProviderScope testApp({
  required FakeHttpAdapter adapter,
  required InMemoryTokenStore tokenStore,
  SessionEvents? sessionEvents,
}) {
  return ProviderScope(
    overrides: [
      dioProvider.overrideWith(
        (Ref ref) =>
            Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter,
      ),
      refreshDioProvider.overrideWith(
        (Ref ref) =>
            Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter,
      ),
      tokenStoreProvider.overrideWith((Ref ref) => tokenStore),
      if (sessionEvents != null)
        sessionEventsProvider.overrideWith((Ref ref) => sessionEvents),
      appVersionReaderProvider.overrideWith((Ref ref) {
        return () async => '1.2.0';
      }),
      appPlatformProvider.overrideWith((Ref ref) => AppPlatform.android),
    ],
    child: Consumer(
      builder: (BuildContext context, WidgetRef ref, _) {
        return MaterialApp.router(
          title: 'SaveUp',
          theme: AppTheme.light(),
          routerConfig: ref.watch(routerProvider),
        );
      },
    ),
  );
}

/// Respuesta estándar de `GET /app/version` al día (sin bloqueos ni
/// sugerencias).
ResponseBody versionResponse() => jsonResponse(<String, Object?>{
  'actualizacionObligatoria': false,
  'actualizacionSugerida': false,
  'mensaje': '',
  'urlTienda': 'https://play.google.com/apps',
  'versionTerminos': 'v1.2',
  'versionPrivacidad': 'v1',
});

/// Respuesta estándar de `GET /saldos/me`.
ResponseBody saldoResponse({num saldo = 0}) =>
    jsonResponse(<String, Object?>{'saldo': saldo});

/// Página vacía de `GET /movimientos/paginados/me`.
ResponseBody paginaVaciaResponse() => jsonResponse(<String, Object?>{
  'content': <Object?>[],
  'currentPage': 0,
  'totalItems': 0,
  'totalPages': 0,
});
