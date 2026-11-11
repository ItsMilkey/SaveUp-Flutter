import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../movimientos/domain/categoria.dart';
import '../../domain/ejecucion_presupuesto.dart';
import '../../domain/plan_calculo.dart';
import '../../domain/preferencia_categoria.dart';
import '../controllers/limites_categorias_controller.dart';
import '../controllers/preferencias_categoria_controller.dart';
import '../plan_labels.dart';

/// Límites mensuales por categoría y tipos preferidos (F6).
class CategoriasPresupuestoScreen extends ConsumerStatefulWidget {
  const CategoriasPresupuestoScreen({super.key});

  @override
  ConsumerState<CategoriasPresupuestoScreen> createState() =>
      _CategoriasPresupuestoScreenState();
}

class _CategoriasPresupuestoScreenState
    extends ConsumerState<CategoriasPresupuestoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(limitesCategoriasProvider.notifier).cargar();
      ref.read(preferenciasCategoriaProvider.notifier).cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: NeoScaffold(
        appBar: NeoAppBar(
          title: 'Categorías',
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Límites'),
              Tab(text: 'Tipos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[_LimitesTab(), _TiposTab()],
        ),
      ),
    );
  }
}

class _LimitesTab extends ConsumerWidget {
  const _LimitesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LimitesCategoriasState estado = ref.watch(
      limitesCategoriasProvider,
    );
    final LimitesCategoriasController controller = ref.read(
      limitesCategoriasProvider.notifier,
    );
    final ThemeData theme = Theme.of(context);

    if (estado.cargando && estado.categorias.isEmpty) {
      return const NeoLoading(rows: 3);
    }
    if (estado.errorCarga != null) {
      return NeoErrorState(
        message: failureMessage(estado.errorCarga!),
        onRetry: controller.cargar,
      );
    }

    final Map<int, Categoria> porId = <int, Categoria>{
      for (final Categoria categoria in estado.categorias) categoria.id: categoria,
    };
    final List<MapEntry<int, Decimal>> filas =
        estado.valores.entries.toList()
          ..sort((MapEntry<int, Decimal> a, MapEntry<int, Decimal> b) {
            final String nombreA = porId[a.key]?.nombre ?? '${a.key}';
            final String nombreB = porId[b.key]?.nombre ?? '${b.key}';
            return nombreA.compareTo(nombreB);
          });

    return RefreshIndicator(
      onRefresh: controller.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Text(
            'Define un tope mensual por categoría. El guardado reemplaza el '
            'conjunto completo de límites.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (filas.isEmpty)
            NeoSurface(
              density: AppDensity.list,
              child: Text(
                'Aún no hay límites configurados.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            for (final MapEntry<int, MapEntry<int, Decimal>> indexado
                in filas.asMap().entries) ...<Widget>[
              NeoListItem(
                density: AppDensity.list,
                color: _coloresCategorias[
                    indexado.key % _coloresCategorias.length],
                title:
                    porId[indexado.value.key]?.nombre ??
                    'Categoría ${indexado.value.key}',
                subtitle: Money.formatClp(indexado.value.value),
                onTap: () => _editar(
                  context,
                  ref,
                  categoriaId: indexado.value.key,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    NeoIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Editar límite',
                      variant: NeoIconButtonVariant.ghost,
                      onPressed: () => _editar(
                        context,
                        ref,
                        categoriaId: indexado.value.key,
                      ),
                    ),
                    NeoIconButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Quitar límite',
                      variant: NeoIconButtonVariant.ghost,
                      onPressed: () => controller.quitar(indexado.value.key),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          const SizedBox(height: AppSpacing.sm),
          if (estado.categorias.isNotEmpty &&
              estado.valores.length < estado.categorias.length)
            Align(
              alignment: Alignment.centerLeft,
              child: NeoButton(
                icon: Icons.add,
                label: 'Agregar límite',
                variant: NeoButtonVariant.secondary,
                onPressed: () => _editar(context, ref),
              ),
            )
          else if (estado.categorias.isEmpty)
            Text(
              'No hay categorías disponibles.',
              style: theme.textTheme.bodySmall,
            )
          else
            Text(
              'Todas las categorías ya tienen un límite.',
              style: theme.textTheme.bodySmall,
            ),
          if (estado.mensajeValidacion != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: NeoErrorBand(message: estado.mensajeValidacion!),
            ),
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: NeoErrorBand(
                message: failureMessage(estado.error!),
              ),
            ),
          if (estado.guardado)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: NeoSurface(
                density: AppDensity.table,
                color: theme.extension<SaveUpColors>()!.success,
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Límites guardados.',
                      style: AppTypography.text(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (estado.guardando)
            const LinearProgressIndicator()
          else
            NeoButton(
              label: 'Guardar límites',
              expanded: true,
              onPressed: controller.guardar,
            ),
          const SizedBox(height: AppSpacing.lg),
          const _EjecucionCategorias(),
        ],
      ),
    );
  }

  Future<void> _editar(
    BuildContext context,
    WidgetRef ref, {
    int? categoriaId,
  }) async {
    final LimitesCategoriasState estado = ref.read(limitesCategoriasProvider);
    final List<Categoria> disponibles = categoriaId == null
        ? <Categoria>[
            for (final Categoria categoria in estado.categorias)
              if (!estado.valores.containsKey(categoria.id)) categoria,
          ]
        : estado.categorias;
    if (disponibles.isEmpty) {
      return;
    }
    final _LimiteValor? valor = await showDialog<_LimiteValor>(
      context: context,
      builder: (_) => _LimiteDialog(
        categorias: disponibles,
        categoriaInicial: categoriaId,
        limiteActual: categoriaId == null
            ? null
            : estado.valores[categoriaId],
      ),
    );
    if (valor == null) {
      return;
    }
    ref
        .read(limitesCategoriasProvider.notifier)
        .setLimite(valor.categoriaId, valor.limiteMensual);
  }
}

class _EjecucionCategorias extends ConsumerWidget {
  const _EjecucionCategorias();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<EjecucionCategoria>> ejecucion = ref.watch(
      ejecucionCategoriasProvider,
    );

    return NeoSurface(
      density: AppDensity.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Ejecución por categoría (mes actual)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          ejecucion.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
            error: (Object error, StackTrace stack) => Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'No se pudo cargar la ejecución por categoría.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(ejecucionCategoriasProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
            data: (List<EjecucionCategoria> lista) {
              if (lista.isEmpty) {
                return Text(
                  'Sin límites para ejecutar este mes.',
                  style: theme.textTheme.bodySmall,
                );
              }
              return Column(
                children: <Widget>[
                  for (final EjecucionCategoria fila in lista)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Text(fila.categoria)),
                          Text(
                            '${Money.formatClp(fila.gastado)} / '
                            '${Money.formatClp(fila.limite)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          NeoBadge(
                            label: estadoPlanLabel(fila.estado),
                            color: estadoPlanColor(context, fila.estado),
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LimiteValor {
  const _LimiteValor({required this.categoriaId, required this.limiteMensual});

  final int categoriaId;
  final Decimal limiteMensual;
}

class _LimiteDialog extends StatefulWidget {
  const _LimiteDialog({
    required this.categorias,
    this.categoriaInicial,
    this.limiteActual,
  });

  final List<Categoria> categorias;
  final int? categoriaInicial;
  final Decimal? limiteActual;

  @override
  State<_LimiteDialog> createState() => _LimiteDialogState();
}

class _LimiteDialogState extends State<_LimiteDialog> {
  late int? _categoriaId;
  late final TextEditingController _monto;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categoriaId = widget.categoriaInicial ?? widget.categorias.first.id;
    _monto = TextEditingController(
      text: widget.limiteActual == null
          ? ''
          : MoneyInputFormatter.format(widget.limiteActual!),
    );
  }

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  void _guardar() {
    final Decimal monto;
    try {
      monto = Money.parseUserInput(_monto.text);
    } on FormatException {
      setState(() => _error = 'Ingresa un monto válido.');
      return;
    }
    if (monto <= Decimal.zero) {
      setState(() => _error = 'El límite debe ser mayor a 0.');
      return;
    }
    final int? categoriaId = _categoriaId;
    if (categoriaId == null) {
      setState(() => _error = 'Selecciona una categoría.');
      return;
    }
    Navigator.of(context).pop(
      _LimiteValor(
        categoriaId: categoriaId,
        limiteMensual: monto.round(scale: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeoDialog(
      title: widget.categoriaInicial == null ? 'Agregar límite' : 'Editar límite',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        NeoButton(label: 'Guardar', onPressed: _guardar),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownButtonFormField<int>(
            initialValue: _categoriaId,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: <DropdownMenuItem<int>>[
              for (final Categoria categoria in widget.categorias)
                DropdownMenuItem<int>(
                  value: categoria.id,
                  child: Text(categoria.nombre),
                ),
            ],
            onChanged: widget.categoriaInicial == null
                ? (int? value) => setState(() => _categoriaId = value)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          NeoInput(
            controller: _monto,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            label: 'Límite mensual',
            error: _error,
            inputFormatters: moneyInputFormatters,
          ),
        ],
      ),
    );
  }
}

class _TiposTab extends ConsumerWidget {
  const _TiposTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PreferenciasCategoriaState estado = ref.watch(
      preferenciasCategoriaProvider,
    );
    final PreferenciasCategoriaController controller = ref.read(
      preferenciasCategoriaProvider.notifier,
    );
    final ThemeData theme = Theme.of(context);

    if (estado.cargando && estado.preferencias.isEmpty) {
      return const NeoLoading(rows: 3);
    }
    if (estado.errorCarga != null) {
      return NeoErrorState(
        message: failureMessage(estado.errorCarga!),
        onRetry: controller.cargar,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Text(
            'Reclasifica una categoría como necesidad o deseo. El resto usa '
            'su tipo por defecto.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: NeoErrorBand(
                      message: failureMessage(estado.error!),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: controller.limpiarError,
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          for (final MapEntry<int, PreferenciaCategoria> indexado
              in estado.preferencias.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _FilaPreferencia(
                preferencia: indexado.value,
                color: _coloresCategorias[
                    indexado.key % _coloresCategorias.length],
                guardando: estado.guardando.contains(indexado.value.id),
                onEstablecer: (TipoPresupuesto tipo) =>
                    controller.establecer(indexado.value.id, tipo),
                onQuitar: () => controller.quitar(indexado.value.id),
              ),
            ),
        ],
      ),
    );
  }
}

const List<Color> _coloresCategorias = <Color>[
  AppColors.cyan,
  AppColors.yellow,
  AppColors.lavender,
  AppColors.green,
  AppColors.magenta,
  AppColors.orange,
];

class _FilaPreferencia extends StatelessWidget {
  const _FilaPreferencia({
    required this.preferencia,
    required this.color,
    required this.guardando,
    required this.onEstablecer,
    required this.onQuitar,
  });

  final PreferenciaCategoria preferencia;
  final Color color;
  final bool guardando;
  final ValueChanged<TipoPresupuesto> onEstablecer;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    final String subtitulo =
        'Por defecto: ${tipoPresupuestoLabel(preferencia.tipoPorDefecto)} · '
        'Efectivo: ${tipoPresupuestoLabel(preferencia.tipoEfectivo)}';
    return NeoSurface(
      density: AppDensity.list,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  preferencia.nombre,
                  style: textTheme.titleSmall,
                ),
              ),
              if (guardando)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitulo, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          if (!preferencia.reclasificable)
            Text(
              'No reclasificable (${tipoPresupuestoLabel(preferencia.tipoPorDefecto)})',
              style: textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Necesidad'),
                  selected:
                      preferencia.tipoPreferido ==
                      TipoPresupuesto.necesidad,
                  onSelected: guardando
                      ? null
                      : (_) => onEstablecer(TipoPresupuesto.necesidad),
                ),
                ChoiceChip(
                  label: const Text('Deseo'),
                  selected:
                      preferencia.tipoPreferido == TipoPresupuesto.deseo,
                  onSelected: guardando
                      ? null
                      : (_) => onEstablecer(TipoPresupuesto.deseo),
                ),
                if (preferencia.tipoPreferido != null)
                  TextButton(
                    onPressed: guardando ? null : onQuitar,
                    child: const Text('Quitar preferencia'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
