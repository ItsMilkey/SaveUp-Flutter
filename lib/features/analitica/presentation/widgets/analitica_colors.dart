import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/time/business_month.dart';
import '../../../presupuesto/domain/plan_calculo.dart';
import '../../domain/analitica.dart';

/// Color estable para una porción de la torta.
///
/// Usa el `colorHex` del catálogo; si falta o es inválido, cae en la paleta del
/// tema. Las porciones agrupadas usan colores neutros del sistema.
Color colorDeCategoria(
  BuildContext context,
  GastoCategoria categoria,
  int index,
) {
  final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
  if (categoria.codigo == codigoSinCategoria) {
    return colors.muted;
  }
  final Color? hex = _parseHex(categoria.colorHex);
  if (hex != null) {
    return hex;
  }
  return colors.chartPalette[index % colors.chartPalette.length];
}

Color? _parseHex(String? hex) {
  if (hex == null) {
    return null;
  }
  final String cleaned = hex.replaceFirst('#', '');
  if (cleaned.length != 6) {
    return null;
  }
  final int? value = int.tryParse(cleaned, radix: 16);
  if (value == null) {
    return null;
  }
  return Color(0xFF000000 | value);
}

/// Color del tipo efectivo del gasto.
Color colorDeTipo(BuildContext context, TipoPresupuesto tipo) {
  final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
  return switch (tipo) {
    TipoPresupuesto.necesidad => colors.info,
    TipoPresupuesto.deseo => AppColors.magenta,
    TipoPresupuesto.ahorro => colors.success,
    TipoPresupuesto.otros => colors.categoryFallback,
  };
}

String labelDeTipo(TipoPresupuesto tipo) => switch (tipo) {
  TipoPresupuesto.necesidad => 'Necesidades',
  TipoPresupuesto.deseo => 'Deseos',
  TipoPresupuesto.ahorro => 'Ahorro',
  TipoPresupuesto.otros => 'Otros',
};

/// Porcentaje legible con 1 decimal (el dato sigue siendo `Decimal`).
String formatearPorcentaje(Decimal valor) =>
    '${valor.round(scale: 1).toStringAsFixed(1)} %';

const List<String> _mesesCortos = <String>[
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String mesCorto(BusinessMonth mes) {
  if (mes.month < 1 || mes.month > 12) {
    return '${mes.month}';
  }
  return _mesesCortos[mes.month - 1];
}
