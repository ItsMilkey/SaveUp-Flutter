import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/money/money.dart';
import '../../../../core/time/business_month.dart';
import '../../domain/plan_calculo.dart';
import '../../domain/plan_mensual.dart';
import '../controllers/plan_mensual_controller.dart';
import '../widgets/grupos_plan_dialog.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Plan $_mes'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mes anterior',
            onPressed: () => _cambiarMes(-1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Mes siguiente',
            onPressed: () => _cambiarMes(1),
          ),
          IconButton(
            icon: Icon(
              estado.incluirReferencias ? Icons.history : Icons.history_toggle_off,
            ),
            tooltip: 'Referencias históricas',
            onPressed: _alternarReferencias,
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Grupos',
            onPressed: _abrirGrupos,
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Copiar desde otro mes',
            onPressed: estado.copiando ? null : _copiarMes,
          ),
        ],
      ),
      body: _cuerpo(estado),
    );
  }

  Widget _cuerpo(PlanMensualState estado) {
    if (estado.cargando && estado.plan == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (estado.errorCarga != null && estado.plan == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(failureMessage(estado.errorCarga!)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref
                  .read(planMensualProvider.notifier)
                  .cargar(_mes.toString()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    final PlanMensual? plan = estado.plan;
    if (plan == null) {
      return const Center(child: Text('Sin datos del plan.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(planMensualProvider.notifier)
          .cargar(_mes.toString()),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: <Widget>[
          if (!plan.existe)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    const Text('Aún no hay un plan para este mes.'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_all_outlined),
                      label: const Text('Copiar desde otro mes'),
                      onPressed: estado.copiando ? null : _copiarMes,
                    ),
                  ],
                ),
              ),
            ),
          if (plan.avisos.isNotEmpty) _Avisos(avisos: plan.avisos),
          _Resumen(plan: plan),
          if (estado.errorLote != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      failureMessage(estado.errorLote!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
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
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          if (estado.incluirReferencias) _Referencias(plan: plan),
          const SizedBox(height: 8),
          if (plan.grupos.isEmpty && plan.partidas.isNotEmpty)
            _SeccionGrupo(
              titulo: 'Sin grupo',
              planificado: plan.calculo.resumen.planificadoTotal,
              real: plan.partidas.fold(
                Decimal.zero,
                (Decimal a, PartidaPlan p) => a + p.real,
              ),
              partidaIds: <int>[
                for (final PartidaPlan p in plan.partidas) p.id,
              ],
            )
          else
            for (final GrupoResultado grupo in plan.grupos)
              _SeccionGrupo(
                titulo: grupo.nombre,
                planificado: grupo.planificado,
                real: grupo.real,
                partidaIds: grupo.partidaIds,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage(failure))));
      return;
    }
    final PlanMensualState estado = ref.read(planMensualProvider);
    final List<AvisoPlan> avisos = estado.plan?.avisos ?? const <AvisoPlan>[];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          avisos.isEmpty
              ? 'Plan copiado desde $origen.'
              : 'Plan copiado con ${avisos.length} aviso(s).',
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.plan});

  final PlanMensual plan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ResumenCalculado resumen = plan.calculo.resumen;
    final String remanente = resumen.remanenteLibre == null
        ? 'Sin ingreso de referencia'
        : Money.formatClp(resumen.remanenteLibre!);
    final String margen = resumen.margenSeguridadPct == null
        ? '—'
        : '${resumen.margenSeguridadPct} %';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('Resumen', style: theme.textTheme.titleMedium),
                ),
                if (resumen.excedeIngreso)
                  Chip(
                    label: const Text('Excede el ingreso'),
                    labelStyle: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 11,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _fila(theme, 'Planificado', Money.formatClp(resumen.planificadoTotal)),
            _fila(theme, 'Remanente libre', remanente),
            _fila(theme, 'Margen de seguridad', margen),
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
                        style: theme.textTheme.bodySmall,
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: fila.diferenciaPuntos! > Decimal.zero
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            if (plan.calculo.guia != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Guía: ${plan.calculo.guia!.necesidades} / '
                  '${plan.calculo.guia!.deseos} / ${plan.calculo.guia!.ahorro}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fila(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(label, style: theme.textTheme.bodySmall),
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
    required this.planificado,
    required this.real,
    required this.partidaIds,
  });

  final String titulo;
  final Decimal planificado;
  final Decimal real;
  final List<int> partidaIds;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(titulo, style: theme.textTheme.titleMedium),
              ),
              Text(
                '${Money.formatClp(planificado)} · real '
                '${Money.formatClp(real)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (partidaIds.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Sin partidas en este mes.'),
          )
        else
          for (final int id in partidaIds) PartidaMontoSlider(partidaId: id),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Referencias históricas', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
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
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Avisos de la copia',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final AvisoPlan aviso in avisos)
              Text(
                '• ${aviso.mensaje ?? aviso.motivo}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
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
