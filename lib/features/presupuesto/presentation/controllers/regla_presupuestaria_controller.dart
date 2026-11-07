import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/dio_presupuesto_repository.dart';
import '../../domain/presupuesto_repository.dart';
import '../../domain/regla_presupuestaria.dart';

/// Estado editable de la regla presupuestaria.
class ReglaPresupuestariaState {
  ReglaPresupuestariaState({
    this.cargando = false,
    this.config,
    this.sugerencia,
    Decimal? necesidades,
    Decimal? deseos,
    Decimal? ahorro,
    this.activo = true,
    this.automatizarAhorroEnMetas = false,
    this.guardando = false,
    this.guardado = false,
    this.errorCarga,
    this.error,
    this.mensajeValidacion,
  }) : necesidades = necesidades ?? _cincuenta,
       deseos = deseos ?? _treinta,
       ahorro = ahorro ?? _veinte;

  static final Decimal _cincuenta = Decimal.fromInt(50);
  static final Decimal _treinta = Decimal.fromInt(30);
  static final Decimal _veinte = Decimal.fromInt(20);

  final bool cargando;
  final ConfiguracionPresupuesto? config;
  final SugerenciaRegla? sugerencia;

  final Decimal necesidades;
  final Decimal deseos;
  final Decimal ahorro;
  final bool activo;
  final bool automatizarAhorroEnMetas;

  final bool guardando;
  final bool guardado;
  final AppFailure? errorCarga;
  final AppFailure? error;

  /// Mensaje local cuando la suma no es 100.00 (no debería ocurrir con el
  /// autobalanceo, pero protege envíos manuales).
  final String? mensajeValidacion;

  Decimal get suma => necesidades + deseos + ahorro;
  bool get sumaValida => suma.compareTo(Decimal.fromInt(100)) == 0;

  ReglaPresupuestariaState copyWith({
    bool? cargando,
    ConfiguracionPresupuesto? config,
    SugerenciaRegla? sugerencia,
    Decimal? necesidades,
    Decimal? deseos,
    Decimal? ahorro,
    bool? activo,
    bool? automatizarAhorroEnMetas,
    bool? guardando,
    bool? guardado,
    AppFailure? errorCarga,
    bool limpiarErrorCarga = false,
    AppFailure? error,
    bool limpiarError = false,
    String? mensajeValidacion,
    bool limpiarValidacion = false,
  }) {
    return ReglaPresupuestariaState(
      cargando: cargando ?? this.cargando,
      config: config ?? this.config,
      sugerencia: sugerencia ?? this.sugerencia,
      necesidades: necesidades ?? this.necesidades,
      deseos: deseos ?? this.deseos,
      ahorro: ahorro ?? this.ahorro,
      activo: activo ?? this.activo,
      automatizarAhorroEnMetas:
          automatizarAhorroEnMetas ?? this.automatizarAhorroEnMetas,
      guardando: guardando ?? this.guardando,
      guardado: guardado ?? this.guardado,
      errorCarga: limpiarErrorCarga ? null : (errorCarga ?? this.errorCarga),
      error: limpiarError ? null : (error ?? this.error),
      mensajeValidacion: limpiarValidacion
          ? null
          : (mensajeValidacion ?? this.mensajeValidacion),
    );
  }
}

final NotifierProvider<ReglaPresupuestariaController, ReglaPresupuestariaState>
reglaPresupuestariaProvider =
    NotifierProvider<ReglaPresupuestariaController, ReglaPresupuestariaState>(
      ReglaPresupuestariaController.new,
    );

/// Controla la regla 50/30/20 con autobalanceo a 100.00 exacto.
///
/// No usa `double`: los porcentajes son `Decimal` con escala 2; el `double`
/// solo existe en la posición visual del slider.
class ReglaPresupuestariaController
    extends Notifier<ReglaPresupuestariaState> {
  static final Decimal _cien = Decimal.fromInt(100);
  static final Decimal _cero = Decimal.zero;

  @override
  ReglaPresupuestariaState build() => ReglaPresupuestariaState();

  /// Carga configuración y sugerencia en paralelo.
  ///
  /// Sin configuración el backend responde `404 NO_ENCONTRADO`: se arranca con
  /// la sugerencia (o 50/30/20) y no se trata como error.
  Future<void> cargar() async {
    state = ReglaPresupuestariaState(cargando: true);
    final PresupuestoRepository repository = ref.read(
      presupuestoRepositoryProvider,
    );

    ConfiguracionPresupuesto? config;
    AppFailure? errorCarga;
    try {
      config = await repository.obtenerConfiguracion();
    } on NotFoundFailure {
      config = null;
    } on AppFailure catch (failure) {
      errorCarga = failure;
    }

    SugerenciaRegla? sugerencia;
    try {
      sugerencia = await repository.sugerenciaRegla();
    } on AppFailure {
      sugerencia = null;
    }

    if (errorCarga != null) {
      state = ReglaPresupuestariaState(
        sugerencia: sugerencia,
        errorCarga: errorCarga,
      );
      return;
    }

    final PorcentajesRegla inicial =
        config?.porcentajes ??
        sugerencia?.sugerencia ??
        sugerencia?.actual ??
        PorcentajesRegla(
          necesidades: Decimal.fromInt(50),
          deseos: Decimal.fromInt(30),
          ahorro: Decimal.fromInt(20),
        );

    state = ReglaPresupuestariaState(
      config: config,
      sugerencia: sugerencia,
      necesidades: inicial.necesidades,
      deseos: inicial.deseos,
      ahorro: inicial.ahorro,
      activo: config?.activo ?? true,
      automatizarAhorroEnMetas: config?.automatizarAhorroEnMetas ?? false,
    );
  }

  void setNecesidades(Decimal valor) =>
      _ajustar(necesidades: valor);

  void setDeseos(Decimal valor) => _ajustar(deseos: valor);

  void setAhorro(Decimal valor) => _ajustar(ahorro: valor);

  /// Aplica el porcentaje movido y reparte el resto de forma proporcional entre
  /// los otros dos, garantizando suma 100.00 (redondeo HALF_UP y ajuste final).
  void _ajustar({Decimal? necesidades, Decimal? deseos, Decimal? ahorro}) {
    final Decimal movido = _clamp(
      necesidades ?? deseos ?? ahorro ?? _cero,
    );
    final Decimal resto = _cien - movido;
    final Decimal actuales;
    final bool mueveNecesidades = necesidades != null;
    final bool mueveDeseos = deseos != null;

    if (mueveNecesidades) {
      actuales = state.deseos + state.ahorro;
    } else if (mueveDeseos) {
      actuales = state.necesidades + state.ahorro;
    } else {
      actuales = state.necesidades + state.deseos;
    }

    Decimal primero;
    Decimal segundo;
    if (actuales == _cero) {
      primero = resto;
      segundo = _cero;
    } else if (mueveNecesidades) {
      primero = _proporcional(resto, state.deseos, actuales);
      segundo = resto - primero;
    } else if (mueveDeseos) {
      primero = _proporcional(resto, state.necesidades, actuales);
      segundo = resto - primero;
    } else {
      primero = _proporcional(resto, state.necesidades, actuales);
      segundo = resto - primero;
    }

    Decimal n = state.necesidades;
    Decimal d = state.deseos;
    Decimal a = state.ahorro;
    if (mueveNecesidades) {
      n = movido;
      d = primero;
      a = segundo;
    } else if (mueveDeseos) {
      d = movido;
      n = primero;
      a = segundo;
    } else {
      a = movido;
      n = primero;
      d = segundo;
    }

    state = state.copyWith(
      necesidades: n,
      deseos: d,
      ahorro: a,
      guardado: false,
      limpiarValidacion: true,
      limpiarError: true,
    );
  }

  Decimal _proporcional(Decimal resto, Decimal parte, Decimal total) {
    if (total == _cero) {
      return _cero;
    }
    final BigInt r = (resto * _cien).toBigInt();
    final BigInt p = (parte * _cien).toBigInt();
    final BigInt t = (total * _cien).toBigInt();
    final BigInt q = (r * p * BigInt.two + t) ~/ (t * BigInt.two);
    return Decimal.fromBigInt(q).shift(-2);
  }

  Decimal _clamp(Decimal valor) {
    if (valor < _cero) {
      return _cero;
    }
    if (valor > _cien) {
      return _cien;
    }
    return valor.round(scale: 2);
  }

  void setActivo(bool activo) {
    state = state.copyWith(activo: activo, guardado: false);
  }

  void setAutomatizarAhorroEnMetas(bool valor) {
    state = state.copyWith(
      automatizarAhorroEnMetas: valor,
      guardado: false,
    );
  }

  /// Copia la sugerencia del servidor si existe.
  void aplicarSugerencia() {
    final SugerenciaRegla? sugerencia = state.sugerencia;
    if (sugerencia?.sugerencia == null) {
      return;
    }
    final PorcentajesRegla p = sugerencia!.sugerencia!;
    state = state.copyWith(
      necesidades: p.necesidades,
      deseos: p.deseos,
      ahorro: p.ahorro,
      guardado: false,
      limpiarValidacion: true,
    );
  }

  Future<void> guardar() async {
    if (!state.sumaValida) {
      state = state.copyWith(
        mensajeValidacion: 'Los porcentajes deben sumar 100.00.',
      );
      return;
    }
    if (state.guardando) {
      return;
    }
    state = state.copyWith(
      guardando: true,
      guardado: false,
      limpiarError: true,
      limpiarValidacion: true,
    );
    try {
      final ConfiguracionPresupuesto config = await ref
          .read(presupuestoRepositoryProvider)
          .guardarConfiguracion(
            porcentajes: PorcentajesRegla(
              necesidades: state.necesidades,
              deseos: state.deseos,
              ahorro: state.ahorro,
            ),
            activo: state.activo,
            automatizarAhorroEnMetas: state.automatizarAhorroEnMetas,
          );
      state = state.copyWith(config: config, guardando: false, guardado: true);
    } on AppFailure catch (failure) {
      state = state.copyWith(guardando: false, error: failure);
    }
  }

  /// Limpia la marca de "guardado" después de mostrar el aviso.
  void limpiarGuardado() {
    if (state.guardado) {
      state = state.copyWith(guardado: false);
    }
  }
}
