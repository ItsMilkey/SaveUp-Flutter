import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/token_store.dart';
import 'package:saveup_app/features/movimientos/domain/movimiento_tipo.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/test_app.dart';

Map<String, Object?> meBody() => <String, Object?>{
  'rut': '12345678-5',
  'nombre': 'Ana',
  'apellido': 'Primerahija',
  'email': 'ana@example.cl',
  'fechaRegistro': '2026-01-15T10:30:00.000Z',
};

Map<String, Object?> movimientoJson({
  required int id,
  required num monto,
  required String descripcion,
  String fecha = '2026-11-05T12:00:00.000Z',
  String tipo = 'GASTO_GENERAL',
  String categoria = 'Alimentación Básica',
}) => <String, Object?>{
  'id': id,
  'monto': monto,
  'descripcion': descripcion,
  'fecha': fecha,
  'tipoMovimiento': tipo,
  'categoria': <String, Object?>{
    'id': 1,
    'codigo': 'ALIMENTACION_BASE',
    'nombre': categoria,
  },
};

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStore tokenStore;

  setUp(() {
    adapter = FakeHttpAdapter();
    tokenStore = InMemoryTokenStore();
    tokenStore.save(token: 'jwt.vigente', refreshToken: 'refresh.vigente');
  });

  Future<void> abrirHome(WidgetTester tester) async {
    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra saldo formateado CLP y los movimientos', (
    WidgetTester tester,
  ) async {
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/me')) {
        return jsonResponse(meBody());
      }
      if (options.path.endsWith('/saldos/me')) {
        return saldoResponse(saldo: -12500);
      }
      if (options.path.endsWith('/movimientos/paginados/me')) {
        return jsonResponse(<String, Object?>{
          'content': <Object?>[
            movimientoJson(
              id: 1,
              monto: -12500,
              descripcion: 'Supermercado',
            ),
            movimientoJson(
              id: 2,
              monto: 50000,
              descripcion: 'Sueldo',
              tipo: 'INGRESO_GENERAL',
              categoria: 'Sueldo',
            ),
          ],
          'currentPage': 0,
          'totalItems': 2,
          'totalPages': 1,
        });
      }
      fail('petición inesperada: ${options.path}');
    };

    await abrirHome(tester);

    // Saldo y monto del movimiento de gasto (mismo valor, ambos visibles).
    expect(find.text(r'-$12.500'), findsNWidgets(2));
    expect(find.text('Supermercado'), findsOneWidget);
    expect(find.text('Sueldo'), findsOneWidget);
    expect(find.textContaining('· Sueldo'), findsOneWidget);
    expect(find.text(r'$50.000'), findsOneWidget);
    expect(
      find.textContaining('05-11-2026'),
      findsNWidgets(2),
    );
    expect(find.text('2 movimiento(s)'), findsOneWidget);
  });

  testWidgets('scroll infinito pide la página siguiente y se detiene', (
    WidgetTester tester,
  ) async {
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/me')) {
        return jsonResponse(meBody());
      }
      if (options.path.endsWith('/saldos/me')) {
        return saldoResponse(saldo: 100000);
      }
      if (options.path.endsWith('/movimientos/paginados/me')) {
        final int page = options.queryParameters['page'] as int;
        expect(options.queryParameters['size'], 50);
        if (page == 0) {
          return jsonResponse(<String, Object?>{
            'content': <Object?>[
              for (int i = 1; i <= 10; i++)
                movimientoJson(
                  id: i,
                  monto: -1000,
                  descripcion: 'Movimiento $i',
                ),
            ],
            'currentPage': 0,
            'totalItems': 11,
            'totalPages': 2,
          });
        }
        return jsonResponse(<String, Object?>{
          'content': <Object?>[
            movimientoJson(id: 11, monto: -3000, descripcion: 'Once'),
          ],
          'currentPage': 1,
          'totalItems': 11,
          'totalPages': 2,
        });
      }
      fail('petición inesperada: ${options.path}');
    };

    await abrirHome(tester);
    expect(find.text('Movimiento 1'), findsOneWidget);
    expect(find.text('Once'), findsNothing);

    // Llegar cerca del final dispara la siguiente página.
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('Once'), findsOneWidget);
    expect(find.text('No hay más movimientos.'), findsOneWidget);
    expect(
      adapter.requests.where(
        (RequestOptions r) =>
            r.path.endsWith('/movimientos/paginados/me') &&
            r.queryParameters['page'] == 1,
      ),
      hasLength(1),
    );
  });

  testWidgets('filtrar por tipo reinicia el listado desde page=0', (
    WidgetTester tester,
  ) async {
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/me')) {
        return jsonResponse(meBody());
      }
      if (options.path.endsWith('/saldos/me')) {
        return saldoResponse();
      }
      if (options.path.endsWith('/movimientos/paginados/me')) {
        final bool filtrado =
            options.queryParameters['tipoMovimiento'] == 'GASTO_GENERAL';
        if (filtrado) {
          return paginaVaciaResponse();
        }
        return jsonResponse(<String, Object?>{
          'content': <Object?>[
            movimientoJson(id: 1, monto: 50000, descripcion: 'Sueldo'),
          ],
          'currentPage': 0,
          'totalItems': 1,
          'totalPages': 1,
        });
      }
      fail('petición inesperada: ${options.path}');
    };

    await abrirHome(tester);
    expect(find.text('Cargando movimientos…'), findsNothing);

    await tester.tap(find.byType(DropdownButton<MovimientoTipo>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gasto').last);
    await tester.pumpAndSettle();

    // Petición con el filtro y reinicio en page 0.
    final RequestOptions ultima = adapter.requests.lastWhere(
      (RequestOptions r) => r.path.endsWith('/movimientos/paginados/me'),
    );
    expect(ultima.queryParameters['tipoMovimiento'], 'GASTO_GENERAL');
    expect(ultima.queryParameters['page'], 0);
    expect(find.text('No hay movimientos para estos filtros.'), findsOneWidget);
    expect(find.text('Quitar filtros'), findsOneWidget);

    // Quitar filtros vuelve a pedir sin tipoMovimiento.
    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();
    final RequestOptions sinFiltro = adapter.requests.lastWhere(
      (RequestOptions r) => r.path.endsWith('/movimientos/paginados/me'),
    );
    expect(sinFiltro.queryParameters.containsKey('tipoMovimiento'), isFalse);
    expect(find.text('Sueldo'), findsOneWidget);
  });
}
