import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../app/config.dart';
import '../../../app/routes.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/time_zones.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/presentation/auth_controllers.dart';
import '../domain/movimiento.dart';
import '../domain/movimiento_filtro.dart';
import '../domain/movimiento_tipo.dart';
import 'movimiento_labels.dart';
import 'movimientos_controller.dart';

/// Solo los movimientos generales son editables/eliminables (el backend
/// responde 409 para deudas, metas o abonos automáticos).
bool movimientoEditable(Movimiento movimiento) =>
    movimiento.tipo == MovimientoTipo.ingresoGeneral ||
    movimiento.tipo == MovimientoTipo.gastoGeneral;

/// Home real (primer slice de F3): saldo, filtros y movimientos paginados.
class MovimientosScreen extends ConsumerStatefulWidget {
  const MovimientosScreen({super.key});

  @override
  ConsumerState<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends ConsumerState<MovimientosScreen> {
  static final DateFormat _fechaVisible = DateFormat('dd-MM-yyyy');

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(movimientosProvider.notifier).inicializar();
      }
    });
    _scroll.addListener(_alAcercarseAlFinal);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_alAcercarseAlFinal)
      ..dispose();
    super.dispose();
  }

  void _alAcercarseAlFinal() {
    if (!_scroll.hasClients) {
      return;
    }
    final double restante =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (restante < 400) {
      ref.read(movimientosProvider.notifier).cargarMas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MovimientosState estado = ref.watch(movimientosProvider);

    return NeoScaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(movimientosProvider.notifier).refrescar(),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            const NeoSliverAppBar(
              title: AppConfig.appName,
              brand: true,
              centerTitle: true,
              floating: true,
              snap: true,
              toolbarHeight: 64,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl * 3,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  const _Saludo(),
                  const SizedBox(height: AppSpacing.md),
                  _TarjetaSaldo(estado: estado),
                  const SizedBox(height: AppSpacing.lg),
                  _Filtros(estado: estado),
                  const SizedBox(height: AppSpacing.sm),
                  ..._contenido(context, estado),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: NeoButton(
        label: 'Nuevo movimiento',
        icon: Icons.add,
        onPressed: () async {
          final bool? guardado = await context.push<bool>(
            AppRoutes.nuevoMovimiento,
          );
          if (guardado ?? false) {
            await ref.read(movimientosProvider.notifier).refrescar();
          }
        },
      ),
    );
  }

  List<Widget> _contenido(BuildContext context, MovimientosState estado) {
    if (estado.cargandoPagina) {
      return const <Widget>[
        NeoLoading(message: 'Cargando movimientos…', rows: 3),
      ];
    }
    if (estado.errorPagina != null) {
      return <Widget>[
        NeoErrorState(
          message: failureMessage(estado.errorPagina!),
          onRetry: () => ref.read(movimientosProvider.notifier).refrescar(),
        ),
      ];
    }
    if (estado.vacio) {
      return <Widget>[
        _SinMovimientos(
          filtrosActivos: estado.filtrosActivos,
          onQuitarFiltros: () =>
              ref.read(movimientosProvider.notifier).limpiarFiltros(),
        ),
      ];
    }
    return <Widget>[
      const NeoSectionHeader(title: 'Movimientos'),
      for (final Movimiento movimiento in estado.items)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _MovimientoFila(movimiento: movimiento),
        ),
      if (estado.cargandoMas)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator.adaptive()),
        )
      else if (!estado.hayMas && estado.items.isNotEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('No hay más movimientos.'),
          ),
        ),
    ];
  }

  /// Formato local (America/Santiago) de la fecha del movimiento.
  static String fechaLocal(DateTime instant) {
    final tz.TZDateTime local = tz.TZDateTime.from(
      instant,
      businessTimeZone,
    );
    return _fechaVisible.format(local);
  }
}

/// Saludo personalizado sobre la tarjeta de saldo.
class _Saludo extends ConsumerWidget {
  const _Saludo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthSession session = ref.watch(authSessionProvider);
    if (session is! SessionAuthenticated) {
      return const SizedBox.shrink();
    }
    final String nombre = session.user.nombre.trim();
    if (nombre.isEmpty) {
      return const SizedBox.shrink();
    }
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '¡Hola, ',
            style: AppTypography.display(size: 26, color: colors.ink),
          ),
          TextSpan(
            text: nombre,
            style: AppTypography.display(
              size: 26,
              color: AppColors.magenta,
            ),
          ),
          TextSpan(
            text: '!',
            style: AppTypography.display(size: 26, color: colors.ink),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Hero de saldo disponible: la pieza de mayor jerarquía del home.
class _TarjetaSaldo extends ConsumerWidget {
  const _TarjetaSaldo({required this.estado});

  final MovimientosState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final Decimal? saldo = estado.saldo;
    final bool negativo = saldo != null && saldo < Decimal.zero;

    final Widget content;
    if (estado.saldoError != null) {
      content = Row(
        children: <Widget>[
          Expanded(
            child: Text(
              failureMessage(estado.saldoError!),
              style: AppTypography.text(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          NeoButton(
            label: 'Reintentar',
            variant: NeoButtonVariant.ghost,
            onPressed: () => ref.read(movimientosProvider.notifier).refrescar(),
          ),
        ],
      );
    } else if (estado.cargandoSaldo || saldo == null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const LinearProgressIndicator(
            color: AppColors.ink,
            backgroundColor: AppColors.paper,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Consultando tu saldo…',
            style: AppTypography.text(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NeoMoneyText(
            amount: saldo,
            size: NeoMoneySize.display,
            tone: NeoMoneyTone.onAccent,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Según los movimientos registrados.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return NeoSurface(
      density: AppDensity.hero,
      color: AppColors.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppRadii.smAll,
                  border: Border.all(
                    color: colors.border,
                    width: AppBorders.regular,
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Saldo disponible',
                  style: AppTypography.text(
                    size: 17,
                    weight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (negativo && estado.saldoError == null)
                NeoBadge(
                  label: 'Saldo negativo',
                  color: AppColors.danger,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          content,
        ],
      ),
    );
  }
}

class _Filtros extends ConsumerWidget {
  const _Filtros({required this.estado});

  final MovimientosState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MovimientosController controller = ref.read(
      movimientosProvider.notifier,
    );
    final MovimientoFiltro filtro = estado.filtro;

    return NeoSurface(
      density: AppDensity.list,
      color: AppColors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.tune, size: 18, color: AppColors.ink),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Filtros',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                estado.inicializado
                    ? '${estado.totalItems} movimiento(s)'
                    : 'Cargando movimientos…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              OutlinedButton.icon(
                icon: const Icon(Icons.event, size: 18),
                label: Text(
                  filtro.desde == null ? 'Desde' : 'Desde ${filtro.desde}',
                ),
                onPressed: () =>
                    _elegirFecha(context, controller, esDesde: true),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_available, size: 18),
                label: Text(
                  filtro.hasta == null ? 'Hasta' : 'Hasta ${filtro.hasta}',
                ),
                onPressed: () =>
                    _elegirFecha(context, controller, esDesde: false),
              ),
              DropdownButton<MovimientoTipo>(
                value: filtro.tipo,
                hint: Text(
                  'Todos los tipos',
                  style: AppTypography.text(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                underline: const SizedBox.shrink(),
                dropdownColor: AppColors.paper,
                borderRadius: AppRadii.mdAll,
                iconEnabledColor: AppColors.ink,
                style: AppTypography.text(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                items: <DropdownMenuItem<MovimientoTipo>>[
                  for (final MovimientoTipo tipo in MovimientoTipo.todos)
                    DropdownMenuItem<MovimientoTipo>(
                      value: tipo,
                      child: Text(tipoMovimientoLabel(tipo)),
                    ),
                ],
                onChanged: controller.setTipo,
              ),
              if (estado.filtrosActivos)
                TextButton(
                  onPressed: controller.limpiarFiltros,
                  child: const Text('Limpiar'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _elegirFecha(
    BuildContext context,
    MovimientosController controller, {
    required bool esDesde,
  }) async {
    final DateTime inicial = DateTime.now();
    final DateTime? elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(inicial.year + 1, 12, 31),
      helpText: esDesde ? 'Fecha desde' : 'Fecha hasta',
    );
    if (elegida == null) {
      return;
    }
    final CalendarDate fecha = CalendarDate(
      elegida.year,
      elegida.month,
      elegida.day,
    );
    if (esDesde) {
      controller.setDesde(fecha);
    } else {
      controller.setHasta(fecha);
    }
  }
}

class _MovimientoFila extends ConsumerWidget {
  const _MovimientoFila({required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool editable = movimientoEditable(movimiento);
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final bool negativo = movimiento.monto < Decimal.zero;

    return Dismissible(
      key: ValueKey<String>('movimiento-${movimiento.id}'),
      direction: editable
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: AppRadii.mdAll,
        ),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onError,
        ),
      ),
      confirmDismiss: (_) => _confirmarEliminar(context, ref),
      child: _MovimientoTile(
        movimiento: movimiento,
        negativo: negativo,
        colors: colors,
        onTap: editable ? () => _abrirEdicion(context, ref) : null,
      ),
    );
  }

  Future<void> _abrirEdicion(BuildContext context, WidgetRef ref) async {
    final Object? resultado = await context.push<Object?>(
      AppRoutes.editarMovimiento,
      extra: movimiento,
    );
    if (resultado is Movimiento) {
      ref
          .read(movimientosProvider.notifier)
          .aplicarMovimientoActualizado(resultado);
    }
  }

  Future<bool> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool? confirmado = await NeoConfirmDialog.show(
      context,
      title: '¿Eliminar movimiento?',
      message:
          '"${movimiento.descripcion}" por '
          '${Money.formatClp(movimiento.monto)}. Esta acción no se puede '
          'deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (confirmado != true) {
      return false;
    }

    final AppFailure? failure = await ref
        .read(movimientosProvider.notifier)
        .eliminarMovimiento(movimiento);
    if (failure != null && context.mounted) {
      NeoSnackbar.show(
        context,
        failureMessage(failure),
        tone: NeoSnackbarTone.danger,
      );
      return false;
    }
    return true;
  }
}

class _SinMovimientos extends StatelessWidget {
  const _SinMovimientos({
    required this.filtrosActivos,
    required this.onQuitarFiltros,
  });

  final bool filtrosActivos;
  final VoidCallback onQuitarFiltros;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return NeoSurface(
      density: AppDensity.list,
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: AppRadii.smAll,
              border: Border.all(
                color: colors.border,
                width: AppBorders.thin,
              ),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 20,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Sin movimientos', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'No hay movimientos para estos filtros.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (filtrosActivos) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onQuitarFiltros,
              child: const Text('Quitar filtros'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MovimientoTile extends StatelessWidget {
  const _MovimientoTile({
    required this.movimiento,
    required this.negativo,
    required this.colors,
    this.onTap,
  });

  final Movimiento movimiento;
  final bool negativo;
  final SaveUpColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String categoria =
        movimiento.categoria?.nombre ?? tipoMovimientoLabel(movimiento.tipo);
    final Color tone = negativo ? colors.negativeText : colors.positiveText;

    return NeoListItem(
      density: AppDensity.list,
      onTap: onTap,
      accent: tone,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: AppRadii.smAll,
          border: Border.all(
            color: colors.border,
            width: AppBorders.thin,
          ),
        ),
        child: Icon(
          negativo ? Icons.south_east : Icons.north_east,
          size: 18,
          color: tone,
        ),
      ),
      title: movimiento.descripcion,
      subtitle:
          '${_MovimientosScreenState.fechaLocal(movimiento.fecha)} · $categoria',
      trailing: NeoMoneyText(
        amount: movimiento.monto,
        size: NeoMoneySize.title,
        tone: negativo ? NeoMoneyTone.expense : NeoMoneyTone.income,
      ),
    );
  }
}
