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
      if (options.path.endsWith('/colaboraciones/deudas-grupales/me')) {
        return jsonResponse(<Object?>[
          <String, Object?>{
            'id': 7,
            'nombre': 'Notebook',
            'descripcion': null,
            'acreedorExterno': 'Falabella',
            'montoTotal': 300000.00,
            'saldoPendiente': 210000.00,
            'estado': 'ACTIVA',
            'permisoEdicion': 'TODOS',
            'nombreCreador': 'Ana Test',
            'creadorActual': true,
            'participanteActual': true,
            'miResponsabilidadPendiente': 160000.00,
            'participantes': <Object?>[
              <String, Object?>{
                'id': 3,
                'nombre': 'Ana Test',
                'email': 'ana@example.com',
                'responsabilidadOriginal': 200000.00,
                'responsabilidadPendiente': 160000.00,
                'estado': 'ACTIVO',
                'actual': true,
              },
              <String, Object?>{
                'id': 4,
                'nombre': 'Bea Test',
                'email': 'bea@example.com',
                'responsabilidadOriginal': 100000.00,
                'responsabilidadPendiente': 50000.00,
                'estado': 'ACTIVO',
                'actual': false,
              },
            ],
            'cuotas': <Object?>[
              <String, Object?>{
                'numero': 1,
                'monto': 150000.00,
                'fechaVencimiento': '2026-12-10',
              },
            ],
            'creadoEn': '2026-11-27T14:10:41.686Z',
            'invitacionesPendientes': <Object?>[],
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
    expect(snapshot.deudasGrupales, hasLength(1));
    expect(snapshot.deudasGrupales.single.acreedorExterno, 'Falabella');
    expect(
      snapshot.deudasGrupales.single.estado,
      EstadoDeudaGrupal.activa,
    );
    expect(
      snapshot.deudasGrupales.single.miResponsabilidadPendiente,
      Decimal.parse('160000.00'),
    );
    expect(snapshot.deudasGrupales.single.activos, hasLength(2));
    expect(
      snapshot.deudasGrupales.single.cuotas.single.fechaVencimiento,
      CalendarDate(2026, 12, 10),
    );
    expect(
      adapter.requests.map((RequestOptions request) => request.uri.path).toSet(),
      <String>{
        '/api/v1/colaboraciones/metas/me',
        '/api/v1/colaboraciones/deudas-directas/me',
        '/api/v1/colaboraciones/deudas-grupales/me',
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

  test('crea deuda grupal con reparto y cuotas personalizadas', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'POST');
      expect(options.path.endsWith('/colaboraciones/deudas-grupales'), isTrue);
      expect(jsonBodyOf(options), <String, Object?>{
        'nombre': 'Notebook',
        'descripcion': 'Crédito compartido',
        'acreedorExterno': 'Falabella',
        'montoTotal': 300000.00,
        'permisoEdicion': 'TODOS',
        'participantes': <Map<String, Object?>>[
          <String, Object?>{
            'email': 'ana@example.com',
            'monto': 200000.00,
          },
          <String, Object?>{
            'email': 'bea@example.com',
            'monto': 100000.00,
          },
        ],
        'cuotas': <Map<String, Object?>>[
          <String, Object?>{
            'monto': 150000.00,
            'fechaVencimiento': '2026-12-10',
          },
        ],
      });
      return jsonResponse(<String, Object?>{
        'deuda': <String, Object?>{'id': 7, 'estado': 'PENDIENTE'},
        'invitaciones': <Object?>[
          <String, Object?>{
            'id': 15,
            'tipoRecurso': 'DEUDA_GRUPAL',
            'recursoId': 7,
            'nombreRecurso': 'Notebook',
            'nombreCreador': 'Ana Test',
            'emailInvitado': 'bea@example.com',
            'estado': 'PENDIENTE',
            'expiraEn': '2026-12-04T12:00:00.000Z',
            'codigo': 'codigo-opaco',
            'acreedorExterno': 'Falabella',
            'montoTotal': 300000.00,
            'responsabilidadInvitada': 100000.00,
          },
        ],
      });
    };

    final List<InvitacionColaborativa> invitaciones =
        await repository.crearDeudaGrupal(
      DeudaGrupalDatos(
        nombre: 'Notebook',
        descripcion: 'Crédito compartido',
        acreedorExterno: 'Falabella',
        montoTotal: Decimal.parse('300000.00'),
        permisoEdicion: PermisoEdicionCompartida.todos,
        participantes: <ResponsabilidadParticipante>[
          ResponsabilidadParticipante(
            email: 'ana@example.com',
            monto: Decimal.parse('200000.00'),
          ),
          ResponsabilidadParticipante(
            email: 'bea@example.com',
            monto: Decimal.parse('100000.00'),
          ),
        ],
        cuotas: <CuotaGrupalDatos>[
          CuotaGrupalDatos(
            monto: Decimal.parse('150000.00'),
            fechaVencimiento: CalendarDate(2026, 12, 10),
          ),
        ],
      ),
    );

    expect(invitaciones.single.esDeudaGrupal, isTrue);
    expect(invitaciones.single.acreedorExterno, 'Falabella');
    expect(invitaciones.single.codigo, 'codigo-opaco');
    expect(
      invitaciones.single.responsabilidadInvitada,
      Decimal.parse('100000.00'),
    );
  });

  test('un pago grupal envía monto e imputaciones y parsea el resultado', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'POST');
      expect(
        options.path.endsWith('/colaboraciones/deudas-grupales/7/pagos'),
        isTrue,
      );
      expect(jsonBodyOf(options), <String, Object?>{
        'monto': 90000.00,
        'descripcion': 'Cuota 1',
        'imputaciones': <Map<String, Object?>>[
          <String, Object?>{
            'email': 'ana@example.com',
            'monto': 50000.00,
          },
          <String, Object?>{
            'email': 'bea@example.com',
            'monto': 40000.00,
          },
        ],
      });
      return jsonResponse(<String, Object?>{
        'id': 3,
        'tipoRecurso': 'DEUDA_GRUPAL',
        'recursoId': 7,
        'tipo': 'PAGO_GRUPAL',
        'monto': 90000.00,
        'descripcion': 'Cuota 1',
        'registradoPor': 'Bea Test',
        'atribuidoA': null,
        'estado': 'PENDIENTE',
        'creadoEn': '2026-11-27T14:10:51.518Z',
        'imputacionesPago': <Object?>[
          <String, Object?>{
            'email': 'ana@example.com',
            'nombre': 'Ana Test',
            'monto': 50000.00,
          },
          <String, Object?>{
            'email': 'bea@example.com',
            'nombre': 'Bea Test',
            'monto': 40000.00,
          },
        ],
        'cambiosResponsabilidad': <Object?>[],
      });
    };

    final OperacionColaborativa result = await repository.registrarPagoGrupal(
      7,
      PagoGrupalDatos(
        monto: Decimal.parse('90000.00'),
        descripcion: 'Cuota 1',
        imputaciones: <ImputacionPagoDatos>[
          ImputacionPagoDatos(
            email: 'ana@example.com',
            monto: Decimal.parse('50000.00'),
          ),
          ImputacionPagoDatos(
            email: 'bea@example.com',
            monto: Decimal.parse('40000.00'),
          ),
        ],
      ),
    );

    expect(result.esPagoGrupal, isTrue);
    expect(result.estado, EstadoColaborativo.pendiente);
    expect(result.imputacionesPago, hasLength(2));
    expect(result.imputacionesPago.first.nombre, 'Ana Test');
    expect(result.imputacionesPago.last.monto, Decimal.parse('40000.00'));
    expect(result.cambiosResponsabilidad, isEmpty);
  });

  test('proponer reparto y salir de la deuda grupal usan sus rutas', () async {
    adapter.handler = (RequestOptions options) async {
      if (options.method == 'PUT' &&
          options.path.endsWith('/colaboraciones/deudas-grupales/7/repartos')) {
        expect(jsonBodyOf(options), <String, Object?>{
          'responsabilidades': <Map<String, Object?>>[
            <String, Object?>{'email': 'ana@example.com', 'monto': 200000.00},
          ],
        });
        return jsonResponse(<String, Object?>{
          'id': 8,
          'tipoRecurso': 'DEUDA_GRUPAL',
          'recursoId': 7,
          'tipo': 'CAMBIO_REPARTO',
          'monto': 200000.00,
          'descripcion': 'Reparto',
          'registradoPor': 'Ana Test',
          'estado': 'PENDIENTE',
          'creadoEn': '2026-11-27T15:00:00.000Z',
          'cambiosResponsabilidad': <Object?>[
            <String, Object?>{
              'email': 'ana@example.com',
              'nombre': 'Ana Test',
              'monto': 200000.00,
            },
          ],
        });
      }
      if (options.method == 'POST' &&
          options.path.endsWith('/colaboraciones/deudas-grupales/7/salir')) {
        expect(jsonBodyOf(options), <String, Object?>{
          'reasignaciones': <Map<String, Object?>>[
            <String, Object?>{'email': 'ana@example.com', 'monto': 50000.00},
          ],
        });
        return jsonResponse(<String, Object?>{
          'id': 9,
          'tipoRecurso': 'DEUDA_GRUPAL',
          'recursoId': 7,
          'tipo': 'SALIDA_DEUDA',
          'monto': 50000.00,
          'descripcion': 'Salida',
          'registradoPor': 'Bea Test',
          'estado': 'PENDIENTE',
          'creadoEn': '2026-11-27T15:05:00.000Z',
          'cambiosResponsabilidad': <Object?>[
            <String, Object?>{'email': 'bea@example.com', 'nombre': 'Bea Test', 'monto': 0},
          ],
        });
      }
      throw StateError('Ruta inesperada: ${options.method} ${options.path}');
    };

    final OperacionColaborativa reparto = await repository.proponerCambioReparto(
      7,
      RepartoDatos(
        responsabilidades: <ResponsabilidadParticipante>[
          ResponsabilidadParticipante(
            email: 'ana@example.com',
            monto: Decimal.parse('200000.00'),
          ),
        ],
      ),
    );
    expect(reparto.esCambioReparto, isTrue);
    expect(reparto.cambiosResponsabilidad.single.monto, Decimal.parse('200000.00'));

    final OperacionColaborativa salida = await repository.salirDeudaGrupal(
      7,
      SalidaDeudaDatos(
        reasignaciones: <ResponsabilidadParticipante>[
          ResponsabilidadParticipante(
            email: 'ana@example.com',
            monto: Decimal.parse('50000.00'),
          ),
        ],
      ),
    );
    expect(salida.esSalidaDeuda, isTrue);
  });
}
