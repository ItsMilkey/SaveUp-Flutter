import 'package:decimal/decimal.dart';
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

  @override
  Future<PlanMensual> copiarDesde(String mes, String mesOrigen) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>('/planes/$mes/copiar-desde/$mesOrigen'),
    );
    return parseJson(() => PlanMensualDto.fromJson(body));
  }

  @override
  Future<List<GrupoPlan>> listarGrupos() async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>('/planes/grupos'),
    );
    return parseJson(
      () => body
          .map(
            (Object? item) => GrupoPlanDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<GrupoPlan> crearGrupo({required String nombre, int? orden}) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/planes/grupos',
        data: GrupoPlanCreacionDto(nombre: nombre, orden: orden).toJson(),
      ),
    );
    return parseJson(() => GrupoPlanDto.fromJson(body));
  }

  @override
  Future<GrupoPlan> editarGrupo(int id, {String? nombre, int? orden}) async {
    final Map<String, dynamic> body = await readObject(
      () => client.put<dynamic>(
        '/planes/grupos/$id',
        data: GrupoPlanEdicionDto(nombre: nombre, orden: orden).toJson(),
      ),
    );
    return parseJson(() => GrupoPlanDto.fromJson(body));
  }

  @override
  Future<void> eliminarGrupo(int id) async {
    // Contrato: 204 sin cuerpo.
    await client.delete<dynamic>('/planes/grupos/$id');
  }

  @override
  Future<PlanMensual> actualizarIngreso(String mes, Decimal? monto) async {
    final Map<String, dynamic> body = await readObject(
      () => client.put<dynamic>(
        '/planes/$mes/ingreso-referencia',
        data: IngresoReferenciaDto(monto: monto).toJson(),
      ),
    );
    return parseJson(() => PlanMensualDto.fromJson(body));
  }

  @override
  Future<PlanMensual> crearPartida(
    String mes, {
    required String nombre,
    int? categoriaId,
    Decimal? montoPlanificado,
    int? grupoId,
    int? deudaId,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/planes/$mes/partidas',
        data: PartidaCreacionDto(
          nombre: nombre,
          categoriaId: categoriaId,
          montoPlanificado: montoPlanificado,
          grupoId: grupoId,
          deudaId: deudaId,
        ).toJson(),
      ),
    );
    return parseJson(() => PlanMensualDto.fromJson(body));
  }

  @override
  Future<PlanMensual> editarPartida(
    String mes,
    int id, {
    String? nombre,
    int? categoriaId,
    int? grupoId,
    bool quitarGrupo = false,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.put<dynamic>(
        '/planes/$mes/partidas/$id',
        data: PartidaEdicionDto(
          nombre: nombre,
          categoriaId: categoriaId,
          grupoId: grupoId,
          quitarGrupo: quitarGrupo,
        ).toJson(),
      ),
    );
    return parseJson(() => PlanMensualDto.fromJson(body));
  }

  @override
  Future<void> eliminarPartida(String mes, int id) async {
    // Contrato: 204 sin cuerpo.
    await client.delete<dynamic>('/planes/$mes/partidas/$id');
  }
}
