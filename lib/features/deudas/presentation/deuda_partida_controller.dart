import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/business_month.dart';
import '../../presupuesto/data/dio_plan_mensual_repository.dart';
import '../../presupuesto/domain/plan_mensual.dart';

/// Partida del plan del mes en curso vinculada a [deudaId], si existe.
///
/// El vínculo se crea con `POST /planes/{mes}/partidas` enviando `deudaId`;
/// este provider permite que el detalle de la deuda muestre si ya está en el
/// plan sin duplicar la regla en la UI.
final partidaDeDeudaProvider = FutureProvider.family<PartidaPlan?, int>((
  Ref ref,
  int deudaId,
) async {
  final String mes = BusinessMonth.fromInstant(DateTime.now()).toString();
  final PlanMensual plan = await ref
      .watch(planMensualRepositoryProvider)
      .obtener(mes);
  for (final PartidaPlan partida in plan.partidas) {
    if (partida.deudaId == deudaId) {
      return partida;
    }
  }
  return null;
});
