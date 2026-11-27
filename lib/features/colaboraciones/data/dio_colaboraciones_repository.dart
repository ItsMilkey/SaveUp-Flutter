import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_json.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json_reading.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/instants.dart';
import '../domain/colaboracion.dart';
import '../domain/colaboraciones_repository.dart';

final Provider<ColaboracionesRepository> colaboracionesRepositoryProvider =
    Provider<ColaboracionesRepository>((Ref ref) {
      return DioColaboracionesRepository(client: ref.watch(apiClientProvider));
    });

class DioColaboracionesRepository implements ColaboracionesRepository {
  const DioColaboracionesRepository({required this.client});

  final ApiClient client;

  @override
  Future<SnapshotColaboraciones> cargar() async {
    final List<dynamic> respuestas = await Future.wait<dynamic>(<Future<dynamic>>[
      readList(() => client.get<dynamic>('/colaboraciones/metas/me')),
      readList(() => client.get<dynamic>('/colaboraciones/deudas-directas/me')),
      readList(() => client.get<dynamic>('/colaboraciones/deudas-grupales/me')),
      readList(() => client.get<dynamic>('/colaboraciones/invitaciones/me')),
      readList(() => client.get<dynamic>('/colaboraciones/actividad/me')),
    ]);
    return parseJson(
      () => SnapshotColaboraciones(
        metas: _mapList(respuestas[0], _meta),
        deudas: _mapList(respuestas[1], _deuda),
        deudasGrupales: _mapList(respuestas[2], _deudaGrupal),
        invitaciones: _mapList(respuestas[3], _invitacion),
        actividad: _mapList(respuestas[4], _actividad),
      ),
    );
  }

  @override
  Future<List<InvitacionColaborativa>> crearMeta(MetaCompartidaDatos datos) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/colaboraciones/metas',
        data: <String, dynamic>{
          'nombre': datos.nombre,
          if (datos.montoObjetivo != null)
            'montoObjetivo': moneyToJson(datos.montoObjetivo!),
          if (datos.fechaLimite != null)
            'fechaLimite': datos.fechaLimite!.toJson(),
          'permisoEdicion': datos.permisoEdicion.codigo,
          'emailsInvitados': datos.emailsInvitados,
        },
      ),
    );
    return parseJson(
      () => _mapList(body['invitaciones'] as List<dynamic>, _invitacion),
    );
  }

  @override
  Future<InvitacionColaborativa> crearDeuda(DeudaDirectaDatos datos) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/colaboraciones/deudas-directas',
        data: <String, dynamic>{
          'nombre': datos.nombre,
          if (datos.descripcion != null && datos.descripcion!.trim().isNotEmpty)
            'descripcion': datos.descripcion!.trim(),
          'monto': moneyToJson(datos.monto),
          'direccion': datos.direccion,
          'emailContraparte': datos.emailContraparte.trim(),
          'permisoEdicion': datos.permisoEdicion.codigo,
        },
      ),
    );
    return parseJson(() => _invitacion(_asMap(body['invitacion'])));
  }

  @override
  Future<List<InvitacionColaborativa>> crearDeudaGrupal(DeudaGrupalDatos datos) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/colaboraciones/deudas-grupales',
        data: <String, dynamic>{
          'nombre': datos.nombre,
          if (datos.descripcion != null && datos.descripcion!.trim().isNotEmpty)
            'descripcion': datos.descripcion!.trim(),
          'acreedorExterno': datos.acreedorExterno.trim(),
          'montoTotal': moneyToJson(datos.montoTotal),
          'permisoEdicion': datos.permisoEdicion.codigo,
          'participantes': <Map<String, dynamic>>[
            for (final ResponsabilidadParticipante participante in datos.participantes)
              <String, dynamic>{
                'email': participante.email.trim(),
                'monto': moneyToJson(participante.monto),
              },
          ],
          if (datos.cuotas.isNotEmpty)
            'cuotas': <Map<String, dynamic>>[
              for (final CuotaGrupalDatos cuota in datos.cuotas)
                <String, dynamic>{
                  'monto': moneyToJson(cuota.monto),
                  'fechaVencimiento': cuota.fechaVencimiento.toJson(),
                },
            ],
        },
      ),
    );
    return parseJson(
      () => _mapList(
        body['invitaciones'] as List<dynamic>,
        _invitacion,
      ),
    );
  }

  @override
  Future<void> aceptarInvitacion(int invitacionId) async {
    await client.post<dynamic>(
      '/colaboraciones/invitaciones/$invitacionId/aceptar',
    );
  }

  @override
  Future<void> aceptarCodigoInvitacion(String codigo) async {
    await client.post<dynamic>(
      '/colaboraciones/invitaciones/aceptar',
      data: <String, dynamic>{'codigo': codigo.trim()},
    );
  }

  @override
  Future<void> rechazarInvitacion(int invitacionId) async {
    await client.post<dynamic>(
      '/colaboraciones/invitaciones/$invitacionId/rechazar',
    );
  }

  @override
  Future<void> revocarInvitacion(int invitacionId) async {
    await client.delete<dynamic>('/colaboraciones/invitaciones/$invitacionId');
  }

  @override
  Future<void> marcarActividadLeida(int actividadId) async {
    await client.patch<dynamic>(
      '/colaboraciones/actividad/$actividadId/leida',
    );
  }

  @override
  Future<OperacionColaborativa> registrarAporte(
    int metaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  }) => _registrarOperacion(
    '/colaboraciones/metas/$metaId/aportes',
    monto: monto,
    descripcion: descripcion,
    emailAtribucion: emailAtribucion,
  );

  @override
  Future<OperacionColaborativa> registrarGastoMeta(
    int metaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  }) => _registrarOperacion(
    '/colaboraciones/metas/$metaId/gastos',
    monto: monto,
    descripcion: descripcion,
    emailAtribucion: emailAtribucion,
  );

  @override
  Future<OperacionColaborativa> registrarRetiroMeta(
    int metaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  }) => _registrarOperacion(
    '/colaboraciones/metas/$metaId/retiros',
    monto: monto,
    descripcion: descripcion,
    emailAtribucion: emailAtribucion,
  );

  @override
  Future<OperacionColaborativa> registrarPagoDeuda(
    int deudaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  }) => _registrarOperacion(
    '/colaboraciones/deudas-directas/$deudaId/pagos',
    monto: monto,
    descripcion: descripcion,
    emailAtribucion: emailAtribucion,
  );

  @override
  Future<OperacionColaborativa> proponerCondonacion(
    int deudaId, {
    required Decimal monto,
    required String descripcion,
  }) => _registrarOperacion(
    '/colaboraciones/deudas-directas/$deudaId/condonaciones',
    monto: monto,
    descripcion: descripcion,
  );

  @override
  Future<OperacionColaborativa> proponerCambioMeta(
    int metaId, {
    Decimal? montoObjetivo,
    CalendarDate? fechaLimite,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.put<dynamic>(
        '/colaboraciones/metas/$metaId/cambios',
        data: <String, dynamic>{
          if (montoObjetivo != null)
            'montoObjetivo': moneyToJson(montoObjetivo),
          if (fechaLimite != null) 'fechaLimite': fechaLimite.toJson(),
        },
      ),
    );
    return parseJson(() => _operacion(body));
  }

  @override
  Future<OperacionColaborativa> proponerCambioDeuda(
    int deudaId, {
    required Decimal saldoPendiente,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.put<dynamic>(
        '/colaboraciones/deudas-directas/$deudaId/cambios',
        data: <String, dynamic>{
          'saldoPendiente': moneyToJson(saldoPendiente),
        },
      ),
    );
    return parseJson(() => _operacion(body));
  }

  Future<OperacionColaborativa> _registrarOperacion(
    String path, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        path,
        data: <String, dynamic>{
          'monto': moneyToJson(monto),
          'descripcion': descripcion.trim(),
          if (emailAtribucion != null && emailAtribucion.trim().isNotEmpty)
            'emailAtribucion': emailAtribucion.trim(),
        },
      ),
    );
    return parseJson(() => _operacion(body));
  }

  @override
  Future<OperacionColaborativa> decidirOperacion(
    int operacionId, {
    required bool aceptar,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/colaboraciones/operaciones/$operacionId/decision',
        data: <String, dynamic>{'aceptar': aceptar},
      ),
    );
    return parseJson(() => _operacion(body));
  }

  @override
  Future<OperacionColaborativa> registrarPagoGrupal(
    int deudaId,
    PagoGrupalDatos datos,
  ) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/colaboraciones/deudas-grupales/$deudaId/pagos',
        data: <String, dynamic>{
          'monto': moneyToJson(datos.monto),
          'descripcion': datos.descripcion.trim(),
          'imputaciones': <Map<String, dynamic>>[
            for (final ImputacionPagoDatos imputacion in datos.imputaciones)
              <String, dynamic>{
                'email': imputacion.email.trim(),
                'monto': moneyToJson(imputacion.monto),
              },
          ],
        },
      ),
    );
    return parseJson(() => _operacion(body));
  }

  @override
  Future<OperacionColaborativa> proponerCambioReparto(
    int deudaId,
    RepartoDatos datos,
  ) async {
    final Map<String, dynamic> body = await readObject(
      () => client.put<dynamic>(
        '/colaboraciones/deudas-grupales/$deudaId/repartos',
        data: <String, dynamic>{
          'responsabilidades': <Map<String, dynamic>>[
            for (final ResponsabilidadParticipante responsabilidad
                in datos.responsabilidades)
              <String, dynamic>{
                'email': responsabilidad.email.trim(),
                'monto': moneyToJson(responsabilidad.monto),
              },
          ],
        },
      ),
    );
    return parseJson(() => _operacion(body));
  }

  @override
  Future<OperacionColaborativa> salirDeudaGrupal(
    int deudaId,
    SalidaDeudaDatos datos,
  ) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/colaboraciones/deudas-grupales/$deudaId/salir',
        data: <String, dynamic>{
          if (datos.reasignaciones.isNotEmpty)
            'reasignaciones': <Map<String, dynamic>>[
              for (final ResponsabilidadParticipante reasignacion
                  in datos.reasignaciones)
                <String, dynamic>{
                  'email': reasignacion.email.trim(),
                  'monto': moneyToJson(reasignacion.monto),
                },
            ],
        },
      ),
    );
    return parseJson(() => _operacion(body));
  }

  @override
  Future<InvitacionColaborativa> registrarAdelanto(
    int deudaId,
    int operacionId, {
    required String email,
    String? descripcion,
  }) async {
    final Map<String, dynamic> body = await readObject(
      () => client.post<dynamic>(
        '/colaboraciones/deudas-grupales/$deudaId/operaciones/$operacionId/adelantos',
        data: <String, dynamic>{
          'email': email.trim(),
          if (descripcion != null && descripcion.trim().isNotEmpty)
            'descripcion': descripcion.trim(),
        },
      ),
    );
    return parseJson(() => _invitacion(_asMap(body['invitacion'])));
  }

  @override
  Future<void> cancelarDeudaGrupal(int deudaId) async {
    await client.patch<dynamic>(
      '/colaboraciones/deudas-grupales/$deudaId/cancelar',
    );
  }

  @override
  Future<List<OperacionColaborativa>> historialMeta(int metaId) async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>('/colaboraciones/metas/$metaId/historial'),
    );
    return parseJson(() => _mapList(body, _operacion));
  }

  @override
  Future<List<OperacionColaborativa>> historialDeuda(int deudaId) async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>(
        '/colaboraciones/deudas-directas/$deudaId/historial',
      ),
    );
    return parseJson(() => _mapList(body, _operacion));
  }

  @override
  Future<List<OperacionColaborativa>> historialDeudaGrupal(int deudaId) async {
    final List<dynamic> body = await readList(
      () => client.get<dynamic>(
        '/colaboraciones/deudas-grupales/$deudaId/historial',
      ),
    );
    return parseJson(() => _mapList(body, _operacion));
  }

  @override
  Future<void> salirMeta(int metaId) async {
    await client.post<dynamic>('/colaboraciones/metas/$metaId/salir');
  }

  @override
  Future<OperacionColaborativa> cancelarMeta(int metaId) async {
    final Map<String, dynamic> body = await readObject(
      () => client.patch<dynamic>('/colaboraciones/metas/$metaId/cancelar'),
    );
    return parseJson(() => _operacion(body));
  }
}

MetaCompartida _meta(Map<String, dynamic> json) => MetaCompartida(
  id: _int(json['id']),
  nombre: _string(json['nombre']),
  montoObjetivo: _moneyOrNull(json['montoObjetivo']),
  fechaLimite: _dateOrNull(json['fechaLimite']),
  montoActual: _money(json['montoActual']),
  estado: EstadoMetaCompartida.parse(_string(json['estado'])),
  permisoEdicion: _permiso(_string(json['permisoEdicion'])),
  participantes: _mapList(
    json['participantes'] as List<dynamic>,
    (Map<String, dynamic> item) => ParticipanteMeta(
      id: _int(item['id']),
      nombre: _string(item['nombre']),
      email: _string(item['email']),
      creador: item['creador'] as bool? ?? false,
      actual: item['actual'] as bool? ?? false,
    ),
  ),
  invitacionesPendientes: _mapList(
    json['invitacionesPendientes'] as List<dynamic>? ?? const <dynamic>[],
    _invitacion,
  ),
);

DeudaDirecta _deuda(Map<String, dynamic> json) => DeudaDirecta(
  id: _int(json['id']),
  nombre: _string(json['nombre']),
  descripcion: json['descripcion'] as String?,
  montoOriginal: _money(json['montoOriginal']),
  saldoPendiente: _money(json['saldoPendiente']),
  deudorNombre: json['deudorNombre'] as String?,
  acreedorNombre: json['acreedorNombre'] as String?,
  deudorEmail: json['deudorEmail'] as String?,
  acreedorEmail: json['acreedorEmail'] as String?,
  yoSoyDeudor: json['yoSoyDeudor'] as bool? ?? false,
  yoSoyAcreedor: json['yoSoyAcreedor'] as bool? ?? false,
  creadorActual: json['creadorActual'] as bool? ?? false,
  invitacionesPendientes: _mapList(
    json['invitacionesPendientes'] as List<dynamic>? ?? const <dynamic>[],
    _invitacion,
  ),
  estado: EstadoDeudaDirecta.parse(_string(json['estado'])),
  permisoEdicion: _permiso(_string(json['permisoEdicion'])),
  creadoEn: parseInstant(_string(json['creadoEn'])),
);

InvitacionColaborativa _invitacion(Map<String, dynamic> json) =>
    InvitacionColaborativa(
      id: _int(json['id']),
      tipoRecurso: _string(json['tipoRecurso']),
      recursoId: _int(json['recursoId']),
      nombreRecurso: _string(json['nombreRecurso']),
      nombreCreador: _string(json['nombreCreador']),
      emailInvitado: _string(json['emailInvitado']),
      deudorNombre: json['deudorNombre'] as String?,
      acreedorNombre: json['acreedorNombre'] as String?,
      monto: _moneyOrNull(json['monto']),
      montoObjetivo: _moneyOrNull(json['montoObjetivo']),
      fechaLimite: _dateOrNull(json['fechaLimite']),
      estado: _string(json['estado']),
      expiraEn: parseInstant(_string(json['expiraEn'])),
      codigo: json['codigo'] as String?,
      acreedorExterno: json['acreedorExterno'] as String?,
      montoTotal: _moneyOrNull(json['montoTotal']),
      responsabilidadInvitada: _moneyOrNull(json['responsabilidadInvitada']),
    );

OperacionColaborativa _operacion(Map<String, dynamic> json) =>
    OperacionColaborativa(
      id: _int(json['id']),
      tipoRecurso: _string(json['tipoRecurso']),
      recursoId: _int(json['recursoId']),
      tipo: _string(json['tipo']),
      monto: _money(json['monto']),
      descripcion: _string(json['descripcion']),
      registradoPor: _string(json['registradoPor']),
      atribuidoA: json['atribuidoA'] as String?,
      estado: EstadoColaborativo.parse(_string(json['estado'])),
      creadoEn: parseInstant(_string(json['creadoEn'])),
      nuevoMontoObjetivo: _moneyOrNull(json['nuevoMontoObjetivo']),
      nuevaFechaLimite: _dateOrNull(json['nuevaFechaLimite']),
      nuevoSaldoPendiente: _moneyOrNull(json['nuevoSaldoPendiente']),
      cancelarMeta: json['cancelarMeta'] as bool? ?? false,
      atribuciones: _mapList(
        json['atribuciones'] as List<dynamic>? ?? const <dynamic>[],
        (Map<String, dynamic> item) => AtribucionMeta(
          participante: _string(item['participante']),
          monto: _money(item['monto']),
        ),
      ),
      imputacionesPago: _mapList(
        json['imputacionesPago'] as List<dynamic>? ?? const <dynamic>[],
        _montoParticipante,
      ),
      cambiosResponsabilidad: _mapList(
        json['cambiosResponsabilidad'] as List<dynamic>? ?? const <dynamic>[],
        _montoParticipante,
      ),
    );

MontoParticipante _montoParticipante(Map<String, dynamic> json) =>
    MontoParticipante(
      email: _string(json['email']),
      nombre: _string(json['nombre']),
      monto: _money(json['monto']),
    );

DeudaGrupal _deudaGrupal(Map<String, dynamic> json) => DeudaGrupal(
  id: _int(json['id']),
  nombre: _string(json['nombre']),
  descripcion: json['descripcion'] as String?,
  acreedorExterno: _string(json['acreedorExterno']),
  montoTotal: _money(json['montoTotal']),
  saldoPendiente: _money(json['saldoPendiente']),
  estado: EstadoDeudaGrupal.parse(_string(json['estado'])),
  permisoEdicion: _permiso(_string(json['permisoEdicion'])),
  nombreCreador: _string(json['nombreCreador']),
  creadorActual: json['creadorActual'] as bool? ?? false,
  participanteActual: json['participanteActual'] as bool? ?? false,
  miResponsabilidadPendiente: _money(json['miResponsabilidadPendiente']),
  participantes: _mapList(
    json['participantes'] as List<dynamic>,
    (Map<String, dynamic> item) => ParticipanteDeudaGrupal(
      id: _int(item['id']),
      nombre: _string(item['nombre']),
      email: _string(item['email']),
      responsabilidadOriginal: _money(item['responsabilidadOriginal']),
      responsabilidadPendiente: _money(item['responsabilidadPendiente']),
      estado: EstadoParticipanteDeudaGrupal.parse(_string(item['estado'])),
      actual: item['actual'] as bool? ?? false,
    ),
  ),
  cuotas: _mapList(
    json['cuotas'] as List<dynamic>? ?? const <dynamic>[],
    (Map<String, dynamic> item) => CuotaGrupal(
      numero: _int(item['numero']),
      monto: _money(item['monto']),
      fechaVencimiento: _date(item['fechaVencimiento']),
    ),
  ),
  creadoEn: json['creadoEn'] == null
      ? null
      : parseInstant(_string(json['creadoEn'])),
  invitacionesPendientes: _mapList(
    json['invitacionesPendientes'] as List<dynamic>? ?? const <dynamic>[],
    _invitacion,
  ),
);

ActividadColaborativa _actividad(Map<String, dynamic> json) =>
    ActividadColaborativa(
      id: _int(json['id']),
      tipo: _string(json['tipo']),
      tipoRecurso: _string(json['tipoRecurso']),
      recursoId: _int(json['recursoId']),
      operacion: json['operacion'] == null
          ? null
          : _operacion(_asMap(json['operacion'])),
      invitacion: json['invitacion'] == null
          ? null
          : _invitacion(_asMap(json['invitacion'])),
      accionRequerida: json['accionRequerida'] as bool? ?? false,
      leida: json['leida'] as bool? ?? false,
      creadoEn: parseInstant(_string(json['creadoEn'])),
    );

PermisoEdicionCompartida _permiso(String raw) => switch (raw) {
  'TODOS' => PermisoEdicionCompartida.todos,
  'SOLO_CREADOR' => PermisoEdicionCompartida.soloCreador,
  _ => throw FormatException('Permiso de edición desconocido: $raw'),
};

Decimal? _moneyOrNull(Object? raw) {
  if (raw == null) return null;
  return moneyFromJson(raw);
}

Decimal _money(Object? raw) => moneyFromJson(raw);

CalendarDate? _dateOrNull(Object? raw) =>
    raw == null ? null : CalendarDate.parse(_string(raw));

CalendarDate _date(Object? raw) => CalendarDate.parse(_string(raw));

int _int(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  throw const FormatException('Se esperaba un entero.');
}

String _string(Object? raw) {
  if (raw is String) return raw;
  throw const FormatException('Se esperaba texto.');
}

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is! Map) throw const FormatException('Se esperaba un objeto JSON.');
  return raw.map((Object? key, Object? value) => MapEntry(key.toString(), value));
}

List<T> _mapList<T>(
  List<dynamic> raw,
  T Function(Map<String, dynamic>) parser,
) => raw.map((Object? item) => parser(_asMap(item))).toList(growable: false);
