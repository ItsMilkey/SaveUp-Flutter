import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../domain/categoria.dart';
import '../domain/movimiento_tipo.dart';
import '../domain/sugerencia_categoria.dart';
import 'categoria_sugerencia_controller.dart';
import 'nuevo_movimiento_controller.dart';

/// Alta mínima de movimiento con sugeridor de categorías (F3).
///
/// El contrato de `POST /movimientos` no recibe fecha: el backend usa el
/// instante del registro. El sugeridor nunca asigna en silencio: si la
/// respuesta es ambigua, la persona debe elegir explícitamente.
class NuevoMovimientoScreen extends ConsumerStatefulWidget {
  const NuevoMovimientoScreen({super.key});

  @override
  ConsumerState<NuevoMovimientoScreen> createState() =>
      _NuevoMovimientoScreenState();
}

class _NuevoMovimientoScreenState
    extends ConsumerState<NuevoMovimientoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();

  MovimientoTipo _tipo = MovimientoTipo.gastoGeneral;
  int? _categoriaSeleccionada;
  bool _seleccionManual = false;
  List<SugerenciaCategoria> _sugerencias = const <SugerenciaCategoria>[];
  bool _ambigua = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(nuevoMovimientoProvider.notifier).reset();
        ref.read(sugerenciaCategoriaProvider.notifier).limpiar();
      }
    });
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  ContextoSugerencia get _contexto => _tipo == MovimientoTipo.ingresoGeneral
      ? ContextoSugerencia.ingreso
      : ContextoSugerencia.gasto;

  void _consultarSugerencia() {
    ref
        .read(sugerenciaCategoriaProvider.notifier)
        .actualizarTexto(_descripcionController.text, contexto: _contexto);
  }

  @override
  Widget build(BuildContext context) {
    final NuevoMovimientoUiState ui = ref.watch(nuevoMovimientoProvider);
    final AsyncValue<List<Categoria>> categorias = ref.watch(
      categoriasProvider,
    );
    final bool enviando = ui is NuevoMovimientoSubmitting;

    // Aplica sugerencias solo con respuestas frescas (el controlador descarta
    // las atrasadas por eco de `texto`).
    ref.listen(sugerenciaCategoriaProvider, (
      _,
      AsyncValue<RespuestaSugerencia?> next,
    ) {
      final RespuestaSugerencia? respuesta = next.value;
      if (respuesta == null) {
        return;
      }
      setState(() {
        _sugerencias = respuesta.sugerencias;
        _ambigua = respuesta.ambigua;
        final bool haySugerencias = respuesta.sugerencias.isNotEmpty;
        // Preselección solo si NO es ambigua y la persona no eligió a mano.
        if (!respuesta.ambigua && haySugerencias && !_seleccionManual) {
          _categoriaSeleccionada = respuesta.sugerencias.first.categoriaId;
        }
      });
    });

    // Al 200 el backend ya registró: volver con resultado para refrescar home.
    ref.listen(nuevoMovimientoProvider, (_, NuevoMovimientoUiState next) {
      if (next is NuevoMovimientoSuccess) {
        Navigator.of(context).pop(true);
      }
    });

    String? errorFor(String campo) => switch (ui) {
      NuevoMovimientoFieldErrors(:final Map<String, String> errors) =>
        errors[campo],
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo movimiento')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              if (ui is NuevoMovimientoError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    ui.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (ui is NuevoMovimientoFieldErrors && ui.global != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    ui.global!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              DropdownButtonFormField<MovimientoTipo>(
                initialValue: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  prefixIcon: Icon(Icons.swap_vert),
                ),
                items: const <DropdownMenuItem<MovimientoTipo>>[
                  DropdownMenuItem<MovimientoTipo>(
                    value: MovimientoTipo.gastoGeneral,
                    child: Text('Gasto'),
                  ),
                  DropdownMenuItem<MovimientoTipo>(
                    value: MovimientoTipo.ingresoGeneral,
                    child: Text('Ingreso'),
                  ),
                ],
                onChanged: (MovimientoTipo? tipo) {
                  if (tipo == null) {
                    return;
                  }
                  setState(() => _tipo = tipo);
                  if (_descripcionController.text.trim().isNotEmpty) {
                    _consultarSugerencia();
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _consultarSugerencia(),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Describe el movimiento.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: const Icon(Icons.notes),
                  errorText: errorFor('descripcion'),
                ),
              ),
              if (_sugerencias.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _ambigua
                      ? 'Hay más de una categoría posible: elige la correcta.'
                      : 'Categorías sugeridas (puedes cambiarla):',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final SugerenciaCategoria sugerencia in _sugerencias)
                      ChoiceChip(
                        label: Text(sugerencia.nombre),
                        selected:
                            _categoriaSeleccionada == sugerencia.categoriaId,
                        onSelected: (_) => setState(() {
                          _categoriaSeleccionada = sugerencia.categoriaId;
                          _seleccionManual = true;
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el monto.';
                  }
                  try {
                    Money.parseUserInput(value);
                  } on FormatException {
                    return 'Ingresa un monto válido.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: const Icon(Icons.attach_money),
                  hintText: '12.500',
                  errorText: errorFor('monto'),
                ),
              ),
              const SizedBox(height: 12),
              _CategoriaSelector(
                categorias: categorias,
                seleccionada: _categoriaSeleccionada,
                onChanged: (int? id) => setState(() {
                  _categoriaSeleccionada = id;
                  _seleccionManual = true;
                }),
                errorText: errorFor('categoriaId'),
                onReintentar: () => ref.invalidate(categoriasProvider),
              ),
              const SizedBox(height: 20),
              if (enviando)
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Guardando…'),
                  ],
                )
              else
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Guardar movimiento'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final Decimal monto = Money.parseUserInput(_montoController.text);
    await ref
        .read(nuevoMovimientoProvider.notifier)
        .submit(
          monto: monto,
          descripcion: _descripcionController.text,
          tipo: _tipo,
          categoriaId: _categoriaSeleccionada,
        );
  }
}

class _CategoriaSelector extends StatelessWidget {
  const _CategoriaSelector({
    required this.categorias,
    required this.seleccionada,
    required this.onChanged,
    this.errorText,
    required this.onReintentar,
  });

  final AsyncValue<List<Categoria>> categorias;
  final int? seleccionada;
  final ValueChanged<int?> onChanged;
  final String? errorText;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return categorias.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (Object error, StackTrace stack) => Row(
        children: <Widget>[
          const Expanded(child: Text('No se pudo cargar el catálogo.')),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
      data: (List<Categoria> lista) {
        final bool existe = lista.any((Categoria c) => c.id == seleccionada);
        return DropdownButtonFormField<int>(
          key: ValueKey<int?>(seleccionada),
          initialValue: existe ? seleccionada : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Categoría',
            prefixIcon: const Icon(Icons.category_outlined),
            errorText: errorText,
          ),
          items: <DropdownMenuItem<int>>[
            for (final Categoria categoria in lista)
              DropdownMenuItem<int>(
                value: categoria.id,
                child: Text(categoria.nombre),
              ),
          ],
          onChanged: onChanged,
          validator: (_) => null,
        );
      },
    );
  }
}
