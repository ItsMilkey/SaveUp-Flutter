import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_reading.dart';
import '../domain/asignacion_presupuesto.dart';
import '../domain/ejecucion_presupuesto.dart';
import '../domain/limite_categoria.dart';
import '../domain/presupuesto_repository.dart';
import '../domain/regla_presupuestaria.dart';
import 'presupuesto_dtos.dart';

final Provider<PresupuestoRepository> presupuestoRepositoryProvider =
    Provider<PresupuestoRepository>((Ref ref) {
      return DioPresupuestoRepository(client: ref.watch(apiClientProvider));
    });

/// Presupuesto sobre el cliente HTTP de la app.
class DioPresupuestoRepository implements PresupuestoRepository {
  const DioPresupuestoRepository({required this.client});

  final ApiClient client;

  @override
  Future<ConfiguracionPresupuesto> obtenerConfiguracion() async {
    final Map<String, dynamic> body = await readObject(
      () => client.get<dynamic>('/presupuestos/me'),
    );
    return parseJson(() => ConfiguracionPresupuestoDto.fromJson(body));
  }

  @override
  Future<ConfiguracionPresupuesto> guardarConfiguracion({
    required PorcentajesRegla porcentajes,
    bool activo = true,
    bool automatizarAhorroEnMetas = false,
    List<AsignacionPresupuestoDatos>? asignaciones,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/presupuestos/me',
        data: ConfiguracionPresupuestoRequestDto(
          porcentajes: porcentajes,
          activo: activo,
          automatizarAhorroEnMetas: automatizarAhorroEnMetas,
          asignaciones: asignaciones,
        ).toJson(),
      ),
    );
    return parseJson(() => ConfiguracionPresupuestoDto.fromJson(body));
  }

  @override
  Future<List<AsignacionPresupuesto>> listarAsignaciones() async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>('/presupuestos/asignaciones/me'),
    );
    return parseJson(
      () => body
          .map(
            (Object? item) => AsignacionPresupuestoDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<SugerenciaRegla> sugerenciaRegla() async {
    final Map<String, dynamic> body = await readObject(
      () => client.get<dynamic>('/presupuestos/sugerencia-regla'),
    );
    return parseJson(() => SugerenciaReglaDto.fromJson(body));
  }

  @override
  Future<EjecucionPresupuesto> ejecucion({int? month, int? year}) async {
    final Map<String, dynamic> body = await readObject(
      () => client.get<dynamic>(
        '/presupuestos/ejecucion/me',
        queryParameters: <String, dynamic>{
          'month': ?month,
          'year': ?year,
        },
      ),
    );
    return parseJson(() => EjecucionPresupuestoDto.fromJson(body));
  }

  @override
  Future<List<HistorialPresupuesto>> historial({
    required String desde,
    required String hasta,
  }) async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>(
        '/presupuestos/historial/me',
        queryParameters: <String, dynamic>{'desde': desde, 'hasta': hasta},
      ),
    );
    return parseJson(
      () => body
          .map(
            (Object? item) => HistorialPresupuestoDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<LimiteCategoria>> listarLimites() async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>('/presupuestos/categorias/me'),
    );
    return parseJson(
      () => body
          .map(
            (Object? item) => LimiteCategoriaDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<LimiteCategoria>> reemplazarLimites(
    List<LimiteCategoriaItem> categorias,
  ) async {
    final List<dynamic> body = await readList(
      () => client.put<dynamic>(
        '/presupuestos/categorias/me',
        data: LimitesCategoriaRequestDto(categorias: categorias).toJson(),
      ),
    );
    return parseJson(
      () => body
          .map(
            (Object? item) => LimiteCategoriaDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<EjecucionCategoria>> ejecucionCategorias({
    int? month,
    int? year,
  }) async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>(
        '/presupuestos/categorias/ejecucion/me',
        queryParameters: <String, dynamic>{
          'month': ?month,
          'year': ?year,
        },
      ),
    );
    return parseJson(
      () => body
          .map(
            (Object? item) => EjecucionCategoriaDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
