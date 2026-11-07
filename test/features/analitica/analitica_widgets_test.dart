import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/core/time/business_month.dart';
import 'package:saveup_app/features/analitica/domain/analitica.dart';
import 'package:saveup_app/features/analitica/presentation/widgets/barras_mensuales_card.dart';
import 'package:saveup_app/features/analitica/presentation/widgets/reparto_por_tipo_card.dart';
import 'package:saveup_app/features/analitica/presentation/widgets/top_categorias_card.dart';
import 'package:saveup_app/features/analitica/presentation/widgets/torta_gastos_card.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';

import '../../support/load_app_fonts.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: SaveUpTheme.light(),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    ),
  );
}

GastoCategoria _categoria({
  required String codigo,
  required String nombre,
  required String monto,
  required String porcentaje,
  String? colorHex,
}) {
  return GastoCategoria(
    codigo: codigo,
    nombre: nombre,
    monto: Decimal.parse(monto),
    porcentaje: Decimal.parse(porcentaje),
    colorHex: colorHex,
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('torta muestra total, porciones y leyenda', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        TortaGastosCard(
          total: Decimal.parse('100000'),
          categorias: <GastoCategoria>[
            _categoria(
              codigo: 'ALIMENTACION_BASE',
              nombre: 'Alimentación Básica',
              monto: '60000',
              porcentaje: '60',
              colorHex: '#FF8A3D',
            ),
            _categoria(
              codigo: 'OCIO',
              nombre: 'Ocio',
              monto: '40000',
              porcentaje: '40',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Gastos por categoría'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Alimentación Básica'), findsOneWidget);
    expect(find.text('Ocio'), findsOneWidget);
    expect(find.text('60.0 %'), findsOneWidget);
    expect(find.text('40.0 %'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
  });

  testWidgets('barras muestran meses y leyenda', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        BarrasMensualesCard(
          puntos: <PuntoMensual>[
            PuntoMensual(
              mes: BusinessMonth(2026, 10),
              ingresos: Decimal.parse('900000'),
              gastos: Decimal.parse('500000'),
              ahorro: Decimal.parse('100000'),
            ),
            PuntoMensual(
              mes: BusinessMonth(2026, 11),
              ingresos: Decimal.parse('1000000'),
              gastos: Decimal.parse('650000'),
              ahorro: Decimal.parse('150000'),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Últimos 6 meses'), findsOneWidget);
    expect(find.text('Ingresos'), findsOneWidget);
    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Ahorro'), findsOneWidget);
    expect(find.text('oct'), findsOneWidget);
    expect(find.text('nov'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('reparto por tipo y top categorías listan montos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          children: <Widget>[
            RepartoPorTipoCard(
              tipos: <GastoPorTipo>[
                GastoPorTipo(
                  tipo: TipoPresupuesto.necesidad,
                  monto: Decimal.parse('400000'),
                  porcentaje: Decimal.parse('80'),
                ),
                GastoPorTipo(
                  tipo: TipoPresupuesto.deseo,
                  monto: Decimal.parse('100000'),
                  porcentaje: Decimal.parse('20'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TopCategoriasCard(
              categorias: <GastoCategoria>[
                _categoria(
                  codigo: 'ALIMENTACION_BASE',
                  nombre: 'Alimentación Básica',
                  monto: '400000',
                  porcentaje: '80',
                ),
              ],
            ),
          ],
        ),
      ),
    );

    expect(find.text('Reparto por tipo'), findsOneWidget);
    expect(find.text('Necesidades'), findsOneWidget);
    expect(find.text('Deseos'), findsOneWidget);
    expect(find.textContaining('80.0 %'), findsWidgets);
    expect(find.text('Top categorías'), findsOneWidget);
    expect(find.text('Alimentación Básica'), findsOneWidget);
  });
}
