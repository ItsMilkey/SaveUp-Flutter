/// DTOs del plan mensual (lectura y lote de montos).
library;

import 'package:decimal/decimal.dart';

import '../../../core/money/money_json.dart';
import '../../../core/time/instants.dart';
import '../domain/plan_calculo.dart';
import '../domain/plan_mensual.dart';

Decimal _money(Map<String, dynamic> json, String key) =>
    moneyFromJson(json[key]);

Decimal? _moneyOpt(Map<String, dynamic> json, String key) =>
    json[key] == null ? null : moneyFromJson(json[key]);

int _int(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! int) {
    throw FormatException('Se esperaba un entero en "$key".');
  }
  return value;
}

int? _intOpt(Map<String, dynamic> json, String key) => json[key] as int?;

String _string(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! String) {
    throw FormatException('Se esperaba un texto en "$key".');
  }
  return value;
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) {
    throw const FormatException('Se esperaba un objeto JSON.');
  }
  return value.map((Object? k, Object? v) => MapEntry(k.toString(), v));
}

/// `PlanMensualResponseDTO` → dominio.
class PlanMensualDto {
  const PlanMensualDto._();

  static PlanMensual fromJson(Map<String, dynamic> json) {
    final String mes = _string(json, 'mes');
    final bool existe = json['existe'] == true;
    final Decimal? ingresoReferencia = _moneyOpt(json, 'ingresoReferencia');
    final Map<String, dynamic> resumen = _map(json['resumen']);

    final Map<int, TipoPresupuesto> tiposPorCategoria =
        <int, TipoPresupuesto>{};
    final List<CategoriaResultado> porCategoria = <CategoriaResultado>[
      for (final Object? raw in (json['porCategoria'] as List?) ?? const <dynamic>[])
        _categoria(_map(raw), tiposPorCategoria),
    ];
    porCategoria.sort(
      (CategoriaResultado a, CategoriaResultado b) =>
          a.categoriaId.compareTo(b.categoriaId),
    );

    final List<PartidaPlan> partidas = <PartidaPlan>[];
    final List<PartidaResultado> partidasCalculadas = <PartidaResultado>[];
    for (final Object? raw
        in (json['partidas'] as List?) ?? const <dynamic>[]) {
      final Map<String, dynamic> p = _map(raw);
      final int categoriaId = _int(p, 'categoriaId');
      final String categoriaCodigo = _string(p, 'categoriaCodigo');
      final Decimal monto = _money(p, 'montoPlanificado');
      final Decimal real = _money(p, 'real');
      final Decimal diferencia = _money(p, 'diferencia');
      final Decimal? porcentaje = _moneyOpt(p, 'porcentajeUsado');
      final EstadoEjecucion estado = EstadoEjecucion.parse(
        _string(p, 'estado'),
      );
      final EstadoCuota? estadoCuota = p['estadoCuota'] == null
          ? null
          : EstadoCuota.parse(p['estadoCuota'] as String);
      final TipoPresupuesto tipo =
          tiposPorCategoria[categoriaId] ?? TipoPresupuesto.otros;

      partidasCalculadas.add(
        PartidaResultado(
          id: _int(p, 'id'),
          nombre: _string(p, 'nombre'),
          real: real,
          diferencia: diferencia,
          porcentajeUsado: porcentaje,
          estado: estado,
          estadoCuota: estadoCuota,
          montoPlanificado: monto,
          categoria: CategoriaRef(
            id: categoriaId,
            codigo: categoriaCodigo,
            tipo: tipo,
          ),
          grupoId: _intOpt(p, 'grupoId'),
          deudaId: _intOpt(p, 'deudaId'),
        ),
      );
      partidas.add(
        PartidaPlan(
          id: _int(p, 'id'),
          nombre: _string(p, 'nombre'),
          categoriaId: categoriaId,
          categoriaCodigo: categoriaCodigo,
          montoPlanificado: monto,
          real: real,
          diferencia: diferencia,
          porcentajeUsado: porcentaje,
          estado: estado,
          estadoCuota: estadoCuota,
          grupoId: _intOpt(p, 'grupoId'),
          deudaId: _intOpt(p, 'deudaId'),
          deudaNombre: p['deudaNombre'] as String?,
          vinculoDesactualizado: p['vinculoDesactualizado'] == true,
          orden: _int(p, 'orden'),
          actualizadoEn: parseInstant(_string(p, 'actualizadoEn')),
        ),
      );
    }

    final List<RepartoTipoResultado> reparto = <RepartoTipoResultado>[
      for (final Object? raw
          in (json['repartoPorTipo'] as List?) ?? const <dynamic>[])
        _reparto(_map(raw)),
    ];

    final List<GrupoResultado> grupos = <GrupoResultado>[
      for (final Object? raw in (json['grupos'] as List?) ?? const <dynamic>[])
        _grupo(_map(raw)),
    ];

    final List<AvisoPlan> avisos = <AvisoPlan>[
      for (final Object? raw in (json['avisos'] as List?) ?? const <dynamic>[])
        _aviso(_map(raw)),
    ];

    final Map<String, dynamic>? guiaJson = json['guia'] == null
        ? null
        : _map(json['guia']);

    final PlanCalculado calculo = PlanCalculado(
      resumen: _resumen(resumen),
      partidas: partidasCalculadas,
      porCategoria: porCategoria,
      repartoPorTipo: reparto,
      guia: guiaJson == null
          ? null
          : GuiaCalculo(
              necesidades: _money(guiaJson, 'necesidades'),
              deseos: _money(guiaJson, 'deseos'),
              ahorro: _money(guiaJson, 'ahorro'),
            ),
      grupos: grupos,
    );

    return PlanMensual(
      mes: mes,
      existe: existe,
      ingresoReferencia: ingresoReferencia,
      calculo: calculo,
      partidas: partidas,
      grupos: grupos,
      avisos: avisos,
    );
  }

  static CategoriaResultado _categoria(
    Map<String, dynamic> json,
    Map<int, TipoPresupuesto> tipos,
  ) {
    final int id = _int(json, 'categoriaId');
    final TipoPresupuesto tipo = json['tipo'] == null
        ? TipoPresupuesto.otros
        : TipoPresupuesto.parse(json['tipo'] as String);
    tipos[id] = tipo;
    final Map<String, dynamic>? referenciaJson = json['referencia'] == null
        ? null
        : _map(json['referencia']);
    return CategoriaResultado(
      categoriaId: id,
      codigo: _string(json, 'codigo'),
      tipo: tipo,
      planificado: _money(json, 'planificado'),
      real: _money(json, 'real'),
      diferencia: _money(json, 'diferencia'),
      porcentajeUsado: _moneyOpt(json, 'porcentajeUsado'),
      estado: EstadoEjecucion.parse(_string(json, 'estado')),
      referencia: referenciaJson == null
          ? null
          : ReferenciaCategoria(
              mesAnterior: _moneyOpt(referenciaJson, 'mesAnterior'),
              promedio3Meses: _moneyOpt(referenciaJson, 'promedio3Meses'),
            ),
    );
  }

  static ResumenCalculado _resumen(Map<String, dynamic> json) {
    final Map<String, dynamic> sinPlanificar = _map(json['sinPlanificar']);
    return ResumenCalculado(
      planificadoTotal: _money(json, 'planificadoTotal'),
      remanenteLibre: _moneyOpt(json, 'remanenteLibre'),
      margenSeguridadPct: _moneyOpt(json, 'margenSeguridadPct'),
      excedeIngreso: json['excedeIngreso'] == true,
      ingresoReal: _money(json, 'ingresoReal'),
      gastoRealTotal: _money(json, 'gastoRealTotal'),
      disponibleReal: _money(json, 'disponibleReal'),
      ahorroRegistrado: _money(json, 'ahorroRegistrado'),
      sinPlanificar: SinPlanificarCalculado(
        monto: _money(sinPlanificar, 'monto'),
        movimientos: _int(sinPlanificar, 'movimientos'),
        porMotivo: <MotivoCalculado>[
          for (final Object? raw
              in (sinPlanificar['porMotivo'] as List?) ?? const <dynamic>[])
            MotivoCalculado(
              motivo: MotivoSinPlanificar.parse(
                _string(_map(raw), 'motivo'),
              ),
              monto: _money(_map(raw), 'monto'),
              movimientos: _int(_map(raw), 'movimientos'),
            ),
        ],
      ),
    );
  }

  static RepartoTipoResultado _reparto(Map<String, dynamic> json) {
    return RepartoTipoResultado(
      tipo: TipoPresupuesto.parse(_string(json, 'tipo')),
      planificado: _money(json, 'planificado'),
      porcentajeDelIngreso: _moneyOpt(json, 'porcentajeDelIngreso'),
      real: _money(json, 'real'),
      porcentajeRealDelIngresoReal: _moneyOpt(
        json,
        'porcentajeRealDelIngresoReal',
      ),
      diferenciaPuntos: _moneyOpt(json, 'diferenciaPuntos'),
    );
  }

  static GrupoResultado _grupo(Map<String, dynamic> json) {
    return GrupoResultado(
      id: _intOpt(json, 'id'),
      nombre: _string(json, 'nombre'),
      orden: _intOpt(json, 'orden'),
      planificado: _money(json, 'planificado'),
      porcentajeDelPlanificado: _moneyOpt(json, 'porcentajeDelPlanificado'),
      real: _money(json, 'real'),
      partidaIds: <int>[
        for (final Object? id
            in (json['partidaIds'] as List?) ?? const <dynamic>[])
          id as int,
      ],
    );
  }

  static AvisoPlan _aviso(Map<String, dynamic> json) {
    return AvisoPlan(
      motivo: _string(json, 'motivo'),
      partidaId: _intOpt(json, 'partidaId'),
      nombre: json['nombre'] as String?,
      deudaId: _intOpt(json, 'deudaId'),
      mensaje: json['mensaje'] as String?,
    );
  }
}

/// Cuerpo de `PATCH /planes/{mes}/montos`.
class CambiosMontosDto {
  const CambiosMontosDto({required this.cambios});

  final List<CambioMonto> cambios;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'cambios': <Map<String, Object?>>[
        for (final CambioMonto cambio in cambios)
          <String, Object?>{
            'partidaId': cambio.partidaId,
            'monto': moneyToJson(cambio.monto),
          },
      ],
    };
  }
}

/// `GrupoPlanDTO`.
class GrupoPlanDto {
  const GrupoPlanDto._();

  static GrupoPlan fromJson(Map<String, dynamic> json) {
    return GrupoPlan(
      id: _int(json, 'id'),
      nombre: _string(json, 'nombre'),
      orden: _int(json, 'orden'),
    );
  }
}

/// Cuerpo de `POST /planes/grupos`.
class GrupoPlanCreacionDto {
  const GrupoPlanCreacionDto({required this.nombre, this.orden});

  final String nombre;
  final int? orden;

  Map<String, Object?> toJson() => <String, Object?>{
    'nombre': nombre,
    if (orden != null) 'orden': orden,
  };
}

/// Cuerpo de `PUT /planes/grupos/{id}` (parcial).
class GrupoPlanEdicionDto {
  const GrupoPlanEdicionDto({this.nombre, this.orden});

  final String? nombre;
  final int? orden;

  Map<String, Object?> toJson() => <String, Object?>{
    if (nombre != null) 'nombre': nombre,
    if (orden != null) 'orden': orden,
  };
}

/// Cuerpo de `POST /planes/{mes}/partidas`.
class PartidaCreacionDto {
  const PartidaCreacionDto({
    required this.nombre,
    this.categoriaId,
    this.montoPlanificado,
    this.grupoId,
    this.deudaId,
  });

  final String nombre;
  final int? categoriaId;
  final Decimal? montoPlanificado;
  final int? grupoId;
  final int? deudaId;

  Map<String, Object?> toJson() => <String, Object?>{
    'nombre': nombre,
    if (categoriaId != null) 'categoriaId': categoriaId,
    if (montoPlanificado != null)
      'montoPlanificado': moneyToJson(montoPlanificado!),
    if (grupoId != null) 'grupoId': grupoId,
    if (deudaId != null) 'deudaId': deudaId,
  };
}

/// Cuerpo de `PUT /planes/{mes}/partidas/{id}` (parcial).
class PartidaEdicionDto {
  const PartidaEdicionDto({
    this.nombre,
    this.categoriaId,
    this.grupoId,
    this.quitarGrupo = false,
  });

  final String? nombre;
  final int? categoriaId;
  final int? grupoId;
  final bool quitarGrupo;

  Map<String, Object?> toJson() => <String, Object?>{
    if (nombre != null) 'nombre': nombre,
    if (categoriaId != null) 'categoriaId': categoriaId,
    if (grupoId != null) 'grupoId': grupoId,
    if (quitarGrupo) 'quitarGrupo': true,
  };
}

/// Cuerpo de `PUT /planes/{mes}/ingreso-referencia`.
class IngresoReferenciaDto {
  const IngresoReferenciaDto({required this.monto});

  final Decimal? monto;

  Map<String, Object?> toJson() => <String, Object?>{
    'monto': monto == null ? null : moneyToJson(monto!),
  };
}
