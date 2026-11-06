import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/dio_categorias_repository.dart';
import '../domain/categoria.dart';
import '../domain/categorias_repository.dart';
import '../domain/sugerencia_categoria.dart';

/// Milisegundos sin teclear antes de consultar al sugeridor (T10b).
const Duration debounceSugerencia = Duration(milliseconds: 400);

/// Catálogo de categorías para el selector del alta.
final FutureProvider<List<Categoria>> categoriasProvider =
    FutureProvider<List<Categoria>>((Ref ref) {
      return ref.watch(categoriasRepositoryProvider).listar();
    });

/// Sugeridor de categorías de F3.
///
/// - Debounce de 400 ms desde la última tecla.
/// - Solo aplica la respuesta si su `texto` (eco exacto) coincide con el
///   texto actual del formulario; las respuestas atrasadas se descartan.
/// - Nunca preselecciona por su cuenta cuando `ambigua=true`: la UI debe
///   pedir una elección explícita.
class SugerenciaCategoriaController
    extends AsyncNotifier<RespuestaSugerencia?> {
  Timer? _debounce;
  int _version = 0;
  String _textoActual = '';
  ContextoSugerencia _contexto = ContextoSugerencia.gasto;

  @override
  Future<RespuestaSugerencia?> build() async {
    ref.onDispose(() => _debounce?.cancel());
    return null;
  }

  /// Texto actual del formulario (para diagnóstico y tests).
  String get textoActual => _textoActual;

  /// Registra el texto escrito y agenda la consulta con debounce.
  void actualizarTexto(
    String texto, {
    ContextoSugerencia contexto = ContextoSugerencia.gasto,
  }) {
    _textoActual = texto;
    _contexto = contexto;
    _version += 1;
    final int version = _version;
    _debounce?.cancel();

    if (texto.trim().isEmpty) {
      state = const AsyncData<RespuestaSugerencia?>(null);
      return;
    }

    _debounce = Timer(debounceSugerencia, () {
      unawaited(_consultar(texto, contexto, version));
    });
  }

  Future<void> _consultar(
    String texto,
    ContextoSugerencia contexto,
    int version,
  ) async {
    state = const AsyncLoading<RespuestaSugerencia?>();
    final CategoriasRepository repository = ref.read(
      categoriasRepositoryProvider,
    );
    try {
      final RespuestaSugerencia respuesta = await repository.sugerir(
        texto: texto,
        contexto: contexto,
      );
      // Llegó tarde (otro texto ya se está escribiendo)…
      if (version != _version) {
        return;
      }
      // …o el eco no coincide con el texto actual: se descarta en silencio.
      if (respuesta.texto != _textoActual) {
        return;
      }
      state = AsyncData<RespuestaSugerencia?>(respuesta);
    } on AppFailure catch (error, stack) {
      if (version != _version) {
        return;
      }
      // El sugeridor es best-effort: la UI oculta el error.
      state = AsyncError<RespuestaSugerencia?>(error, stack);
    }
  }

  /// Limpia el estado (al cerrar el formulario).
  void limpiar() {
    _debounce?.cancel();
    _version += 1;
    _textoActual = '';
    state = const AsyncData<RespuestaSugerencia?>(null);
  }

  /// Contexto con el que se consultó por última vez (para tests).
  ContextoSugerencia get contextoActual => _contexto;
}

final AsyncNotifierProvider<
  SugerenciaCategoriaController,
  RespuestaSugerencia?
>
sugerenciaCategoriaProvider =
    AsyncNotifierProvider<SugerenciaCategoriaController, RespuestaSugerencia?>(
      SugerenciaCategoriaController.new,
    );
