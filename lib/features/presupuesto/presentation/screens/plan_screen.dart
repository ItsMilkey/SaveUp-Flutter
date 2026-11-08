import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          ? NeoButton(
              onPressed: _nuevaPartida,
              icon: Icons.add,
              label: 'Nueva partida',
            )
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
          const SizedBox(height: AppSpacing.sm),
          if (plan.grupos.isEmpty && plan.partidas.isNotEmpty)
            _SeccionGrupo(
              titulo: 'Sin grupo',
              color: AppColors.lavender,
              planificado: plan.calculo.resumen.planificadoTotal,
              real: plan.partidas.fold(
                Decimal.zero,
                (Decimal a, PartidaPlan p) => a + p.real,
              ),
              partidaIds: <int>[
                for (final PartidaPlan p in plan.partidas) p.id,
              ],
              onEditar: _editarPartida,
              onEliminar: _eliminarPartida,
            )
          else
            for (int i = 0; i < plan.grupos.length; i++)
              _SeccionGrupo(
                titulo: plan.grupos[i].nombre,
                color: _coloresGrupo[i % _coloresGrupo.length],
                planificado: plan.grupos[i].planificado,
                real: plan.grupos[i].real,
                partidaIds: plan.grupos[i].partidaIds,
                onEditar: _editarPartida,
                onEliminar: _eliminarPartida,
              ),
        ],
      ),
    );
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

class _Resumen extends StatelessWidget {
  const _Resumen({required this.plan, required this.onEditarIngreso});

  final PlanMensual plan;
  final VoidCallback onEditarIngreso;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    final ResumenCalculado resumen = plan.calculo.resumen;
    final String remanente = resumen.remanenteLibre == null
        ? 'Sin ingreso de referencia'
        : Money.formatClp(resumen.remanenteLibre!);
    final String margen = resumen.margenSeguridadPct == null
        ? '—'
        : '${resumen.margenSeguridadPct} %';

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
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Expanded(
                child: _fila(
                  textTheme,
                  'Ingreso de referencia',
                  plan.ingresoReferencia == null
                      ? 'Sin definir'
                      : Money.formatClp(plan.ingresoReferencia!),
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
          _fila(
            textTheme,
            'Planificado',
            Money.formatClp(resumen.planificadoTotal),
          ),
          _fila(textTheme, 'Remanente libre', remanente),
          _fila(textTheme, 'Margen de seguridad', margen),
          const Divider(),
          for (final RepartoTipoResultado fila in plan.calculo.repartoPorTipo)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 110,
                    child: Text(
                      switch (fila.tipo) {
                        TipoPresupuesto.necesidad => 'Necesidades',
                        TipoPresupuesto.deseo => 'Deseos',
                        TipoPresupuesto.otros => 'Otros',
                        TipoPresupuesto.ahorro => 'Ahorro',
                      },
                      style: textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${Money.formatClp(fila.planificado)} '
                      '(${fila.porcentajeDelIngreso ?? '—'} %)',
                    ),
                  ),
                  if (fila.diferenciaPuntos != null)
                    Text(
                      '${fila.diferenciaPuntos! >= Decimal.zero ? '+' : ''}'
                      '${fila.diferenciaPuntos} pts',
                      style: textTheme.bodySmall?.copyWith(
                        color: fila.diferenciaPuntos! > Decimal.zero
                            ? AppColors.danger
                            : AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          if (plan.calculo.guia != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Guía: ${plan.calculo.guia!.necesidades} / '
                '${plan.calculo.guia!.deseos} / ${plan.calculo.guia!.ahorro}',
                style: textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _fila(TextTheme textTheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(label, style: textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
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
    required this.onEditar,
    required this.onEliminar,
  });

  final String titulo;
  final Color color;
  final Decimal planificado;
  final Decimal real;
  final List<int> partidaIds;
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
          ],
        ),
        if (partidaIds.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text('Sin partidas en este mes.'),
          )
        else
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
