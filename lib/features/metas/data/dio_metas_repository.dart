import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_reading.dart';
import '../domain/meta_ahorro.dart';
import '../domain/metas_repository.dart';
import 'meta_dtos.dart';

final Provider<MetasRepository> metasRepositoryProvider =
    Provider<MetasRepository>((Ref ref) {
      return DioMetasRepository(client: ref.watch(apiClientProvider));
    });

/// Metas de ahorro sobre el cliente HTTP de la app.
class DioMetasRepository implements MetasRepository {
  const DioMetasRepository({required this.client});

  final ApiClient client;

  @override
  Future<List<MetaAhorro>> listar() async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>('/metas/me'),
    );
    return parseJson(
      () => body
          .map(
            (Object? item) => MetaAhorroDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<MetaAhorro> crear(MetaAhorroDatos datos) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/metas',
        data: MetaAhorroDatosDto(datos).toJson(),
      ),
    );
    return parseJson(() => MetaAhorroDto.fromJson(body));
  }

  @override
  Future<MetaAhorro> editar(int id, MetaAhorroDatos datos) async {
    final Map<String, dynamic> body = await readObject(
      () => client.put<dynamic>(
        '/metas/$id',
        data: MetaAhorroDatosDto(datos).toJson(),
      ),
    );
    return parseJson(() => MetaAhorroDto.fromJson(body));
  }

  @override
  Future<void> eliminar(int id) async {
    // Contrato: 204 sin cuerpo.
    await client.delete<dynamic>('/metas/$id');
  }

  @override
  Future<MetaAhorro> abonar(
    int id, {
    required Decimal monto,
    required String descripcion,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/metas/$id/abonar',
        data: AbonoRetiroDto(monto: monto, descripcion: descripcion).toJson(),
      ),
    );
    return parseJson(() => MetaAhorroDto.fromJson(body));
  }

  @override
  Future<MetaAhorro> retirar(
    int id, {
    required Decimal monto,
    required String descripcion,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/metas/$id/retirar',
        data: AbonoRetiroDto(monto: monto, descripcion: descripcion).toJson(),
      ),
    );
    return parseJson(() => MetaAhorroDto.fromJson(body));
  }
}
