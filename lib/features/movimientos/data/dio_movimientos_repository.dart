import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_reading.dart';
import '../domain/movimiento.dart';
import '../domain/movimiento_filtro.dart';
import '../domain/movimiento_tipo.dart';
import '../domain/movimientos_repository.dart';
import 'movimiento_dtos.dart';

final Provider<MovimientosRepository> movimientosRepositoryProvider =
    Provider<MovimientosRepository>((Ref ref) {
      return DioMovimientosRepository(client: ref.watch(apiClientProvider));
    });

/// Movimientos sobre el cliente HTTP de la app.
class DioMovimientosRepository implements MovimientosRepository {
  const DioMovimientosRepository({required this.client});

  final ApiClient client;

  @override
  Future<PaginaMovimientos> pagina({
    required MovimientoFiltro filtro,
    required int page,
    int size = 50,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.get<dynamic>(
        '/movimientos/paginados/me',
        queryParameters: <String, dynamic>{
          ...filtro.toQueryParameters(),
          'page': page,
          'size': size,
        },
      ),
    );
    return parseJson(() => PaginaMovimientosDto.fromJson(body).toDomain());
  }

  @override
  Future<void> registrar({
    required Decimal monto,
    required String descripcion,
    required MovimientoTipo tipo,
    int? categoriaId,
  }) async {
    // El contrato responde 200 con el movimiento creado; aquí solo importa
    // que la operación haya sido aceptada (la UI refresca saldo y listado).
    await readObject(
      () => client.post<dynamic>(
        '/movimientos',
        data: MovimientoRegistroDto(
          monto: monto,
          descripcion: descripcion,
          tipo: tipo,
          categoriaId: categoriaId,
        ).toJson(),
      ),
    );
  }

  @override
  Future<Movimiento> editar({
    required int id,
    Decimal? monto,
    String? descripcion,
    int? categoriaId,
    int? partidaId,
    bool desvincularPartida = false,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.put<dynamic>(
        '/movimientos/$id',
        data: MovimientoEdicionDto(
          monto: monto,
          descripcion: descripcion,
          categoriaId: categoriaId,
          partidaId: partidaId,
          desvincularPartida: desvincularPartida,
        ).toJson(),
      ),
    );
    return parseJson(() => MovimientoDto.fromJson(body).toDomain());
  }

  @override
  Future<void> eliminar(int id) async {
    // Contrato: 204 sin cuerpo.
    await client.delete<dynamic>('/movimientos/$id');
  }
}
