import 'package:decimal/decimal.dart';

import '../../../core/time/calendar_date.dart';

enum PermisoEdicionCompartida {
  soloCreador('SOLO_CREADOR'),
  todos('TODOS');

  const PermisoEdicionCompartida(this.codigo);
  final String codigo;
}

enum EstadoMetaCompartida {
  pendiente('PENDIENTE'),
  activa('ACTIVA'),
  cancelada('CANCELADA');

  const EstadoMetaCompartida(this.codigo);
  final String codigo;

  static EstadoMetaCompartida parse(String raw) => values.firstWhere(
    (EstadoMetaCompartida value) => value.codigo == raw,
    orElse: () => throw FormatException('Estado de meta compartida desconocido: $raw'),
  );
}

enum EstadoDeudaDirecta {
  pendiente('PENDIENTE'),
  activa('ACTIVA'),
  pagada('PAGADA'),
  condonada('CONDONADA');

  const EstadoDeudaDirecta(this.codigo);
  final String codigo;

  static EstadoDeudaDirecta parse(String raw) => values.firstWhere(
    (EstadoDeudaDirecta value) => value.codigo == raw,
    orElse: () => throw FormatException('Estado de deuda directa desconocido: $raw'),
  );
}

enum EstadoColaborativo {
  pendiente('PENDIENTE'),
  confirmado('CONFIRMADO'),
  rechazado('RECHAZADO');

  const EstadoColaborativo(this.codigo);
  final String codigo;

  static EstadoColaborativo parse(String raw) => values.firstWhere(
    (EstadoColaborativo value) => value.codigo == raw,
    orElse: () => throw FormatException('Estado colaborativo desconocido: $raw'),
  );
}

class ParticipanteMeta {
  const ParticipanteMeta({
    required this.id,
    required this.nombre,
    required this.email,
    required this.creador,
    required this.actual,
  });

  final int id;
  final String nombre;
  final String email;
  final bool creador;
  final bool actual;
}

class MetaCompartida {
  const MetaCompartida({
    required this.id,
    required this.nombre,
    required this.montoActual,
    required this.estado,
    required this.permisoEdicion,
    required this.participantes,
    required this.invitacionesPendientes,
    this.montoObjetivo,
    this.fechaLimite,
  });

  final int id;
  final String nombre;
  final Decimal? montoObjetivo;
  final CalendarDate? fechaLimite;
  final Decimal montoActual;
  final EstadoMetaCompartida estado;
  final PermisoEdicionCompartida permisoEdicion;
  final List<ParticipanteMeta> participantes;
  final List<InvitacionColaborativa> invitacionesPendientes;
}

class DeudaDirecta {
  const DeudaDirecta({
    required this.id,
    required this.nombre,
    required this.montoOriginal,
    required this.saldoPendiente,
    required this.estado,
    required this.permisoEdicion,
    required this.creadoEn,
    required this.yoSoyDeudor,
    required this.yoSoyAcreedor,
    required this.creadorActual,
    required this.invitacionesPendientes,
    this.descripcion,
    this.deudorNombre,
    this.acreedorNombre,
    this.deudorEmail,
    this.acreedorEmail,
  });

  final int id;
  final String nombre;
  final String? descripcion;
  final Decimal montoOriginal;
  final Decimal saldoPendiente;
  final String? deudorNombre;
  final String? acreedorNombre;
  final String? deudorEmail;
  final String? acreedorEmail;
  final bool yoSoyDeudor;
  final bool yoSoyAcreedor;
  final bool creadorActual;
  final List<InvitacionColaborativa> invitacionesPendientes;
  final EstadoDeudaDirecta estado;
  final PermisoEdicionCompartida permisoEdicion;
  final DateTime creadoEn;
}

class InvitacionColaborativa {
  const InvitacionColaborativa({
    required this.id,
    required this.tipoRecurso,
    required this.recursoId,
    required this.nombreRecurso,
    required this.nombreCreador,
    required this.emailInvitado,
    required this.estado,
    required this.expiraEn,
    this.deudorNombre,
    this.acreedorNombre,
    this.monto,
    this.montoObjetivo,
    this.fechaLimite,
    this.codigo,
  });

  final int id;
  final String tipoRecurso;
  final int recursoId;
  final String nombreRecurso;
  final String nombreCreador;
  final String emailInvitado;
  final String? deudorNombre;
  final String? acreedorNombre;
  final Decimal? monto;
  final Decimal? montoObjetivo;
  final CalendarDate? fechaLimite;
  final String estado;
  final DateTime expiraEn;
  final String? codigo;
}

class AtribucionMeta {
  const AtribucionMeta({required this.participante, required this.monto});

  final String participante;
  final Decimal monto;
}

class OperacionColaborativa {
  const OperacionColaborativa({
    required this.id,
    required this.tipoRecurso,
    required this.recursoId,
    required this.tipo,
    required this.monto,
    required this.descripcion,
    required this.registradoPor,
    required this.estado,
    required this.creadoEn,
    required this.atribuciones,
    this.atribuidoA,
    this.nuevoMontoObjetivo,
    this.nuevaFechaLimite,
    this.nuevoSaldoPendiente,
    this.cancelarMeta = false,
  });

  final int id;
  final String tipoRecurso;
  final int recursoId;
  final String tipo;
  final Decimal monto;
  final String descripcion;
  final String registradoPor;
  final String? atribuidoA;
  final EstadoColaborativo estado;
  final DateTime creadoEn;
  final Decimal? nuevoMontoObjetivo;
  final CalendarDate? nuevaFechaLimite;
  final Decimal? nuevoSaldoPendiente;
  final bool cancelarMeta;
  final List<AtribucionMeta> atribuciones;
}

class ActividadColaborativa {
  const ActividadColaborativa({
    required this.id,
    required this.tipo,
    required this.tipoRecurso,
    required this.recursoId,
    required this.accionRequerida,
    required this.leida,
    required this.creadoEn,
    this.operacion,
    this.invitacion,
  });

  final int id;
  final String tipo;
  final String tipoRecurso;
  final int recursoId;
  final OperacionColaborativa? operacion;
  final InvitacionColaborativa? invitacion;
  final bool accionRequerida;
  final bool leida;
  final DateTime creadoEn;
}

class MetaCompartidaDatos {
  const MetaCompartidaDatos({
    required this.nombre,
    required this.permisoEdicion,
    required this.emailsInvitados,
    this.montoObjetivo,
    this.fechaLimite,
  });

  final String nombre;
  final Decimal? montoObjetivo;
  final CalendarDate? fechaLimite;
  final PermisoEdicionCompartida permisoEdicion;
  final List<String> emailsInvitados;
}

class DeudaDirectaDatos {
  const DeudaDirectaDatos({
    required this.nombre,
    required this.monto,
    required this.direccion,
    required this.emailContraparte,
    required this.permisoEdicion,
    this.descripcion,
  });

  final String nombre;
  final String? descripcion;
  final Decimal monto;
  final String direccion;
  final String emailContraparte;
  final PermisoEdicionCompartida permisoEdicion;
}

class CambioMetaDatos {
  const CambioMetaDatos({this.montoObjetivo, this.fechaLimite});

  final Decimal? montoObjetivo;
  final CalendarDate? fechaLimite;
}

class SnapshotColaboraciones {
  const SnapshotColaboraciones({
    required this.metas,
    required this.deudas,
    required this.invitaciones,
    required this.actividad,
  });

  final List<MetaCompartida> metas;
  final List<DeudaDirecta> deudas;
  final List<InvitacionColaborativa> invitaciones;
  final List<ActividadColaborativa> actividad;
}
