import 'package:decimal/decimal.dart';

import '../../../core/time/business_month.dart';
import '../../movimientos/domain/categoria.dart';
import '../../presupuesto/domain/ejecucion_presupuesto.dart';
import '../../presupuesto/domain/plan_calculo.dart';
import '../../presupuesto/domain/plan_mensual.dart';

/// Máximo de porciones de categoría antes de agrupar en «Otros».
const int maxCategoriasTorta = 6;

const String codigoOtrosAgrupados = 'OTROS_AGRUPADOS';
const String codigoSinCategoria = 'SIN_CATEGORIA';

/// Porción de la torta de gastos.
class GastoCategoria {
  GastoCategoria({
    required this.codigo,
    required this.nombre,
    required this.monto,
    this.colorHex,
    Decimal? porcentaje,
    this.esAgrupado = false,
  }) : porcentaje = porcentaje ?? Decimal.zero;

  final String codigo;
  final String nombre;
  final Decimal monto;
  final String? colorHex;
  final Decimal porcentaje;

  /// `true` para «Otros» y «Sin categoría» (no son categorías reales).
  final bool esAgrupado;

  GastoCategoria copyWith({Decimal? porcentaje}) {
    return GastoCategoria(
      codigo: codigo,
      nombre: nombre,
      monto: monto,
      colorHex: colorHex,
      porcentaje: porcentaje ?? this.porcentaje,
      esAgrupado: esAgrupado,
    );
  }
}

/// Punto de la tendencia mensual.
///
/// `gastos` suma necesidades + deseos: el DTO de historial no expone «otros».
class PuntoMensual {
  const PuntoMensual({
    required this.mes,
    required this.ingresos,
    required this.gastos,
    required this.ahorro,
  });

  final BusinessMonth mes;
  final Decimal ingresos;
  final Decimal gastos;
  final Decimal ahorro;
}

/// Reparto del gasto por tipo efectivo (necesidad/deseo/otros/ahorro).
class GastoPorTipo {
  const GastoPorTipo({
    required this.tipo,
    required this.monto,
    required this.porcentaje,
  });

  final TipoPresupuesto tipo;
  final Decimal monto;
  final Decimal porcentaje;
}

/// Resumen listo para la pantalla de analítica.
class ResumenAnalitica {
  const ResumenAnalitica({
    required this.mes,
    required this.ingresos,
    required this.gastos,
    required this.ahorro,
    required this.disponible,
    required this.categorias,
    required this.porTipo,
    required this.tendencia,
    required this.sinCategoria,
  });

  final BusinessMonth mes;
  final Decimal ingresos;
  final Decimal gastos;
  final Decimal ahorro;
  final Decimal disponible;

  /// Torta: top 6 + «Otros» + «Sin categoría»; porcentajes suman 100.
  final List<GastoCategoria> categorias;
  final List<GastoPorTipo> porTipo;

  /// Últimos 6 meses, en orden ascendente.
  final List<PuntoMensual> tendencia;

  /// Gasto real sin categoría (`gastoRealTotal − Σ porCategoria.real`).
  final Decimal sinCategoria;

  bool get vacio =>
      ingresos == Decimal.zero &&
      gastos == Decimal.zero &&
      categorias.isEmpty;
}

/// Construye el resumen de analítica a partir del plan del mes, el historial y
/// el catálogo.
///
/// No inventa datos: el plan ya trae el gasto real por categoría aunque no
/// exista un plan guardado. El catálogo solo aporta nombre y color; si falla,
/// se usa el código como nombre.
ResumenAnalitica construirResumenAnalitica({
  required BusinessMonth mes,
  required PlanMensual plan,
  required List<HistorialPresupuesto> historial,
  required List<Categoria> catalogo,
}) {
  final ResumenCalculado resumen = plan.calculo.resumen;
  final Decimal gastos = resumen.gastoRealTotal;
  final Map<String, Categoria> porCodigo = <String, Categoria>{
    for (final Categoria categoria in catalogo) categoria.codigo: categoria,
  };

  final List<CategoriaResultado> conGasto = <CategoriaResultado>[
    for (final CategoriaResultado categoria in plan.calculo.porCategoria)
      if (categoria.real > Decimal.zero) categoria,
  ]..sort(
      (CategoriaResultado a, CategoriaResultado b) =>
          b.real.compareTo(a.real),
    );

  Decimal sumaCategorias = Decimal.zero;
  for (final CategoriaResultado categoria in conGasto) {
    sumaCategorias += categoria.real;
  }
  final Decimal diferencia = gastos - sumaCategorias;
  final Decimal sinCategoria = diferencia > Decimal.zero
      ? diferencia
      : Decimal.zero;

  final List<GastoCategoria> porciones = <GastoCategoria>[];
  final int top = conGasto.length > maxCategoriasTorta
      ? maxCategoriasTorta
      : conGasto.length;
  for (int i = 0; i < top; i++) {
    final CategoriaResultado resultado = conGasto[i];
    final Categoria? categoria = porCodigo[resultado.codigo];
    porciones.add(
      GastoCategoria(
        codigo: resultado.codigo,
        nombre: categoria?.nombre ?? resultado.codigo,
        colorHex: categoria?.colorHex,
        monto: resultado.real,
      ),
    );
  }
  if (conGasto.length > top) {
    Decimal otros = Decimal.zero;
    for (int i = top; i < conGasto.length; i++) {
      otros += conGasto[i].real;
    }
    porciones.add(
      GastoCategoria(
        codigo: codigoOtrosAgrupados,
        nombre: 'Otros',
        monto: otros,
        esAgrupado: true,
      ),
    );
  }
  if (sinCategoria > Decimal.zero) {
    porciones.add(
      GastoCategoria(
        codigo: codigoSinCategoria,
        nombre: 'Sin categoría',
        monto: sinCategoria,
        esAgrupado: true,
      ),
    );
  }

  return ResumenAnalitica(
    mes: mes,
    ingresos: resumen.ingresoReal,
    gastos: gastos,
    ahorro: resumen.ahorroRegistrado,
    disponible: resumen.disponibleReal,
    categorias: _conPorcentajes(porciones, gastos),
    porTipo: _porTipo(plan.calculo.repartoPorTipo),
    tendencia: _tendencia(historial),
    sinCategoria: sinCategoria,
  );
}

List<GastoCategoria> _conPorcentajes(
  List<GastoCategoria> porciones,
  Decimal total,
) {
  if (porciones.isEmpty) {
    return const <GastoCategoria>[];
  }
  if (total <= Decimal.zero) {
    return <GastoCategoria>[
      for (final GastoCategoria porcion in porciones)
        porcion.copyWith(porcentaje: Decimal.zero),
    ];
  }
  Decimal acumulado = Decimal.zero;
  final List<GastoCategoria> resultado = <GastoCategoria>[];
  for (int i = 0; i < porciones.length; i++) {
    final Decimal porcentaje = i == porciones.length - 1
        ? Decimal.fromInt(100) - acumulado
        : _porcentaje(porciones[i].monto, total);
    acumulado += porcentaje;
    resultado.add(porciones[i].copyWith(porcentaje: porcentaje));
  }
  return resultado;
}

List<GastoPorTipo> _porTipo(List<RepartoTipoResultado> tipos) {
  final List<RepartoTipoResultado> conGasto = <RepartoTipoResultado>[
    for (final RepartoTipoResultado tipo in tipos)
      if (tipo.real > Decimal.zero) tipo,
  ];
  if (conGasto.isEmpty) {
    return const <GastoPorTipo>[];
  }
  Decimal total = Decimal.zero;
  for (final RepartoTipoResultado tipo in conGasto) {
    total += tipo.real;
  }
  Decimal acumulado = Decimal.zero;
  final List<GastoPorTipo> resultado = <GastoPorTipo>[];
  for (int i = 0; i < conGasto.length; i++) {
    final Decimal porcentaje = i == conGasto.length - 1
        ? Decimal.fromInt(100) - acumulado
        : _porcentaje(conGasto[i].real, total);
    acumulado += porcentaje;
    resultado.add(
      GastoPorTipo(
        tipo: conGasto[i].tipo,
        monto: conGasto[i].real,
        porcentaje: porcentaje,
      ),
    );
  }
  return resultado;
}

List<PuntoMensual> _tendencia(List<HistorialPresupuesto> historial) {
  final List<PuntoMensual> puntos = <PuntoMensual>[
    for (final HistorialPresupuesto fila in historial)
      PuntoMensual(
        mes: BusinessMonth(fila.anio, fila.mes),
        ingresos: fila.ejecucion.totalIngresos,
        gastos:
            fila.ejecucion.gastoNecesidades + fila.ejecucion.gastoDeseos,
        ahorro: fila.ejecucion.ahorroRealizado,
      ),
  ]..sort((PuntoMensual a, PuntoMensual b) => a.mes.compareTo(b.mes));
  return puntos;
}

Decimal _porcentaje(Decimal monto, Decimal total) {
  return (monto * Decimal.fromInt(100) / total)
      .toDecimal(scaleOnInfinitePrecision: 6)
      .round(scale: 2);
}
