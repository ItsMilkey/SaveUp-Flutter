import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/money/money.dart';
import '../../../../core/time/business_month.dart';
import '../../domain/plan_calculo.dart';
import '../../domain/plan_mensual.dart';
import '../controllers/plan_mensual_controller.dart';
import '../widgets/grupos_plan_dialog.dart';
import '../widgets/ingreso_referencia_dialog.dart';
import '../widgets/partida_form_dialog.dart';
import '../widgets/partida_monto_slider.dart';

/// Pantalla del plan mensual (F6a): resumen, grupos, sliders, referencias y
/// copia entre meses.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  BusinessMonth _mes = BusinessMonth.fromInstant(DateTime.now());
  final Set<String> _gruposColapsados = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(planMensualProvider.notifier).cargar(_mes.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final PlanMensualState estado = ref.watch(planMensualProvider);

    return NeoScaffold(
      floatingActionButton: estado.plan?.existe ?? false
          ? _BotonMenuPlan(onPressed: _abrirMenu)
          : null,
      appBar: NeoAppBar(
        title: 'Plan',
        actions: <Widget>[
          NeoIconButton(
            icon: estado.incluirReferencias
                ? Icons.history
                : Icons.history_toggle_off,
            tooltip: 'Referencias históricas',
            variant: NeoIconButtonVariant.ghost,
            onPressed: _alternarReferencias,
          ),
          NeoIconButton(
            icon: Icons.folder_outlined,
            tooltip: 'Grupos',
            variant: NeoIconButtonVariant.ghost,
            onPressed: _abrirGrupos,
          ),
          NeoIconButton(
            icon: Icons.copy_all_outlined,
            tooltip: 'Copiar desde otro mes',
            variant: NeoIconButtonVariant.ghost,
            onPressed: estado.copiando ? null : _copiarMes,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              NeoIconButton(
                icon: Icons.chevron_left,
                tooltip: 'Mes anterior',
                variant: NeoIconButtonVariant.ghost,
                onPressed: () => _cambiarMes(-1),
              ),
              Text('$_mes', style: Theme.of(context).textTheme.titleMedium),
              NeoIconButton(
                icon: Icons.chevron_right,
                tooltip: 'Mes siguiente',
                variant: NeoIconButtonVariant.ghost,
                onPressed: () => _cambiarMes(1),
              ),
            ],
          ),
        ),
      ),
      body: _cuerpo(estado),
    );
  }

  Widget _cuerpo(PlanMensualState estado) {
    if (estado.cargando && estado.plan == null) {
      return const NeoLoading(rows: 3);
    }
    if (estado.errorCarga != null && estado.plan == null) {
      return NeoErrorState(
        message: failureMessage(estado.errorCarga!),
        onRetry: () => ref
            .read(planMensualProvider.notifier)
            .cargar(_mes.toString()),
      );
    }
    final PlanMensual? plan = estado.plan;
    if (plan == null) {
      return const NeoEmptyState(
        title: 'Sin datos',
        message: 'Sin datos del plan.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(planMensualProvider.notifier)
          .cargar(_mes.toString()),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl * 2,
        ),
        children: <Widget>[
          if (!plan.existe)
            NeoSurface(
              density: AppDensity.section,
              child: Column(
                children: <Widget>[
                  const Text('Aún no hay un plan para este mes.'),
                  const SizedBox(height: AppSpacing.sm),
                  NeoButton(
                    icon: Icons.copy_all_outlined,
                    label: 'Copiar desde otro mes',
                    variant: NeoButtonVariant.secondary,
                    onPressed: estado.copiando ? null : _copiarMes,
                  ),
                ],
              ),
            ),
          if (plan.avisos.isNotEmpty) _Avisos(avisos: plan.avisos),
          _Resumen(plan: plan, onEditarIngreso: _editarIngreso),
          if (estado.errorLote != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: NeoErrorBand(
                      message: failureMessage(estado.errorLote!),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () =>
                        ref.read(planMensualProvider.notifier).reintentar(),
                    child: const Text('Reenviar cambios'),
                  ),
                ],
              ),
            ),
          if (estado.enviandoLote)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
          if (estado.incluirReferencias) _Referencias(plan: plan),
          const SizedBox(height: AppSpacing.xl),
          ..._secciones(plan),
        ],
      ),
    );
  }

  /// Secciones de grupos con una línea separadora entre ellas.
  List<Widget> _secciones(PlanMensual plan) {
    final List<Widget> secciones = <Widget>[];
    if (plan.grupos.isEmpty && plan.partidas.isNotEmpty) {
      secciones.add(
        _SeccionGrupo(
          titulo: 'Sin grupo',
          color: AppColors.lavender,
          planificado: plan.calculo.resumen.planificadoTotal,
          real: plan.partidas.fold(
            Decimal.zero,
            (Decimal a, PartidaPlan p) => a + p.real,
          ),
          partidaIds: <int>[for (final PartidaPlan p in plan.partidas) p.id],
          expandido: !_gruposColapsados.contains('sin-grupo'),
          onToggle: () => _alternarGrupo('sin-grupo'),
          onEditar: _editarPartida,
          onEliminar: _eliminarPartida,
        ),
      );
      return secciones;
    }
    for (int i = 0; i < plan.grupos.length; i++) {
      if (i > 0) {
        secciones.add(const _SeparadorGrupos());
      }
      secciones.add(
        _SeccionGrupo(
          titulo: plan.grupos[i].nombre,
          color: _coloresGrupo[i % _coloresGrupo.length],
          planificado: plan.grupos[i].planificado,
          real: plan.grupos[i].real,
          partidaIds: plan.grupos[i].partidaIds,
          expandido: !_gruposColapsados.contains(_claveGrupo(plan.grupos[i])),
          onToggle: () => _alternarGrupo(_claveGrupo(plan.grupos[i])),
          onEditar: _editarPartida,
          onEliminar: _eliminarPartida,
        ),
      );
    }
    return secciones;
  }

  static String _claveGrupo(GrupoResultado grupo) =>
      grupo.id?.toString() ?? 'sin-grupo';

  void _alternarGrupo(String clave) {
    setState(() {
      if (!_gruposColapsados.remove(clave)) {
        _gruposColapsados.add(clave);
      }
    });
  }

  /// Menú que aparece justo encima del botón `+` con las acciones del plan.
  Future<void> _abrirMenu(Rect anchor) async {
    const double anchoMenu = 220;
    final Size pantalla = MediaQuery.sizeOf(context);
    final double izquierda = (anchor.right - anchoMenu)
        .clamp(8.0, pantalla.width - anchoMenu - 8)
        .toDouble();
    final double abajo = pantalla.height - anchor.top + 8;

    final _PlanAccion? accion = await showGeneralDialog<_PlanAccion>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menú del plan',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: AppMotion.fast,
      pageBuilder: (BuildContext dialogContext, _, _) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: izquierda,
                bottom: abajo,
                width: anchoMenu,
                child: _MenuPlan(
                  onGrupo: () =>
                      Navigator.of(dialogContext).pop(_PlanAccion.grupo),
                  onPartida: () =>
                      Navigator.of(dialogContext).pop(_PlanAccion.partida),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            _,
            Widget child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                alignment: Alignment.bottomRight,
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: AppMotion.curve),
                ),
                child: child,
              ),
            );
          },
    );
    if (!mounted || accion == null) {
      return;
    }
    switch (accion) {
      case _PlanAccion.grupo:
        await _abrirGrupos();
      case _PlanAccion.partida:
        await _nuevaPartida();
    }
  }

  void _cambiarMes(int delta) {
    final DateTime siguiente = DateTime(_mes.year, _mes.month + delta);
    setState(() => _mes = BusinessMonth(siguiente.year, siguiente.month));
    ref.read(planMensualProvider.notifier).cargar(_mes.toString());
  }

  void _alternarReferencias() {
    final PlanMensualState estado = ref.read(planMensualProvider);
    ref
        .read(planMensualProvider.notifier)
        .cargar(_mes.toString(), incluirReferencias: !estado.incluirReferencias);
  }

  Future<void> _abrirGrupos() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const GruposPlanDialog(),
    );
    if (mounted) {
      await ref.read(planMensualProvider.notifier).cargar(_mes.toString());
    }
  }

  Future<void> _copiarMes() async {
    final BusinessMonth? origen = await showDialog<BusinessMonth>(
      context: context,
      builder: (_) => _SelectorMesOrigen(mesDestino: _mes),
    );
    if (origen == null || !mounted) {
      return;
    }
    final AppFailure? failure = await ref
        .read(planMensualProvider.notifier)
        .copiarDesde(origen.toString());
    if (!mounted) {
      return;
    }
    if (failure != null) {
      NeoSnackbar.show(
        context,
        failureMessage(failure),
        tone: NeoSnackbarTone.danger,
      );
      return;
    }
    final PlanMensualState estado = ref.read(planMensualProvider);
    final List<AvisoPlan> avisos = estado.plan?.avisos ?? const <AvisoPlan>[];
    NeoSnackbar.show(
      context,
      avisos.isEmpty
          ? 'Plan copiado desde $origen.'
          : 'Plan copiado con ${avisos.length} aviso(s).',
      tone: NeoSnackbarTone.success,
    );
  }

  Future<void> _editarIngreso() async {
    final PlanMensual? plan = ref.read(planMensualProvider).plan;
    if (plan == null) {
      return;
    }
    final IngresoReferenciaValor? valor = await IngresoReferenciaDialog.show(
      context,
      actual: plan.ingresoReferencia,
    );
    if (valor == null || !mounted) {
      return;
    }
    final AppFailure? failure = await ref
        .read(planMensualProvider.notifier)
        .actualizarIngreso(valor.monto);
    if (failure != null && mounted) {
      NeoSnackbar.show(
        context,
        failureMessage(failure),
        tone: NeoSnackbarTone.danger,
      );
    }
  }

  Future<void> _nuevaPartida() async {
    final bool? creada = await PartidaFormDialog.show(
      context,
      mes: _mes.toString(),
    );
    if ((creada ?? false) && mounted) {
      await ref.read(planMensualProvider.notifier).cargar(_mes.toString());
    }
  }

  Future<void> _editarPartida(int id) async {
    final PartidaPlan? partida = ref.read(planMensualProvider).plan?.partida(id);
    if (partida == null) {
      return;
    }
    final bool? editada = await PartidaFormDialog.show(
      context,
      mes: _mes.toString(),
      partida: partida,
    );
    if ((editada ?? false) && mounted) {
      await ref.read(planMensualProvider.notifier).cargar(_mes.toString());
    }
  }

  Future<void> _eliminarPartida(int id) async {
    final PartidaPlan? partida = ref.read(planMensualProvider).plan?.partida(id);
    if (partida == null) {
      return;
    }
    final bool? confirmado = await NeoConfirmDialog.show(
      context,
      title: '¿Eliminar partida?',
      message:
          '«${partida.nombre}» se quitará del plan y su monto volverá al '
          'remanente libre.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (confirmado != true || !mounted) {
      return;
    }
    final AppFailure? failure = await ref
        .read(planMensualProvider.notifier)
        .eliminarPartida(id);
    if (failure != null && mounted) {
      NeoSnackbar.show(
        context,
        failureMessage(failure),
        tone: NeoSnackbarTone.danger,
      );
    }
  }
}

const List<Color> _coloresGrupo = <Color>[
  AppColors.cyan,
  AppColors.magenta,
  AppColors.green,
  AppColors.lavender,
  AppColors.orange,
  AppColors.yellow,
];

enum _PlanAccion { grupo, partida }

/// Botón `+` que abre el menú de acciones del plan.
class _BotonMenuPlan extends StatelessWidget {
  const _BotonMenuPlan({required this.onPressed});

  final ValueChanged<Rect> onPressed;

  @override
  Widget build(BuildContext context) {
    final SaveUpShadows shadows = Theme.of(context).extension<SaveUpShadows>()!;
    return Tooltip(
      message: 'Agregar al plan',
      child: Builder(
        builder: (BuildContext buttonContext) {
          return NeoSurface(
            color: AppColors.yellow,
            radius: AppRadii.pillAll,
            borderWidth: AppBorders.regular,
            boxShadow: shadows.md,
            padding: EdgeInsets.zero,
            onTap: () {
              final RenderBox box =
                  buttonContext.findRenderObject()! as RenderBox;
              onPressed(box.localToGlobal(Offset.zero) & box.size);
            },
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.add, size: 30, color: AppColors.ink),
            ),
          );
        },
      ),
    );
  }
}

/// Menú flotante con las acciones del plan, en estilo tarjeta.
class _MenuPlan extends StatelessWidget {
  const _MenuPlan({required this.onGrupo, required this.onPartida});

  final VoidCallback onGrupo;
  final VoidCallback onPartida;

  @override
  Widget build(BuildContext context) {
    final SaveUpShadows shadows = Theme.of(context).extension<SaveUpShadows>()!;
    return NeoSurface(
      density: AppDensity.section,
      boxShadow: shadows.lg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _MenuOpcion(
            label: 'Crear grupo',
            icon: Icons.folder_outlined,
            color: AppColors.cyan,
            onTap: onGrupo,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MenuOpcion(
            label: 'Crear partida',
            icon: Icons.playlist_add,
            onTap: onPartida,
          ),
        ],
      ),
    );
  }
}

/// Opción del menú con forma de tarjeta y color de acento.
class _MenuOpcion extends StatelessWidget {
  const _MenuOpcion({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppColors.yellow,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadii.pillAll,
            border: Border.all(
              color: colors.border,
              width: AppBorders.regular,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: AppColors.ink),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.text(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Línea que separa un grupo del siguiente.
class _SeparadorGrupos extends StatelessWidget {
  const _SeparadorGrupos();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: AppSpacing.xxl,
      thickness: AppBorders.thin,
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.plan, required this.onEditarIngreso});

  final PlanMensual plan;
  final VoidCallback onEditarIngreso;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final TextTheme textTheme = theme.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    final ResumenCalculado resumen = plan.calculo.resumen;
    final Decimal? ingreso = plan.ingresoReferencia;
    final Decimal? remanente = resumen.remanenteLibre;
    final Decimal? margen = resumen.margenSeguridadPct;
    final GuiaCalculo? guia = plan.calculo.guia;
    final bool excede = resumen.excedeIngreso && ingreso != null;
    final TextStyle etiqueta = AppTypography.text(
      size: 11,
      weight: FontWeight.w700,
      letterSpacing: 0.5,
      color: AppColors.ink.withValues(alpha: 0.7),
    );

    return NeoSurface(
      density: AppDensity.section,
      color: AppColors.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: NeoSectionHeader(title: 'Resumen')),
              if (resumen.excedeIngreso)
                NeoBadge(
                  label: 'Excede el ingreso',
                  color: theme.colorScheme.error,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('INGRESO DE REFERENCIA', style: etiqueta),
                    const SizedBox(height: 2),
                    Text(
                      ingreso == null ? 'Sin definir' : Money.formatClp(ingreso),
                      style: ingreso == null
                          ? textTheme.titleMedium?.copyWith(color: colors.muted)
                          : AppTypography.display(
                              size: 28,
                              color: AppColors.ink,
                            ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'El monto que planeas recibir este mes.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              NeoIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Editar ingreso de referencia',
                variant: NeoIconButtonVariant.ghost,
                onPressed: onEditarIngreso,
              ),
            ],
          ),
          if (excede) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'El plan supera tu ingreso por '
              '${Money.formatClp(resumen.planificadoTotal - ingreso)}.',
              style: textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _Metrica(
                  label: 'Planificado',
                  value: Money.formatClp(resumen.planificadoTotal),
                  helper: 'Suma de partidas',
                ),
              ),
              const _SeparadorMetrica(),
              Expanded(
                child: _Metrica(
                  label: 'Remanente',
                  value: remanente == null ? '—' : Money.formatClp(remanente),
                  helper: 'Ingreso − planificado',
                  valueColor: remanente != null && remanente < Decimal.zero
                      ? colors.negativeText
                      : null,
                ),
              ),
              const _SeparadorMetrica(),
              Expanded(
                child: _Metrica(
                  label: 'Margen',
                  value: margen == null ? '—' : '$margen %',
                  helper: 'Remanente ÷ ingreso',
                  valueColor: margen != null && margen < Decimal.zero
                      ? colors.negativeText
                      : null,
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Reparto por tipo',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'vs guía',
                style: textTheme.bodySmall?.copyWith(color: colors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final RepartoTipoResultado fila in plan.calculo.repartoPorTipo)
            _TipoFila(fila: fila, colors: colors, textTheme: textTheme),
          const Divider(),
          Text('GUÍA DEL PRESUPUESTO', style: etiqueta),
          const SizedBox(height: AppSpacing.xs),
          if (guia == null)
            Text(
              'Todavía no tienes una guía configurada.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.68),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                NeoBadge(
                  label: 'Necesidades ${guia.necesidades} %',
                  color: AppColors.paper,
                  compact: true,
                ),
                NeoBadge(
                  label: 'Deseos ${guia.deseos} %',
                  color: AppColors.paper,
                  compact: true,
                ),
                NeoBadge(
                  label: 'Ahorro ${guia.ahorro} %',
                  color: AppColors.paper,
                  compact: true,
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          NeoButton(
            label: 'Ir a Presupuesto',
            icon: Icons.tune,
            variant: NeoButtonVariant.secondary,
            expanded: true,
            onPressed: () => context.go(AppRoutes.presupuestoConfiguracion),
          ),
        ],
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.label,
    required this.value,
    required this.helper,
    this.valueColor,
  });

  final String label;
  final String value;
  final String helper;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.text(
            size: 11,
            weight: FontWeight.w600,
            color: AppColors.ink.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: AppTypography.text(
            size: 16,
            weight: FontWeight.w700,
            color: valueColor ?? AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          helper,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: AppColors.ink.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _SeparadorMetrica extends StatelessWidget {
  const _SeparadorMetrica();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: AppColors.ink.withValues(alpha: 0.15),
    );
  }
}

class _TipoFila extends StatelessWidget {
  const _TipoFila({
    required this.fila,
    required this.colors,
    required this.textTheme,
  });

  final RepartoTipoResultado fila;
  final SaveUpColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (fila.tipo) {
      TipoPresupuesto.necesidad => AppColors.cyan,
      TipoPresupuesto.deseo => AppColors.magenta,
      TipoPresupuesto.otros => AppColors.lavender,
      TipoPresupuesto.ahorro => AppColors.green,
    };
    final String label = switch (fila.tipo) {
      TipoPresupuesto.necesidad => 'Necesidades',
      TipoPresupuesto.deseo => 'Deseos',
      TipoPresupuesto.otros => 'Otros',
      TipoPresupuesto.ahorro => 'Ahorro',
    };
    final String porcentaje = fila.porcentajeDelIngreso == null
        ? '—'
        : '${fila.porcentajeDelIngreso} % del ingreso';
    final String diferencia = fila.diferenciaPuntos == null
        ? '—'
        : '${fila.diferenciaPuntos! >= Decimal.zero ? '+' : ''}'
              '${fila.diferenciaPuntos} pts';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4, right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppColors.ink, width: 1),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  porcentaje,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(Money.formatClp(fila.planificado), style: textTheme.titleSmall),
              Text(
                diferencia,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fila.diferenciaPuntos == null
                      ? colors.muted
                      : (fila.diferenciaPuntos! > Decimal.zero
                            ? AppColors.danger
                            : AppColors.ink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeccionGrupo extends StatelessWidget {
  const _SeccionGrupo({
    required this.titulo,
    required this.color,
    required this.planificado,
    required this.real,
    required this.partidaIds,
    required this.expandido,
    required this.onToggle,
    required this.onEditar,
    required this.onEliminar,
  });

  final String titulo;
  final Color color;
  final Decimal planificado;
  final Decimal real;
  final List<int> partidaIds;
  final bool expandido;
  final VoidCallback onToggle;
  final ValueChanged<int> onEditar;
  final ValueChanged<int> onEliminar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadii.smAll,
                border: Border.all(
                  color: Theme.of(context).extension<SaveUpColors>()!.border,
                  width: AppBorders.thin,
                ),
              ),
            ),
            Expanded(
              child: NeoSectionHeader(
                title: titulo,
                subtitle:
                    '${Money.formatClp(planificado)} · real '
                    '${Money.formatClp(real)}',
              ),
            ),
            if (partidaIds.isNotEmpty)
              NeoIconButton(
                icon: expandido ? Icons.expand_less : Icons.expand_more,
                tooltip: expandido ? 'Contraer grupo' : 'Expandir grupo',
                variant: NeoIconButtonVariant.ghost,
                onPressed: onToggle,
              ),
          ],
        ),
        if (partidaIds.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text('Sin partidas en este mes.'),
          )
        else if (expandido)
          for (final int id in partidaIds)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: PartidaMontoSlider(
                partidaId: id,
                color: color,
                onEditar: () => onEditar(id),
                onEliminar: () => onEliminar(id),
              ),
            ),
      ],
    );
  }
}

class _Referencias extends StatelessWidget {
  const _Referencias({required this.plan});

  final PlanMensual plan;

  @override
  Widget build(BuildContext context) {
    final List<CategoriaResultado> conReferencia = <CategoriaResultado>[
      for (final CategoriaResultado c in plan.calculo.porCategoria)
        if (c.referencia != null) c,
    ];
    if (conReferencia.isEmpty) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    return NeoSurface(
      density: AppDensity.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NeoSectionHeader(title: 'Referencias históricas'),
          for (final CategoriaResultado c in conReferencia)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(c.codigo)),
                  Text(
                    'Mes anterior ${c.referencia!.mesAnterior == null ? '—' : Money.formatClp(c.referencia!.mesAnterior!)}'
                    ' · Promedio 3M ${c.referencia!.promedio3Meses == null ? '—' : Money.formatClp(c.referencia!.promedio3Meses!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Avisos extends StatelessWidget {
  const _Avisos({required this.avisos});

  final List<AvisoPlan> avisos;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return NeoSurface(
      density: AppDensity.section,
      color: theme.colorScheme.tertiaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Avisos de la copia',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final AvisoPlan aviso in avisos)
            Text(
              '• ${aviso.mensaje ?? aviso.motivo}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _SelectorMesOrigen extends StatelessWidget {
  const _SelectorMesOrigen({required this.mesDestino});

  final BusinessMonth mesDestino;

  @override
  Widget build(BuildContext context) {
    final List<BusinessMonth> opciones = <BusinessMonth>[
      for (int i = 1; i <= 12; i++)
        BusinessMonth(
          DateTime(mesDestino.year, mesDestino.month - i).year,
          DateTime(mesDestino.year, mesDestino.month - i).month,
        ),
    ];
    return SimpleDialog(
      title: const Text('Copiar plan desde'),
      children: <Widget>[
        for (final BusinessMonth mes in opciones)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(mes),
            child: Text('$mes'),
          ),
      ],
    );
  }
}
