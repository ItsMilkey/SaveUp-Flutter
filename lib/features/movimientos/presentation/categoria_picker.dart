import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/categoria.dart';
import '../domain/movimiento.dart';
import '../domain/movimiento_tipo.dart';
import 'categoria_visual.dart';

/// Categorías que el sugeridor del contrato considera válidas por contexto
/// (`contexto=INGRESO` solo devuelve SUELDO y OTROS; `GASTO` excluye SUELDO y
/// AHORRO). El selector del alta replica esa regla.
const Set<String> _codigosIngreso = <String>{'SUELDO', 'OTROS'};
const Set<String> _codigosExcluidosGasto = <String>{'SUELDO', 'AHORRO'};

List<Categoria> categoriasPermitidas(
  List<Categoria> todas,
  MovimientoTipo tipo,
) {
  if (tipo == MovimientoTipo.ingresoGeneral) {
    return <Categoria>[
      for (final Categoria categoria in todas)
        if (_codigosIngreso.contains(categoria.codigo)) categoria,
    ];
  }
  return <Categoria>[
    for (final Categoria categoria in todas)
      if (!_codigosExcluidosGasto.contains(categoria.codigo)) categoria,
  ];
}

/// Categorías que conviene ofrecer primero según los movimientos cargados.
class CategoriasSugeridas {
  const CategoriasSugeridas({
    required this.recientes,
    required this.frecuentes,
  });

  final List<Categoria> recientes;
  final List<Categoria> frecuentes;
}

CategoriasSugeridas categoriasPorUso({
  required List<Categoria> permitidas,
  required List<Movimiento> movimientos,
  required MovimientoTipo tipo,
}) {
  final Map<int, Categoria> porId = <int, Categoria>{
    for (final Categoria categoria in permitidas) categoria.id: categoria,
  };
  final List<Categoria> recientes = <Categoria>[];
  final Map<int, int> conteo = <int, int>{};
  int usados = 0;

  for (final Movimiento movimiento in movimientos) {
    if (movimiento.tipo != tipo || movimiento.categoria == null) {
      continue;
    }
    final Categoria? categoria = porId[movimiento.categoria!.id];
    if (categoria == null) {
      continue;
    }
    usados++;
    conteo[categoria.id] = (conteo[categoria.id] ?? 0) + 1;
    if (recientes.length < 4 &&
        !recientes.any((Categoria c) => c.id == categoria.id)) {
      recientes.add(categoria);
    }
  }

  final List<Categoria> frecuentes = <Categoria>[];
  if (usados >= 5) {
    final List<MapEntry<int, int>> ordenados = conteo.entries
        .where(
          (MapEntry<int, int> e) =>
              e.value >= 2 &&
              !recientes.any((Categoria c) => c.id == e.key),
        )
        .toList()
      ..sort(
        (MapEntry<int, int> a, MapEntry<int, int> b) =>
            b.value.compareTo(a.value),
      );
    for (final MapEntry<int, int> entrada in ordenados.take(4)) {
      frecuentes.add(porId[entrada.key]!);
    }
  }

  return CategoriasSugeridas(recientes: recientes, frecuentes: frecuentes);
}

class GrupoCategorias {
  const GrupoCategorias(this.titulo, this.categorias);

  final String titulo;
  final List<Categoria> categorias;
}

List<GrupoCategorias> agruparCategorias(List<Categoria> categorias) {
  final Map<String, List<Categoria>> grupos = <String, List<Categoria>>{};
  for (final Categoria categoria in categorias) {
    final String titulo = switch (categoria.tipoPresupuesto) {
      'NECESIDAD' => 'Necesidades',
      'DESEO' => 'Deseos',
      'AHORRO' => 'Ahorro',
      _ => 'Otros',
    };
    grupos.putIfAbsent(titulo, () => <Categoria>[]).add(categoria);
  }
  const List<String> orden = <String>[
    'Necesidades',
    'Deseos',
    'Ahorro',
    'Otros',
  ];
  return <GrupoCategorias>[
    for (final String titulo in orden)
      if (grupos[titulo] != null && grupos[titulo]!.isNotEmpty)
        GrupoCategorias(titulo, grupos[titulo]!),
  ];
}

/// Hoja inferior para elegir categoría con sugerencias por uso y catálogo
/// agrupado.
class CategoriaPicker extends StatelessWidget {
  const CategoriaPicker({
    super.key,
    required this.categorias,
    required this.tipo,
    required this.movimientos,
    this.seleccionada,
  });

  final List<Categoria> categorias;
  final MovimientoTipo tipo;
  final List<Movimiento> movimientos;
  final int? seleccionada;

  static Future<int?> show(
    BuildContext context, {
    required List<Categoria> categorias,
    required MovimientoTipo tipo,
    required List<Movimiento> movimientos,
    int? seleccionada,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CategoriaPicker(
        categorias: categorias,
        tipo: tipo,
        movimientos: movimientos,
        seleccionada: seleccionada,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool ingreso = tipo == MovimientoTipo.ingresoGeneral;
    final List<Categoria> permitidas = categoriasPermitidas(categorias, tipo);
    final CategoriasSugeridas sugeridas = categoriasPorUso(
      permitidas: permitidas,
      movimientos: movimientos,
      tipo: tipo,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Elegir categoría',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ingreso
                            ? 'Solo las categorías que aplican a un ingreso.'
                            : 'Sugerencias por uso y todas las categorías de '
                                  'gasto.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                NeoIconButton(
                  icon: Icons.close,
                  tooltip: 'Cerrar',
                  variant: NeoIconButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
                if (!ingreso && sugeridas.recientes.isNotEmpty) ...<Widget>[
                  const _PickerSeccion(
                    titulo: 'Recientes',
                    icono: Icons.history,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      for (final Categoria categoria in sugeridas.recientes)
                        _ChipCategoria(
                          categoria: categoria,
                          seleccionada: seleccionada,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (!ingreso && sugeridas.frecuentes.isNotEmpty) ...<Widget>[
                  const _PickerSeccion(
                    titulo: 'Más usadas',
                    icono: Icons.trending_up,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      for (final Categoria categoria in sugeridas.frecuentes)
                        _ChipCategoria(
                          categoria: categoria,
                          seleccionada: seleccionada,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _PickerSeccion(
                  titulo: ingreso
                      ? 'Categorías de ingreso'
                      : 'Todas las categorías',
                  icono: ingreso ? Icons.south_west : Icons.category_outlined,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (permitidas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'No hay categorías disponibles para este tipo.',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                else if (ingreso)
                  for (final Categoria categoria in permitidas)
                    _CategoriaFila(
                      categoria: categoria,
                      seleccionada: seleccionada == categoria.id,
                    )
                else
                  for (final GrupoCategorias grupo
                      in agruparCategorias(permitidas)) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.xs,
                      ),
                      child: Text(
                        grupo.titulo,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.extension<SaveUpColors>()!.muted,
                        ),
                      ),
                    ),
                    for (final Categoria categoria in grupo.categorias)
                      _CategoriaFila(
                        categoria: categoria,
                        seleccionada: seleccionada == categoria.id,
                      ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerSeccion extends StatelessWidget {
  const _PickerSeccion({required this.titulo, required this.icono});

  final String titulo;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icono, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Text(
          titulo.toUpperCase(),
          style: AppTypography.text(
            size: 11,
            weight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.ink.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  const _ChipCategoria({
    required this.categoria,
    required this.seleccionada,
  });

  final Categoria categoria;
  final int? seleccionada;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: IconoCategoria(categoria: categoria, size: 22),
      label: Text(categoria.nombre),
      selected: seleccionada == categoria.id,
      onSelected: (_) => Navigator.of(context).pop(categoria.id),
    );
  }
}

class _CategoriaFila extends StatelessWidget {
  const _CategoriaFila({
    required this.categoria,
    required this.seleccionada,
  });

  final Categoria categoria;
  final bool seleccionada;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: seleccionada ? AppColors.yellow : null,
        borderRadius: AppRadii.smAll,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(categoria.id),
          borderRadius: AppRadii.smAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                IconoCategoria(categoria: categoria, size: 30),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    categoria.nombre,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: seleccionada
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (seleccionada)
                  const Icon(Icons.check, size: 18, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
