import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_reading.dart';
import '../domain/simulacion.dart';
import '../domain/simulador_repository.dart';
import 'simulacion_dtos.dart';

final Provider<SimuladorRepository> simuladorRepositoryProvider =
    Provider<SimuladorRepository>((Ref ref) {
      return DioSimuladorRepository(client: ref.watch(apiClientProvider));
    });

/// Simulador de crédito sobre el cliente HTTP de la app.
class DioSimuladorRepository implements SimuladorRepository {
  const DioSimuladorRepository({required this.client});

  final ApiClient client;

  @override
  Future<SimulacionResultado> simular(SimulacionRequest request) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/simulaciones/credito',
        data: SimulacionRequestDto(request: request).toJson(),
      ),
    );
    return parseJson(() => SimulacionResponseDto.fromJson(body));
  }
}
