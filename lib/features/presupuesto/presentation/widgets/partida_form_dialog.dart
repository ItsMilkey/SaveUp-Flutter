import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/money/money.dart';
import '../../../movimientos/domain/categoria.dart';
import '../../../movimientos/domain/sugerencia_categoria.dart';
import '../../../movimientos/presentation/categoria_sugerencia_controller.dart';
import '../../domain/plan_mensual.dart';
import '../controllers/grupos_plan_controller.dart';
import '../controllers/plan_mensual_controller.dart';

/// Alta o edición de una partida del plan.
///
/// Alta: nombre, categoría (con sugeridor de F3: debounce 400 ms, eco de texto
/// y confirmación si es ambigua), monto y grupo opcional.
/// Edición: nombre, categoría y grupo. Si la partida está vinculada a una deuda
/// (`deudaId`), categoría y monto quedan bloqueados (el monto lo define la
/// cuota); solo se ajusta el grupo.
class PartidaFormDialog extends ConsumerStatefulWidget {
  const PartidaFormDialog({super.key, required this.mes, this.partida});

  final String mes;
  final PartidaPlan? partida;

  bool get esEdicion => partida != null;

  static Future<bool?> show(
    BuildContext context, {
    required String mes,
    PartidaPlan? partida,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => PartidaFormDialog(mes: mes, partida: partida),
    );
  }

  @override
  ConsumerState<PartidaFormDialog> createState() => _PartidaFormDialogState();
}

class _PartidaFormDialogState extends ConsumerState<PartidaFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _monto = TextEditingController();

  int? _categoriaId;
  int? _grupoId;
  bool _seleccionManual = false;
  List<SugerenciaCategoria> _sugerencias = const <SugerenciaCategoria>[];
  bool _ambigua = false;
  bool _guardando = false;
  String? _error;

  bool get _vinculada => widget.partida?.vinculadaADeuda ?? false;

  @override
  void initState() {
    super.initState();
    final PartidaPlan? partida = widget.partida;
    if (partida != null) {
      _nombre.text = partida.nombre;
      _categoriaId = partida.categoriaId;
      _grupoId = partida.grupoId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(sugerenciaCategoriaProvider.notifier).limpiar();
      }
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _monto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        if (!respuesta.ambigua &&
            respuesta.sugerencias.isNotEmpty &&
            !_seleccionManual &&
            !widget.esEdicion) {
          _categoriaId = respuesta.sugerencias.first.categoriaId;
        }
      });
    });

    final AsyncValue<List<Categoria>> categorias = ref.watch(
      categoriasProvider,
    );
    final AsyncValue<List<GrupoPlan>> grupos = ref.watch(gruposPlanProvider);

    return AlertDialog(
      title: Text(widget.esEdicion ? 'Editar partida' : 'Nueva partida'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                TextFormField(
                  controller: _nombre,
                  autofocus: !widget.esEdicion,
                  maxLength: 80,
                  onChanged: (_) {
                    if (!widget.esEdicion) {
                      ref
                          .read(sugerenciaCategoriaProvider.notifier)
                          .actualizarTexto(
                            _nombre.text,
                            contexto: ContextoSugerencia.gasto,
                          );
                    }
                  },
                  validator: (String? value) {
                    final String text = value?.trim() ?? '';
                    if (text.isEmpty || text.length > 80) {
                      return 'Entre 1 y 80 caracteres.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 8),
                if (_vinculada)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    child: Text(
                      '${widget.partida!.categoriaCodigo} · fijada por la '
                      'deuda',
                    ),
                  )
                else
                  _selectorCategoria(categorias),
                if (!_vinculada && _sugerencias.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    _ambigua
                        ? 'Hay más de una categoría posible: elige la correcta.'
                        : 'Sugerencias (puedes cambiarla):',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      for (final SugerenciaCategoria s in _sugerencias)
                        ChoiceChip(
                          label: Text(s.nombre),
                          selected: _categoriaId == s.categoriaId,
                          onSelected: (_) => setState(() {
                            _categoriaId = s.categoriaId;
                            _seleccionManual = true;
                          }),
                        ),
                    ],
                  ),
                ],
                if (!widget.esEdicion) ...<Widget>[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _monto,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (String? value) {
                      final String text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Ingresa el monto planificado.';
                      }
                      try {
                        if (Money.parseUserInput(text) < Decimal.zero) {
                          return 'No puede ser negativo.';
                        }
                      } on FormatException {
                        return 'Monto inválido.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Monto planificado',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                grupos.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (Object error, StackTrace stack) => Text(
                    'No se pudieron cargar los grupos.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  data: (List<GrupoPlan> lista) => DropdownButtonFormField<int?>(
                    initialValue: _grupoId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Grupo (opcional)',
                      prefixIcon: Icon(Icons.folder_outlined),
                    ),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin grupo'),
                      ),
                      for (final GrupoPlan grupo in lista)
                        DropdownMenuItem<int?>(
                          value: grupo.id,
                          child: Text(grupo.nombre),
                        ),
                    ],
                    onChanged: (int? id) => setState(() => _grupoId = id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _selectorCategoria(AsyncValue<List<Categoria>> categorias) {
    return categorias.when(
      loading: () => const LinearProgressIndicator(),
      error: (Object error, StackTrace stack) => Row(
        children: <Widget>[
          const Expanded(child: Text('No se pudo cargar el catálogo.')),
          TextButton(
            onPressed: () => ref.invalidate(categoriasProvider),
            child: const Text('Reintentar'),
          ),
        ],
      ),
      data: (List<Categoria> lista) {
        final bool existe = lista.any((Categoria c) => c.id == _categoriaId);
        return DropdownButtonFormField<int>(
          key: ValueKey<int?>(_categoriaId),
          initialValue: existe ? _categoriaId : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: <DropdownMenuItem<int>>[
            for (final Categoria categoria in lista)
              DropdownMenuItem<int>(
                value: categoria.id,
                child: Text(categoria.nombre),
              ),
          ],
          validator: (int? value) =>
              value == null ? 'Elige una categoría.' : null,
          onChanged: (int? id) => setState(() {
            _categoriaId = id;
            _seleccionManual = true;
          }),
        );
      },
    );
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final PlanMensualController controller = ref.read(
      planMensualProvider.notifier,
    );

    final AppFailure? failure;
    if (widget.esEdicion) {
      final PartidaPlan original = widget.partida!;
      final bool quitarGrupo = _grupoId == null && original.grupoId != null;
      failure = await controller.editarPartida(
        original.id,
        nombre: _nombre.text.trim(),
        categoriaId: _vinculada ? null : _categoriaId,
        grupoId: _grupoId,
        quitarGrupo: quitarGrupo,
      );
    } else {
      failure = await controller.crearPartida(
        nombre: _nombre.text.trim(),
        categoriaId: _categoriaId!,
        montoPlanificado: Money.parseUserInput(_monto.text),
        grupoId: _grupoId,
      );
    }
    if (!mounted) {
      return;
    }
    if (failure != null) {
      final AppFailure fallo = failure;
      setState(() {
        _guardando = false;
        _error = failureMessage(fallo);
      });
      return;
    }
    Navigator.of(context).pop(true);
  }
}
