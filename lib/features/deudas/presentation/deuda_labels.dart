import 'package:flutter/material.dart';

import '../domain/deuda.dart';

/// Etiquetas visibles de deudas (listado, detalle y formulario).
String tipoDeudaLabel(TipoDeuda tipo) => switch (tipo) {
  TipoDeuda.personal => 'Personal',
  TipoDeuda.tienda => 'Tienda',
  TipoDeuda.creditoConsumo => 'Crédito de consumo',
  TipoDeuda.educacion => 'Educación',
  TipoDeuda.otro => 'Otra',
};

String estadoDeudaLabel(EstadoDeuda estado) => switch (estado) {
  EstadoDeuda.pendiente => 'Pendiente',
  EstadoDeuda.pagada => 'Pagada',
  EstadoDeuda.cancelada => 'Cancelada',
};

Color estadoDeudaColor(BuildContext context, EstadoDeuda estado) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  return switch (estado) {
    EstadoDeuda.pendiente => scheme.primary,
    EstadoDeuda.pagada => scheme.tertiary,
    EstadoDeuda.cancelada => scheme.error,
  };
}

String modalidadLabel(ModalidadCalculo modalidad) => switch (modalidad) {
  ModalidadCalculo.sinInteres => 'Sin interés',
  ModalidadCalculo.tasaConocida => 'Con tasa',
  ModalidadCalculo.cuotaConocida => 'Con cuota conocida',
};

String estadoCuotaLabel(EstadoCuota? estado) => switch (estado) {
  EstadoCuota.pagada => 'Pagada',
  EstadoCuota.parcial => 'Parcial',
  EstadoCuota.pendiente => 'Pendiente',
  null => '—',
};
