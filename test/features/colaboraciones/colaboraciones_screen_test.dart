import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/core/time/calendar_date.dart';
import 'package:saveup_app/features/auth/domain/auth_session.dart';
import 'package:saveup_app/features/auth/domain/user_profile.dart';
import 'package:saveup_app/features/auth/presentation/auth_controllers.dart';
import 'package:saveup_app/features/colaboraciones/data/dio_colaboraciones_repository.dart';
import 'package:saveup_app/features/colaboraciones/domain/colaboracion.dart';
import 'package:saveup_app/features/colaboraciones/domain/colaboraciones_repository.dart';
import 'package:saveup_app/features/colaboraciones/presentation/colaboraciones_screen.dart';

class _FakeColaboracionesRepository implements ColaboracionesRepository {
  _FakeColaboracionesRepository({this.snapshot});

  int llamadasCargar = 0;
  final SnapshotColaboraciones? snapshot;

  @override
  Future<SnapshotColaboraciones> cargar() async {
    llamadasCargar++;
    return snapshot ??
        const SnapshotColaboraciones(
          metas: <MetaCompartida>[],
          deudas: <DeudaDirecta>[],
          deudasGrupales: <DeudaGrupal>[],
          invitaciones: <InvitacionColaborativa>[],
          actividad: <ActividadColaborativa>[],
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Controlador de sesión manual: permite cambiar la cuenta sin red.
class _SesionManual extends AuthSessionController {
  @override
  AuthSession build() => const SessionUnauthenticated();

  void cambiar(AuthSession sesion) => state = sesion;
}

void main() {
  testWidgets('muestra estados vacíos por cada sección colaborativa', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          colaboracionesRepositoryProvider.overrideWithValue(
            _FakeColaboracionesRepository(),
          ),
        ],
        child: MaterialApp(
          theme: SaveUpTheme.light(),
          home: const ColaboracionesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes metas compartidas'), findsOneWidget);
    await tester.tap(find.text('Deudas'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes deudas colaborativas'), findsOneWidget);

    await tester.tap(find.text('Invitaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Sin invitaciones pendientes'), findsOneWidget);
    expect(find.text('Ingresar código'), findsOneWidget);

    await tester.tap(find.text('Actividad'));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no hay actividad'), findsOneWidget);
  });

  testWidgets('muestra la tarjeta de una deuda compartida activa', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          colaboracionesRepositoryProvider.overrideWithValue(
            _FakeColaboracionesRepository(
              snapshot: SnapshotColaboraciones(
                metas: const <MetaCompartida>[],
                deudas: const <DeudaDirecta>[],
                deudasGrupales: <DeudaGrupal>[
                  DeudaGrupal(
                    id: 7,
                    nombre: 'Notebook',
                    acreedorExterno: 'Falabella',
                    montoTotal: Decimal.parse('300000.00'),
                    saldoPendiente: Decimal.parse('210000.00'),
                    estado: EstadoDeudaGrupal.activa,
                    permisoEdicion: PermisoEdicionCompartida.todos,
                    nombreCreador: 'Ana Demo',
                    creadorActual: true,
                    participanteActual: true,
                    miResponsabilidadPendiente: Decimal.parse('160000.00'),
                    participantes: <ParticipanteDeudaGrupal>[
                      ParticipanteDeudaGrupal(
                        id: 3,
                        nombre: 'Ana Demo',
                        email: 'ana@example.com',
                        responsabilidadOriginal: Decimal.parse('200000.00'),
                        responsabilidadPendiente: Decimal.parse('160000.00'),
                        estado: EstadoParticipanteDeudaGrupal.activo,
                        actual: true,
                      ),
                      ParticipanteDeudaGrupal(
                        id: 4,
                        nombre: 'Bea Demo',
                        email: 'bea@example.com',
                        responsabilidadOriginal: Decimal.parse('100000.00'),
                        responsabilidadPendiente: Decimal.parse('50000.00'),
                        estado: EstadoParticipanteDeudaGrupal.activo,
                        actual: false,
                      ),
                    ],
                    cuotas: <CuotaGrupal>[
                      CuotaGrupal(
                        numero: 1,
                        monto: Decimal.parse('150000.00'),
                        fechaVencimiento: CalendarDate(2027, 6, 10),
                      ),
                    ],
                    invitacionesPendientes: <InvitacionColaborativa>[],
                  ),
                ],
                invitaciones: <InvitacionColaborativa>[],
                actividad: <ActividadColaborativa>[],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: SaveUpTheme.light(),
          home: const ColaboracionesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deudas'));
    await tester.pumpAndSettle();

    expect(find.text('Notebook'), findsOneWidget);
    expect(find.text('Acreedor externo: Falabella'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
    expect(find.text('Registrar pago'), findsOneWidget);
    expect(find.text('Proponer reparto'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
  });

  testWidgets('vuelve a pedir el snapshot cuando cambia la sesión', (
    WidgetTester tester,
  ) async {
    final _FakeColaboracionesRepository repository =
        _FakeColaboracionesRepository();
    final _SesionManual sesion = _SesionManual();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          colaboracionesRepositoryProvider.overrideWithValue(repository),
          authSessionProvider.overrideWith(() => sesion),
        ],
        child: MaterialApp(
          theme: SaveUpTheme.light(),
          home: const ColaboracionesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.llamadasCargar, 1);

    // Cambio de cuenta: la bandeja debe recargarse con el nuevo usuario.
    sesion.cambiar(
      SessionAuthenticated(
        UserProfile(
          rut: '12345678-5',
          nombre: 'Ana',
          apellido: 'Demo',
          email: 'ana.colab@example.test',
          fechaRegistro: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.llamadasCargar, 2);
  });
}
