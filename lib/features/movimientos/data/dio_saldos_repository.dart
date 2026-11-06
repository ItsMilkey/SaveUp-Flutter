import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/saldos_repository.dart';
import 'json_reading.dart';
import 'movimiento_dtos.dart';

final Provider<SaldosRepository> saldosRepositoryProvider =
    Provider<SaldosRepository>((Ref ref) {
      return DioSaldosRepository(client: ref.watch(apiClientProvider));
    });

/// `GET /saldos/me` sobre el cliente HTTP de la app.
class DioSaldosRepository implements SaldosRepository {
  const DioSaldosRepository({required this.client});

  final ApiClient client;

  @override
  Future<Decimal> saldoActual() async {
    final Map<String, dynamic> body = await readObject(
      () => client.get<dynamic>('/saldos/me'),
    );
    return parseJson(() => SaldoDto.fromJson(body).saldo);
  }
}
