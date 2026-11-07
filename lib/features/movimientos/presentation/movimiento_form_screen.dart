import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/money/money.dart';
import '../domain/categoria.dart';
import '../domain/movimiento.dart';
import '../domain/movimiento_tipo.dart';
import '../domain/sugerencia_categoria.dart';
import 'categoria_sugerencia_controller.dart';
import 'movimiento_labels.dart';
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
      _montoController.text = inicial.monto.abs().toString();
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
                    setState(() => _tipo = tipo);
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
                error: errorFor('monto'),
              ),
              const SizedBox(height: AppSpacing.md),
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
