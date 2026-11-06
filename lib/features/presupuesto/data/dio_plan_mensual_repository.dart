import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_reading.dart';
import '../domain/plan_mensual.dart';
import 'plan_dtos.dart';

final Provider<PlanMensualRepository> planMensualRepositoryProvider =
    Provider<PlanMensualRepository>((Ref ref) {
      return DioPlanMensualRepository(client: ref.watch(apiClientProvider));
    });

/// Plan mensual sobre el cliente HTTP de la app.
class DioPlanMensualRepository implements PlanMensualRepository {
  const DioPlanMensualRepository({required this.client});

  final ApiClient client;

  @override
  Future<PlanMensual> obtener(
    String mes, {
    bool incluirReferencias = false,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.get<dynamic>(
        '/planes/$mes',
        queryParameters: incluirReferencias
            ? <String, dynamic>{'incluirReferencias': true}
            : null,
      ),
    );
    return parseJson(() => PlanMensualDto.fromJson(body));
  }

  @override
  Future<PlanMensual> actualizarMontos(
    String mes,
    List<CambioMonto> cambios,
  ) async {
    final Map<String, dynamic> body = await readObject(
      () => client.patch<dynamic>(
        '/planes/$mes/montos',
        data: CambiosMontosDto(cambios: cambios).toJson(),
      ),
    );
    return parseJson(() => PlanMensualDto.fromJson(body));
  }
}
