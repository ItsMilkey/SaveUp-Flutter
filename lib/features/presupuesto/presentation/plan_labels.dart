import 'package:flutter/material.dart';

import '../domain/plan_calculo.dart';

/// Etiquetas y colores del plan (informativos, nunca errores).
String estadoPlanLabel(EstadoEjecucion estado) => switch (estado) {
  EstadoEjecucion.bajoElPlan => 'Bajo el plan',
  EstadoEjecucion.cercaDelPlan => 'Cerca del plan',
  EstadoEjecucion.sobreElPlan => 'Sobre el plan',
};

Color estadoPlanColor(BuildContext context, EstadoEjecucion estado) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  return switch (estado) {
    EstadoEjecucion.bajoElPlan => scheme.primary,
    EstadoEjecucion.cercaDelPlan => scheme.tertiary,
    EstadoEjecucion.sobreElPlan => scheme.error,
  };
}

String estadoCuotaPlanLabel(EstadoCuota? estado) => switch (estado) {
  EstadoCuota.pendiente => 'Cuota pendiente',
  EstadoCuota.parcial => 'Cuota parcial',
  EstadoCuota.pagada => 'Cuota pagada',
  null => '',
};
