import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/features/auth/domain/auth_session.dart';
import 'package:saveup_app/features/auth/domain/user_profile.dart';
import 'package:saveup_app/features/auth/presentation/auth_controllers.dart';
import 'package:saveup_app/features/colaboraciones/data/dio_colaboraciones_repository.dart';
import 'package:saveup_app/features/colaboraciones/domain/colaboracion.dart';
import 'package:saveup_app/features/colaboraciones/domain/colaboraciones_repository.dart';
import 'package:saveup_app/features/colaboraciones/presentation/colaboraciones_screen.dart';

class _FakeColaboracionesRepository implements ColaboracionesRepository {
  int llamadasCargar = 0;

  @override
  Future<SnapshotColaboraciones> cargar() async {
    llamadasCargar++;
    return const SnapshotColaboraciones(
      metas: <MetaCompartida>[],
      deudas: <DeudaDirecta>[],
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
    expect(find.text('Aún no tienes deudas directas'), findsOneWidget);

    await tester.tap(find.text('Invitaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Sin invitaciones pendientes'), findsOneWidget);
    expect(find.text('Ingresar código'), findsOneWidget);

    await tester.tap(find.text('Actividad'));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no hay actividad'), findsOneWidget);
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
