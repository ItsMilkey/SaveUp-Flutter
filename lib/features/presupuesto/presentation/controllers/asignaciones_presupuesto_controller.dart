import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../metas/data/dio_metas_repository.dart';
import '../../../metas/domain/meta_ahorro.dart';
import '../../data/dio_presupuesto_repository.dart';
import '../../domain/asignacion_presupuesto.dart';
import '../../domain/presupuesto_repository.dart';

/// Estado editable del reparto de ahorro entre metas.
class AsignacionesPresupuestoState {
  const AsignacionesPresupuestoState({
    this.cargando = false,
    this.cargadas = false,
    this.metas = const <MetaAhorro>[],
    this.valores = const <int, Decimal>{},
    this.errorCarga,
    this.mensajeValidacion,
  });

  final bool cargando;

  /// `true` solo si el `GET` de asignaciones y las metas cargaron.
  ///
  /// Si es `false` la sección no se muestra y el guardado omite
  /// `asignaciones` para no borrar lo que no se pudo leer.
  final bool cargadas;
  final List<MetaAhorro> metas;

  /// `metaId` → porcentaje (escala 2). Vacío = sin distribución.
  final Map<int, Decimal> valores;
  final AppFailure? errorCarga;
  final String? mensajeValidacion;

  Decimal get total => valores.values.fold(
    Decimal.zero,
    (Decimal suma, Decimal valor) => suma + valor,
  );

  bool get valido =>
      valores.isEmpty || total.compareTo(Decimal.fromInt(100)) == 0;

  List<MetaAhorro> get disponibles => <MetaAhorro>[
    for (final MetaAhorro meta in metas)
      if (!valores.containsKey(meta.id)) meta,
  ];

  String nombreDe(int metaId) {
    for (final MetaAhorro meta in metas) {
      if (meta.id == metaId) {
        return meta.nombre;
      }
    }
    return 'Meta $metaId';
  }

  /// Conjunto completo que viaja en `POST /presupuestos/me`.
  List<AsignacionPresupuestoDatos> get datos {
    final List<int> ids = valores.keys.toList()..sort();
    return <AsignacionPresupuestoDatos>[
      for (final int id in ids)
        AsignacionPresupuestoDatos(metaId: id, porcentaje: valores[id]!),
    ];
  }

  AsignacionesPresupuestoState copyWith({
    bool? cargando,
    bool? cargadas,
    List<MetaAhorro>? metas,
    Map<int, Decimal>? valores,
    AppFailure? errorCarga,
    bool limpiarError = false,
    String? mensajeValidacion,
  }) {
    return AsignacionesPresupuestoState(
      cargando: cargando ?? this.cargando,
      cargadas: cargadas ?? this.cargadas,
      metas: metas ?? this.metas,
      valores: valores ?? this.valores,
      errorCarga: limpiarError ? null : (errorCarga ?? this.errorCarga),
      mensajeValidacion: mensajeValidacion ?? this.mensajeValidacion,
    );
  }
}

final NotifierProvider<
  AsignacionesPresupuestoController,
  AsignacionesPresupuestoState
>
asignacionesPresupuestoProvider =
    NotifierProvider<
      AsignacionesPresupuestoController,
      AsignacionesPresupuestoState
    >(AsignacionesPresupuestoController.new);

/// Carga metas + asignaciones y mantiene el reparto sumando 100.00 exacto.
class AsignacionesPresupuestoController
    extends Notifier<AsignacionesPresupuestoState> {
  static final Decimal _cien = Decimal.fromInt(100);
  static final Decimal _uno = Decimal.one;

  @override
  AsignacionesPresupuestoState build() => const AsignacionesPresupuestoState();

  Future<void> cargar() async {
    state = const AsignacionesPresupuestoState(cargando: true);
    try {
      final PresupuestoRepository presupuesto = ref.read(
        presupuestoRepositoryProvider,
      );
      final List<AsignacionPresupuesto> asignaciones = await presupuesto
          .listarAsignaciones();
      final List<MetaAhorro> metas = await ref
          .read(metasRepositoryProvider)
          .listar();
      final Map<int, Decimal> valores = <int, Decimal>{
        for (final AsignacionPresupuesto item in asignaciones)
          if (item.porcentaje > Decimal.zero) item.metaId: item.porcentaje,
      };
      state = AsignacionesPresupuestoState(
        cargadas: true,
        metas: metas,
        valores: valores,
      );
    } on AppFailure catch (failure) {
      state = AsignacionesPresupuestoState(errorCarga: failure);
    }
  }

  /// Agrega una meta y reparte el 100 % en partes iguales entre las elegidas.
  void agregar(int metaId) {
    if (!state.cargadas || state.valores.containsKey(metaId)) {
      return;
    }
    final List<int> ids = <int>[...state.valores.keys, metaId];
    state = state.copyWith(
      valores: _repartirIgual(ids),
      mensajeValidacion: null,
    );
  }

  void quitar(int metaId) {
    if (!state.valores.containsKey(metaId)) {
      return;
    }
    final Map<int, Decimal> restantes = <int, Decimal>{...state.valores}
      ..remove(metaId);
    if (restantes.isEmpty) {
      state = state.copyWith(
        valores: const <int, Decimal>{},
        mensajeValidacion: null,
      );
      return;
    }
    state = state.copyWith(
      valores: _repartirProporcional(restantes, _cien),
      mensajeValidacion: null,
    );
  }

  /// Mueve un porcentaje y reparte el resto proporcionalmente entre los demás.
  void setPorcentaje(int metaId, Decimal valor) {
    if (!state.valores.containsKey(metaId)) {
      return;
    }
    final int cantidad = state.valores.length;
    if (cantidad == 1) {
      state = state.copyWith(
        valores: <int, Decimal>{metaId: _cien},
        mensajeValidacion: null,
      );
      return;
    }
    final Decimal maximo = _cien - Decimal.fromInt(cantidad - 1);
    Decimal movido = valor;
    if (movido < _uno) {
      movido = _uno;
    }
    if (movido > maximo) {
      movido = maximo;
    }
    movido = movido.round(scale: 2);

    final Map<int, Decimal> otros = <int, Decimal>{...state.valores}
      ..remove(metaId);
    final Map<int, Decimal> nuevos = <int, Decimal>{
      metaId: movido,
      ..._repartirProporcional(otros, _cien - movido),
    };
    state = state.copyWith(valores: nuevos, mensajeValidacion: null);
  }

  /// Deja el reparto vacío (`[]` al guardar): el ahorro queda en la meta base.
  void limpiar() {
    state = state.copyWith(
      valores: const <int, Decimal>{},
      mensajeValidacion: null,
    );
  }

  /// Valida antes de guardar; devuelve el mensaje si no puede guardarse.
  String? validar() {
    if (!state.cargadas || state.valores.isEmpty) {
      return null;
    }
    if (state.valores.values.any((Decimal valor) => valor <= Decimal.zero)) {
      return 'Cada meta debe tener un porcentaje mayor a 0.';
    }
    if (!state.valido) {
      return 'Las asignaciones deben sumar 100.00.';
    }
    return null;
  }

  Map<int, Decimal> _repartirIgual(List<int> ids) {
    final int n = ids.length;
    final Decimal base = (Decimal.fromInt(100) / Decimal.fromInt(n))
        .toDecimal(scaleOnInfinitePrecision: 6)
        .round(scale: 2);
    final Map<int, Decimal> resultado = <int, Decimal>{};
    Decimal acumulado = Decimal.zero;
    for (int i = 0; i < n; i++) {
      final Decimal valor = i == n - 1 ? _cien - acumulado : base;
      resultado[ids[i]] = valor;
      acumulado += valor;
    }
    return resultado;
  }

  Map<int, Decimal> _repartirProporcional(
    Map<int, Decimal> actuales,
    Decimal total,
  ) {
    final List<int> ids = actuales.keys.toList();
    if (ids.isEmpty) {
      return const <int, Decimal>{};
    }
    final Decimal pesos = actuales.values.fold(
      Decimal.zero,
      (Decimal suma, Decimal valor) => suma + valor,
    );
    final Map<int, Decimal> resultado = <int, Decimal>{};
    Decimal acumulado = Decimal.zero;
    for (int i = 0; i < ids.length; i++) {
      final Decimal valor;
      if (i == ids.length - 1) {
        valor = total - acumulado;
      } else if (pesos <= Decimal.zero) {
        valor = (total / Decimal.fromInt(ids.length))
            .toDecimal(scaleOnInfinitePrecision: 6)
            .round(scale: 2);
      } else {
        valor = (total * actuales[ids[i]]! / pesos)
            .toDecimal(scaleOnInfinitePrecision: 6)
            .round(scale: 2);
      }
      resultado[ids[i]] = valor;
      acumulado += valor;
    }
    return resultado;
  }
}
