import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/core/time/calendar_date.dart';
import 'package:saveup_app/features/colaboraciones/data/dio_colaboraciones_repository.dart';
import 'package:saveup_app/features/colaboraciones/domain/colaboracion.dart';

import '../../support/fake_http_adapter.dart';

const String _baseUrl = 'http://localhost:8080/api/v1';

void main() {
  late FakeHttpAdapter adapter;
  late DioColaboracionesRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: _baseUrl))
      ..httpClientAdapter = adapter;
    repository = DioColaboracionesRepository(client: ApiClient(dio));
  });

  test('carga metas, deudas, invitaciones y actividad desde las rutas T11', () async {
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/colaboraciones/metas/me')) {
        return jsonResponse(<Object?>[
          <String, Object?>{
            'id': 4,
            'nombre': 'Viaje',
            'montoObjetivo': 500.00,
            'fechaLimite': '2027-01-15',
            'montoActual': 125.25,
            'estado': 'ACTIVA',
            'permisoEdicion': 'TODOS',
            'participantes': <Object?>[
              <String, Object?>{
                'id': 2,
                'nombre': 'Ana Test',
                'email': 'ana@example.com',
                'creador': true,
                'actual': true,
              },
            ],
          },
        ]);
      }
      if (options.path.endsWith('/colaboraciones/deudas-directas/me') ||
          options.path.endsWith('/colaboraciones/invitaciones/me') ||
          options.path.endsWith('/colaboraciones/actividad/me')) {
        return jsonResponse(<Object?>[]);
      }
      throw StateError('Ruta inesperada: ${options.path}');
    };

    final SnapshotColaboraciones snapshot = await repository.cargar();

    expect(snapshot.metas, hasLength(1));
    expect(snapshot.metas.single.nombre, 'Viaje');
    expect(snapshot.metas.single.montoActual, Decimal.parse('125.25'));
    expect(snapshot.metas.single.fechaLimite, CalendarDate(2027, 1, 15));
    expect(snapshot.metas.single.participantes.single.actual, isTrue);
    expect(snapshot.deudas, isEmpty);
    expect(
      adapter.requests.map((RequestOptions request) => request.uri.path).toSet(),
      <String>{
        '/api/v1/colaboraciones/metas/me',
        '/api/v1/colaboraciones/deudas-directas/me',
        '/api/v1/colaboraciones/invitaciones/me',
        '/api/v1/colaboraciones/actividad/me',
      },
    );
  });

  test('crea meta con montos Decimal y devuelve el código solo en la respuesta', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'POST');
      expect(options.path.endsWith('/colaboraciones/metas'), isTrue);
      expect(jsonBodyOf(options), <String, Object?>{
        'nombre': 'Viaje',
        'montoObjetivo': 500.25,
        'fechaLimite': '2027-01-15',
        'permisoEdicion': 'TODOS',
        'emailsInvitados': <String>['bea@example.com'],
      });
      return jsonResponse(<String, Object?>{
        'meta': <String, Object?>{
          'id': 4,
          'nombre': 'Viaje',
          'montoActual': 0.00,
          'compartida': true,
          'estadoCompartida': 'PENDIENTE',
        },
        'invitaciones': <Object?>[
          <String, Object?>{
            'id': 9,
            'tipoRecurso': 'META',
            'recursoId': 4,
            'nombreRecurso': 'Viaje',
            'nombreCreador': 'Ana Test',
            'emailInvitado': 'bea@example.com',
            'estado': 'PENDIENTE',
            'expiraEn': '2026-12-03T12:00:00.000Z',
            'codigo': 'codigo-opaco',
          },
        ],
      });
    };

    final List<InvitacionColaborativa> invitaciones = await repository.crearMeta(
      MetaCompartidaDatos(
        nombre: 'Viaje',
        montoObjetivo: Decimal.parse('500.25'),
        fechaLimite: CalendarDate(2027, 1, 15),
        permisoEdicion: PermisoEdicionCompartida.todos,
        emailsInvitados: <String>['bea@example.com'],
      ),
    );

    expect(invitaciones.single.codigo, 'codigo-opaco');
    expect(invitaciones.single.expiraEn, DateTime.parse('2026-12-03T12:00:00.000Z'));
  });

  test('un aporte atribuido a otra persona envía emailAtribucion', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.path.endsWith('/colaboraciones/metas/4/aportes'), isTrue);
      expect(jsonBodyOf(options), <String, Object?>{
        'monto': 25,
        'descripcion': 'Aporte',
        'emailAtribucion': 'bea@example.com',
      });
      return jsonResponse(<String, Object?>{
        'id': 12,
        'tipoRecurso': 'META',
        'recursoId': 4,
        'tipo': 'APORTE_META',
        'monto': 25.00,
        'descripcion': 'Aporte',
        'registradoPor': 'Ana Test',
        'atribuidoA': 'Bea Test',
        'estado': 'PENDIENTE',
        'creadoEn': '2026-11-26T12:00:00.000Z',
        'atribuciones': <Object?>[],
      });
    };

    final OperacionColaborativa result = await repository.registrarAporte(
      4,
      monto: Decimal.parse('25.00'),
      descripcion: 'Aporte',
      emailAtribucion: 'bea@example.com',
    );

    expect(result.estado, EstadoColaborativo.pendiente);
    expect(result.atribuidoA, 'Bea Test');
  });
}
