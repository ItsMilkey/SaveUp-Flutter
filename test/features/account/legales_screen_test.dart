import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/token_store.dart';
import 'package:saveup_app/features/account/presentation/legales_screen.dart';
import 'package:saveup_app/features/app_version/presentation/app_version_controller.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/test_app.dart';

Map<String, Object?> meBody() => <String, Object?>{
  'rut': '12345678-5',
  'nombre': 'Ana',
  'apellido': 'Primerahija',
  'email': 'ana@example.cl',
  'fechaRegistro': '2026-01-15T10:30:00.000Z',
};

/// Versión con versión legales v1.2 / v1 (igual a `versionResponse`).
Map<String, Object?> versionJson() => <String, Object?>{
  'actualizacionObligatoria': false,
  'actualizacionSugerida': false,
  'mensaje': '',
  'urlTienda': 'https://play.google.com/apps',
  'versionTerminos': 'v1.2',
  'versionPrivacidad': 'v1',
};

/// Arranca la app y navega a /legales desde donde indique [desde].
Future<void> abrirLegales(
  WidgetTester tester, {
  required FakeHttpAdapter adapter,
  required InMemoryTokenStore tokenStore,
  bool conSesion = false,
}) async {
  adapter.handler = (RequestOptions options) async {
    if (options.path.endsWith('/app/version')) {
      return jsonResponse(versionJson());
    }
    if (options.path.endsWith('/usuarios/me')) {
      return jsonResponse(meBody());
    }
    if (options.path.endsWith('/saldos/me')) {
      return saldoResponse();
    }
    if (options.path.endsWith('/movimientos/paginados/me')) {
      return paginaVaciaResponse();
    }
    fail('petición inesperada: ${options.path}');
  };

  if (conSesion) {
    await tokenStore.save(token: 'jwt.vigente', refreshToken: 'refresh.vigente');
  }
  await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
  await tester.pumpAndSettle();

  if (conSesion) {
    // Con sesión el visor vive en el menú de cuenta del home real.
    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Términos y privacidad'));
  await tester.pumpAndSettle();
}

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStore tokenStore;

  setUp(() {
    adapter = FakeHttpAdapter();
    tokenStore = InMemoryTokenStore();
  });

  testWidgets('accesible desde login (sin sesión) con las versiones vigentes', (
    WidgetTester tester,
  ) async {
    await abrirLegales(tester, adapter: adapter, tokenStore: tokenStore);

    // Cabecera del documento con la versión que entregó /app/version.
    expect(
      find.textContaining('Términos y Condiciones de Uso — versión v1.2'),
      findsOneWidget,
    );
    // Texto provisional marcado como tal.
    expect(find.textContaining('TEXTO PROVISIONAL'), findsWidgets);
    // Pie con ambas versiones.
    expect(
      find.textContaining('Términos v1.2 · Privacidad v1'),
      findsOneWidget,
    );
  });

  testWidgets('accesible desde home (con sesión activa)', (
    WidgetTester tester,
  ) async {
    await abrirLegales(
      tester,
      adapter: adapter,
      tokenStore: tokenStore,
      conSesion: true,
    );

    expect(find.textContaining('Términos v1.2 · Privacidad v1'), findsOneWidget);
  });

  testWidgets('pestañas Términos y Privacidad muestran sus documentos', (
    WidgetTester tester,
  ) async {
    await abrirLegales(tester, adapter: adapter, tokenStore: tokenStore);

    expect(
      find.textContaining('Términos y Condiciones de Uso — versión v1.2'),
      findsOneWidget,
    );
    await tester.tap(find.text('Política de Privacidad'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Política de Privacidad — versión v1'),
      findsOneWidget,
    );
  });

  testWidgets('sin versiones informadas (degradado) no se bloquea el visor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          legalVersionsProvider.overrideWith(() => _LegalesNulas()),
        ],
        child: const MaterialApp(home: LegalesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('no disponible'), findsNWidgets(3));
  });
}

/// Controlador forzado a null para la prueba del degradado.
class _LegalesNulas extends LegalVersionsController {
  @override
  LegalVersions? build() => null;
}
