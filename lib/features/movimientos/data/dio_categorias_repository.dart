import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_reading.dart';
import '../domain/categoria.dart';
import '../domain/categorias_repository.dart';
import '../domain/sugerencia_categoria.dart';
import 'movimiento_dtos.dart';

final Provider<CategoriasRepository> categoriasRepositoryProvider =
    Provider<CategoriasRepository>((Ref ref) {
      return DioCategoriasRepository(client: ref.watch(apiClientProvider));
    });

/// Catálogo y sugeridor sobre el cliente HTTP de la app.
class DioCategoriasRepository implements CategoriasRepository {
  const DioCategoriasRepository({required this.client});

  final ApiClient client;

  @override
  Future<List<Categoria>> listar() async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>('/categorias'),
    );
    return parseJson(
      () => body
          .map(
            (Object? item) => CategoriaDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ).toDomain(),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<RespuestaSugerencia> sugerir({
    required String texto,
    ContextoSugerencia contexto = ContextoSugerencia.gasto,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.get<dynamic>(
        '/categorias/sugerencia',
        queryParameters: <String, dynamic>{
          'texto': texto,
          'contexto': contexto.codigo,
        },
      ),
    );
    return parseJson(() => SugerenciaRespuestaDto.fromJson(body).toDomain());
  }
}
