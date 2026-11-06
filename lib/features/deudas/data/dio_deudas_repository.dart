import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_reading.dart';
import '../domain/deuda.dart';
import '../domain/deudas_repository.dart';
import 'deuda_dtos.dart';

final Provider<DeudasRepository> deudasRepositoryProvider =
    Provider<DeudasRepository>((Ref ref) {
      return DioDeudasRepository(client: ref.watch(apiClientProvider));
    });

/// Deudas sobre el cliente HTTP de la app.
class DioDeudasRepository implements DeudasRepository {
  const DioDeudasRepository({required this.client});

  final ApiClient client;

  @override
  Future<List<Deuda>> listar() async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>('/deudas/me'),
    );
    return parseJson(
      () => body
          .map(
            (Object? item) => DeudaDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Deuda> detalle(int id) async {
    final Map<String, dynamic> body = await readObject(
      () => client.get<dynamic>('/deudas/$id'),
    );
    return parseJson(() => DeudaDto.fromJson(body));
  }

  @override
  Future<Deuda> crear(DeudaCreacion deuda) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/deudas',
        data: DeudaCreacionDto(deuda: deuda).toJson(),
      ),
    );
    return parseJson(() => DeudaDto.fromJson(body));
  }

  @override
  Future<Deuda> editar(int id, DeudaCreacion deuda) async {
    final Map<String, dynamic> body = await readObject(
      () => client.put<dynamic>(
        '/deudas/$id',
        data: DeudaCreacionDto(deuda: deuda).toJson(),
      ),
    );
    return parseJson(() => DeudaDto.fromJson(body));
  }

  @override
  Future<List<CuotaAmortizacion>> amortizacion(int id) async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>('/deudas/$id/amortizacion'),
    );
    return parseJson(
      () => body
          .map(
            (Object? item) => CuotaAmortizacionDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
