import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_input_formatter.dart';
import '../domain/categoria.dart';
import '../domain/movimiento.dart';
import '../domain/movimiento_tipo.dart';
import '../domain/sugerencia_categoria.dart';
import 'categoria_picker.dart';
import 'categoria_sugerencia_controller.dart';
import 'categoria_visual.dart';
import 'movimiento_labels.dart';
import 'movimientos_controller.dart';
import 'nuevo_movimiento_controller.dart';

/// Formulario de movimiento (alta y edición comparten pantalla).
///
/// Edición: `PUT /movimientos/{id}` — el **tipo no es editable** (el contrato
/// no lo incluye; el signo lo impone el tipo actual) y por eso se muestra
/// fijo. El contrato tampoco recibe fecha en el alta: la pone el backend.
/// El sugeridor nunca asigna en silencio: si la respuesta es ambigua, la
/// persona debe elegir explícitamente.
class MovimientoFormScreen extends ConsumerStatefulWidget {
  const MovimientoFormScreen({super.key, this.movimiento});

  /// `null` = alta; con valor = edición de ese movimiento.
  final Movimiento? movimiento;

  @override
  ConsumerState<MovimientoFormScreen> createState() =>
      _MovimientoFormScreenState();
}

class _MovimientoFormScreenState extends ConsumerState<MovimientoFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();

  late MovimientoTipo _tipo;
  int? _categoriaSeleccionada;
  bool _seleccionManual = false;
  List<SugerenciaCategoria> _sugerencias = const <SugerenciaCategoria>[];
  bool _ambigua = false;

  bool get _esEdicion => widget.movimiento != null;

  @override
  void initState() {
    super.initState();
    final Movimiento? inicial = widget.movimiento;
    _tipo = inicial?.tipo ?? MovimientoTipo.gastoGeneral;
    if (inicial != null) {
      _descripcionController.text = inicial.descripcion;
      // El campo de monto es positivo: el signo lo impone el tipo.
      _montoController.text = MoneyInputFormatter.format(inicial.monto.abs());
      _categoriaSeleccionada = inicial.categoria?.id;
    }
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

  Categoria? _categoriaDe(List<Categoria>? lista, int id) {
    for (final Categoria categoria in lista ?? const <Categoria>[]) {
      if (categoria.id == id) {
        return categoria;
      }
    }
    return null;
  }

  Widget _chipSugerencia(
    SugerenciaCategoria sugerencia,
    List<Categoria>? catalogo,
  ) {
    final Categoria? categoria = _categoriaDe(
      catalogo,
      sugerencia.categoriaId,
    );
    return ChoiceChip(
      avatar: categoria == null
          ? Icon(iconoDeCategoriaPorCodigo(sugerencia.codigo), size: 18)
          : IconoCategoria(categoria: categoria, size: 22),
      label: Text(sugerencia.nombre),
      selected: _categoriaSeleccionada == sugerencia.categoriaId,
      onSelected: (_) => setState(() {
        _categoriaSeleccionada = sugerencia.categoriaId;
        _seleccionManual = true;
      }),
    );
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

    // Al 200 volver con el resultado: alta (`true`) o movimiento actualizado.
    ref.listen(nuevoMovimientoProvider, (_, NuevoMovimientoUiState next) {
      if (next is NuevoMovimientoSuccess) {
        Navigator.of(context).pop(next.actualizado ?? true);
      }
    });

    String? errorFor(String campo) => switch (ui) {
      NuevoMovimientoFieldErrors(:final Map<String, String> errors) =>
        errors[campo],
      _ => null,
    };

    return NeoScaffold(
      appBar: NeoAppBar(
        title: _esEdicion ? 'Editar movimiento' : 'Nuevo movimiento',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              if (ui is NuevoMovimientoError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: NeoErrorBand(message: ui.message),
                ),
              if (ui is NuevoMovimientoFieldErrors && ui.global != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: NeoErrorBand(message: ui.global!),
                ),
              if (_esEdicion)
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    prefixIcon: Icon(Icons.swap_vert),
                  ),
                  child: Text(tipoMovimientoLabel(_tipo)),
                )
              else
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
                    final List<Categoria>? lista = categorias.value;
                    setState(() {
                      _tipo = tipo;
                      if (lista != null &&
                          _categoriaSeleccionada != null &&
                          !categoriasPermitidas(lista, tipo).any(
                            (Categoria c) => c.id == _categoriaSeleccionada,
                          )) {
                        _categoriaSeleccionada = null;
                        _seleccionManual = false;
                      }
                    });
                    if (_descripcionController.text.trim().isNotEmpty) {
                      _consultarSugerencia();
                    }
                  },
                ),
              const SizedBox(height: AppSpacing.md),
              NeoInput(
                controller: _descripcionController,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _consultarSugerencia(),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Describe el movimiento.';
                  }
                  return null;
                },
                label: 'Descripción',
                prefixIcon: Icons.notes,
                error: errorFor('descripcion'),
              ),
              if (_sugerencias.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _ambigua
                      ? 'Hay más de una categoría posible: elige la correcta.'
                      : 'Categorías sugeridas (puedes cambiarla):',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    for (final SugerenciaCategoria sugerencia in _sugerencias)
                      _chipSugerencia(sugerencia, categorias.value),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              NeoInput(
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
                label: 'Monto',
                hint: '12.500',
                prefixIcon: Icons.attach_money,
                inputFormatters: moneyInputFormatters,
                error: errorFor('monto'),
              ),
              const SizedBox(height: AppSpacing.md),
              _CategoriaSelector(
                categorias: categorias,
                seleccionada: _categoriaSeleccionada,
                tipo: _tipo,
                movimientos: ref.watch(movimientosProvider).items,
                onChanged: (int? id) => setState(() {
                  _categoriaSeleccionada = id;
                  _seleccionManual = true;
                }),
                errorText: errorFor('categoriaId'),
                onReintentar: () => ref.invalidate(categoriasProvider),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (enviando)
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    LinearProgressIndicator(),
                    SizedBox(height: AppSpacing.sm),
                    Text('Guardando…'),
                  ],
                )
              else
                NeoButton(
                  label: 'Guardar movimiento',
                  expanded: true,
                  onPressed: _submit,
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
    if (_esEdicion) {
      await ref
          .read(nuevoMovimientoProvider.notifier)
          .editar(
            id: widget.movimiento!.id,
            monto: monto,
            descripcion: _descripcionController.text,
            categoriaId: _categoriaSeleccionada,
          );
      return;
    }
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
    required this.tipo,
    required this.movimientos,
    required this.onChanged,
    this.errorText,
    required this.onReintentar,
  });

  final AsyncValue<List<Categoria>> categorias;
  final int? seleccionada;
  final MovimientoTipo tipo;
  final List<Movimiento> movimientos;
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
        final Categoria? actual = _buscar(lista);
        final ThemeData theme = Theme.of(context);
        final SaveUpColors colors = theme.extension<SaveUpColors>()!;
        return InkWell(
          onTap: () => _elegir(context, lista),
          borderRadius: AppRadii.mdAll,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Categoría',
              prefixIcon: actual == null
                  ? const Icon(Icons.category_outlined)
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: IconoCategoria(categoria: actual, size: 28),
                    ),
              suffixIcon: const Icon(Icons.expand_more),
              errorText: errorText,
            ),
            child: Text(
              actual?.nombre ?? 'Elegir categoría',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: actual == null ? colors.muted : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Categoria? _buscar(List<Categoria> lista) {
    for (final Categoria categoria in lista) {
      if (categoria.id == seleccionada) {
        return categoria;
      }
    }
    return null;
  }

  Future<void> _elegir(BuildContext context, List<Categoria> lista) async {
    final int? id = await CategoriaPicker.show(
      context,
      categorias: lista,
      tipo: tipo,
      movimientos: movimientos,
      seleccionada: seleccionada,
    );
    if (id != null) {
      onChanged(id);
    }
  }
}
