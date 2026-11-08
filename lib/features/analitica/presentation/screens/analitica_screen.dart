import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../domain/analitica.dart';
import '../controllers/analitica_controller.dart';
import '../widgets/analitica_colors.dart';
import '../widgets/barras_mensuales_card.dart';
import '../widgets/reparto_por_tipo_card.dart';
import '../widgets/top_categorias_card.dart';
import '../widgets/torta_gastos_card.dart';

/// Analítica de gastos: KPIs, torta por categoría, tendencia y reparto.
class AnaliticaScreen extends ConsumerStatefulWidget {
  const AnaliticaScreen({super.key});

  @override
  ConsumerState<AnaliticaScreen> createState() => _AnaliticaScreenState();
}

class _AnaliticaScreenState extends ConsumerState<AnaliticaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(analiticaProvider.notifier).cargar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AnaliticaState estado = ref.watch(analiticaProvider);

    return NeoScaffold(
      appBar: NeoAppBar(
        title: 'Analítica',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              NeoIconButton(
                icon: Icons.chevron_left,
                tooltip: 'Mes anterior',
                variant: NeoIconButtonVariant.ghost,
                onPressed: estado.cargando
                    ? null
                    : () =>
                          ref.read(analiticaProvider.notifier).cambiarMes(-1),
              ),
              Text(
                '${estado.mes}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              NeoIconButton(
                icon: Icons.chevron_right,
                tooltip: 'Mes siguiente',
                variant: NeoIconButtonVariant.ghost,
                onPressed: estado.cargando
                    ? null
                    : () =>
                          ref.read(analiticaProvider.notifier).cambiarMes(1),
              ),
            ],
          ),
        ),
      ),
      body: _cuerpo(estado),
    );
  }

  Widget _cuerpo(AnaliticaState estado) {
    if (estado.cargando && estado.resumen == null) {
      return const NeoLoading(rows: 3);
    }
    if (estado.error != null && estado.resumen == null) {
      return NeoErrorState(
        message: failureMessage(estado.error!),
        onRetry: () => ref.read(analiticaProvider.notifier).reintentar(),
      );
    }
    final ResumenAnalitica? resumen = estado.resumen;
    if (resumen == null) {
      return NeoErrorState(
        message: 'No se pudo cargar la analítica.',
        onRetry: () => ref.read(analiticaProvider.notifier).reintentar(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(analiticaProvider.notifier).reintentar(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: <Widget>[
          if (estado.errorHistorial != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: NeoErrorBand(
                message:
                    'No se pudo cargar la tendencia: '
                    '${failureMessage(estado.errorHistorial!)}',
              ),
            ),
          if (resumen.vacio)
            NeoEmptyState(
              title: 'Sin movimientos',
              message: 'No hay movimientos registrados en este mes.',
              icon: Icons.insights_outlined,
              action: NeoButton(
                label: 'Reintentar',
                variant: NeoButtonVariant.secondary,
                onPressed: () =>
                    ref.read(analiticaProvider.notifier).reintentar(),
              ),
            )
          else ...<Widget>[
            _Kpis(resumen: resumen),
            const SizedBox(height: AppSpacing.lg),
            TortaGastosCard(
              categorias: resumen.categorias,
              total: resumen.gastos,
            ),
            const SizedBox(height: AppSpacing.lg),
            BarrasMensualesCard(puntos: resumen.tendencia),
            const SizedBox(height: AppSpacing.lg),
            RepartoPorTipoCard(tipos: resumen.porTipo),
            const SizedBox(height: AppSpacing.lg),
            TopCategoriasCard(categorias: resumen.categorias),
          ],
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.resumen});

  final ResumenAnalitica resumen;

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    final Decimal disponible = resumen.disponible;
    return Column(
      children: <Widget>[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: NeoStat(
                  label: 'Ingresos',
                  icon: Icons.south_west,
                  color: colors.info,
                  value: NeoMoneyText(
                    amount: resumen.ingresos,
                    size: NeoMoneySize.title,
                    tone: NeoMoneyTone.onAccent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: NeoStat(
                  label: 'Gastos',
                  icon: Icons.north_east,
                  color: AppColors.magenta,
                  value: NeoMoneyText(
                    amount: resumen.gastos,
                    size: NeoMoneySize.title,
                    tone: NeoMoneyTone.onAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: NeoStat(
                  label: 'Ahorro',
                  icon: Icons.savings_outlined,
                  color: colors.success,
                  value: NeoMoneyText(
                    amount: resumen.ahorro,
                    size: NeoMoneySize.title,
                    tone: NeoMoneyTone.onAccent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: NeoStat(
                  label: 'Disponible',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.yellow,
                  value: NeoMoneyText(
                    amount: disponible,
                    size: NeoMoneySize.title,
                    tone: NeoMoneyTone.onAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Mes ${mesCorto(resumen.mes)} ${resumen.mes.year}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.muted,
          ),
        ),
      ],
    );
  }
}
