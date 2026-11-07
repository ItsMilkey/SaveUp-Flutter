import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_reading.dart';
import '../domain/categorias_preferencias_repository.dart';
import '../domain/plan_calculo.dart';
import '../domain/preferencia_categoria.dart';
import 'preferencia_dtos.dart';

final Provider<CategoriasPreferenciasRepository>
categoriasPreferenciasRepositoryProvider =
    Provider<CategoriasPreferenciasRepository>((Ref ref) {
      return DioCategoriasPreferenciasRepository(
        client: ref.watch(apiClientProvider),
      );
    });

/// Preferencias de tipo de categoría sobre el cliente HTTP.
class DioCategoriasPreferenciasRepository
    implements CategoriasPreferenciasRepository {
  const DioCategoriasPreferenciasRepository({required this.client});

  final ApiClient client;

  @override
  Future<List<PreferenciaCategoria>> listar() async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>('/categorias/preferencias'),
    );
    return parseJson(
      () => body
          .map(
            (Object? item) => PreferenciaCategoriaDto.fromJson(
              (item as Map).map(
                (Object? k, Object? v) => MapEntry(k.toString(), v),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<PreferenciaCategoria> establecerTipoPreferido(
    int categoriaId,
    TipoPresupuesto tipo,
  ) async {
    final Map<String, dynamic> body = await readObject(
      () => client.put<dynamic>(
        '/categorias/$categoriaId/tipo-preferido',
        data: TipoPreferidoRequestDto(tipo: tipo).toJson(),
      ),
    );
    return parseJson(() => PreferenciaCategoriaDto.fromJson(body));
  }

  @override
  Future<void> quitarTipoPreferido(int categoriaId) async {
    // Contrato: 204 idempotente, sin cuerpo.
    await client.delete<dynamic>('/categorias/$categoriaId/tipo-preferido');
  }
}
