import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/features/deudas/data/dio_deudas_repository.dart';
import 'package:saveup_app/features/deudas/domain/deuda.dart';
import 'package:saveup_app/features/deudas/domain/deudas_repository.dart';
import 'package:saveup_app/features/deudas/presentation/deuda_form_screen.dart';

class _FakeDeudasRepository implements DeudasRepository {
  DeudaCreacion? creada;

  @override
  Future<Deuda> crear(DeudaCreacion deuda) async {
    creada = deuda;
    return _respuestaServidor;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final Deuda _respuestaServidor = Deuda(
  id: 1,
  nombre: 'Equipo',
  tipo: TipoDeuda.tienda,
  modalidad: ModalidadCalculo.sinInteres,
  estado: EstadoDeuda.pendiente,
  montoCapital: Decimal.parse('360000'),
  tasaMensual: Decimal.zero,
  tasaAnualEfectiva: Decimal.zero,
  valorCuota: Decimal.parse('15000'),
  gastosIniciales: Decimal.zero,
  costoAdicionalPorCuota: Decimal.zero,
  costoTotalCredito: Decimal.parse('360000'),
  cargaAnualEquivalente: Decimal.zero,
  fechaCreacion: DateTime.utc(2026, 11),
  cuotasPagadasPrevias: 0,
  montoPagadoPrevio: Decimal.zero,
  montoTotal: Decimal.parse('360000'),
  cantidadCuotas: 24,
  montoPagadoReal: Decimal.zero,
  montoPagado: Decimal.zero,
  montoRestante: Decimal.parse('360000'),
  totalPorPagar: Decimal.parse('360000'),
  saldoCapital: Decimal.parse('360000'),
  cuotasPagadas: 0,
  interesesPagados: Decimal.zero,
);

Widget _host(_FakeDeudasRepository repository, {Deuda? deuda}) {
  return ProviderScope(
    overrides: [deudasRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: SaveUpTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DeudaFormScreen(deuda: deuda),
              ),
            ),
            child: const Text('abrir formulario'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _abrirFormulario(
  WidgetTester tester,
  _FakeDeudasRepository repository,
) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(_host(repository));
  await tester.tap(find.text('abrir formulario'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('inicia en básico y no muestra el formulario avanzado', (
    WidgetTester tester,
  ) async {
    await _abrirFormulario(tester, _FakeDeudasRepository());

    expect(find.text('Básico'), findsOneWidget);
    expect(
      find.textContaining('Cuota fija sin interés adicional.'),
      findsOneWidget,
    );
    expect(find.text('Monto de cada cuota'), findsOneWidget);
    expect(find.text('Cantidad de cuotas'), findsOneWidget);
    expect(find.text('Modalidad'), findsNothing);
    expect(find.text('Capital'), findsNothing);
    expect(find.textContaining('Crear partida en el plan'), findsNothing);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('alternar conserva por separado los valores avanzados', (
    WidgetTester tester,
  ) async {
    await _abrirFormulario(tester, _FakeDeudasRepository());
    await tester.tap(find.text('Avanzado'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(2), '500.000');
    await tester.enterText(find.byType(TextFormField).at(3), '12');
    await tester.tap(find.text('Básico'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '15.000');
    await tester.enterText(find.byType(TextFormField).at(3), '24');

    await tester.tap(find.text('Avanzado'));
    await tester.pumpAndSettle();
    expect(_findValue('500.000'), findsOneWidget);
    expect(_findValue('12'), findsOneWidget);
    await tester.tap(find.text('Básico'));
    await tester.pumpAndSettle();
    expect(_findValue('15.000'), findsOneWidget);
    expect(_findValue('24'), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('edición conserva el formulario avanzado sin selector', (
    WidgetTester tester,
  ) async {
    final _FakeDeudasRepository repository = _FakeDeudasRepository();
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deudasRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: SaveUpTheme.light(),
          home: DeudaFormScreen(deuda: _respuestaServidor),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar deuda'), findsOneWidget);
    expect(find.text('Básico'), findsNothing);
    expect(find.text('Avanzado'), findsNothing);
    expect(find.text('Modalidad'), findsOneWidget);
    expect(find.text('Capital'), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('crea con cuota fija y muestra los valores devueltos', (
    WidgetTester tester,
  ) async {
    final _FakeDeudasRepository repository = _FakeDeudasRepository();
    await _abrirFormulario(tester, repository);

    await tester.enterText(find.byType(TextFormField).at(0), 'Equipo');
    await tester.enterText(find.byType(TextFormField).at(2), '15.000');
    await tester.enterText(find.byType(TextFormField).at(3), '24');
    await tester.ensureVisible(find.text('Crear deuda'));
    await tester.tap(find.text('Crear deuda'));
    await tester.pumpAndSettle();

    expect(repository.creada?.condiciones, isNull);
    expect(repository.creada?.cuotaFija?.valorCuota.toString(), '15000');
    expect(repository.creada?.cuotaFija?.cantidadCuotas, 24);
    expect(repository.creada?.cuotaFija?.fechaPrimeraCuota, isNull);
    expect(find.text('Monto de cada cuota: \$15.000'), findsOneWidget);
    expect(
      find.text('Total informado por el servidor: \$360.000'),
      findsOneWidget,
    );
    expect(find.text('Plazo: 24 cuotas'), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('alta muestra en el campo el error por exceder el límite', (
    WidgetTester tester,
  ) async {
    final _FakeDeudasRepository repository = _FakeDeudasRepository();
    await _abrirFormulario(tester, repository);

    await tester.enterText(find.byType(TextFormField).at(0), 'Equipo');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      '10000000000000',
    );
    await tester.enterText(find.byType(TextFormField).at(3), '24');
    await tester.ensureVisible(find.text('Crear deuda'));
    await tester.tap(find.text('Crear deuda'));
    await tester.pumpAndSettle();

    expect(
      find.text('El monto excede el máximo (13 enteros + 2 decimales).'),
      findsOneWidget,
    );
    expect(repository.creada, isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('alta muestra en el campo el error por escala mayor a dos', (
    WidgetTester tester,
  ) async {
    final _FakeDeudasRepository repository = _FakeDeudasRepository();
    await _abrirFormulario(tester, repository);

    await tester.enterText(find.byType(TextFormField).at(0), 'Equipo');
    final TextEditingController cuota = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller!;
    cuota.text = '15000,001';
    await tester.enterText(find.byType(TextFormField).at(3), '24');
    await tester.ensureVisible(find.text('Crear deuda'));
    await tester.tap(find.text('Crear deuda'));
    await tester.pumpAndSettle();

    expect(
      find.text('El monto no puede tener más de 2 decimales.'),
      findsOneWidget,
    );
    expect(repository.creada, isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('edición valida el límite del capital en su campo', (
    WidgetTester tester,
  ) async {
    final _FakeDeudasRepository repository = _FakeDeudasRepository();
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deudasRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: SaveUpTheme.light(),
          home: DeudaFormScreen(deuda: _respuestaServidor),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final TextEditingController capital = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller!;
    capital.text = '10000000000000';
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(
      find.text('El monto excede el máximo (13 enteros + 2 decimales).'),
      findsOneWidget,
    );

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Finder _findValue(String value) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is TextFormField && widget.controller?.text == value,
);
