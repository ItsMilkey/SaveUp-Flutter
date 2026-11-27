import 'package:decimal/decimal.dart';

import '../../../core/time/calendar_date.dart';
import 'colaboracion.dart';

abstract interface class ColaboracionesRepository {
  Future<SnapshotColaboraciones> cargar();

  Future<List<InvitacionColaborativa>> crearMeta(MetaCompartidaDatos datos);
  Future<InvitacionColaborativa> crearDeuda(DeudaDirectaDatos datos);
  Future<List<InvitacionColaborativa>> crearDeudaGrupal(DeudaGrupalDatos datos);
  Future<void> aceptarInvitacion(int invitacionId);
  Future<void> aceptarCodigoInvitacion(String codigo);
  Future<void> rechazarInvitacion(int invitacionId);
  Future<void> revocarInvitacion(int invitacionId);
  Future<void> marcarActividadLeida(int actividadId);
  Future<OperacionColaborativa> registrarAporte(
    int metaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  });
  Future<OperacionColaborativa> registrarGastoMeta(
    int metaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  });
  Future<OperacionColaborativa> registrarRetiroMeta(
    int metaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  });
  Future<OperacionColaborativa> registrarPagoDeuda(
    int deudaId, {
    required Decimal monto,
    required String descripcion,
    String? emailAtribucion,
  });
  Future<OperacionColaborativa> proponerCondonacion(
    int deudaId, {
    required Decimal monto,
    required String descripcion,
  });
  Future<OperacionColaborativa> proponerCambioMeta(
    int metaId, {
    Decimal? montoObjetivo,
    CalendarDate? fechaLimite,
  });
  Future<OperacionColaborativa> proponerCambioDeuda(
    int deudaId, {
    required Decimal saldoPendiente,
  });
  Future<OperacionColaborativa> decidirOperacion(
    int operacionId, {
    required bool aceptar,
  });
  Future<OperacionColaborativa> registrarPagoGrupal(
    int deudaId,
    PagoGrupalDatos datos,
  );
  Future<OperacionColaborativa> proponerCambioReparto(
    int deudaId,
    RepartoDatos datos,
  );
  Future<OperacionColaborativa> salirDeudaGrupal(
    int deudaId,
    SalidaDeudaDatos datos,
  );
  Future<InvitacionColaborativa> registrarAdelanto(
    int deudaId,
    int operacionId, {
    required String email,
    String? descripcion,
  });
  Future<void> cancelarDeudaGrupal(int deudaId);
  Future<List<OperacionColaborativa>> historialMeta(int metaId);
  Future<List<OperacionColaborativa>> historialDeuda(int deudaId);
  Future<List<OperacionColaborativa>> historialDeudaGrupal(int deudaId);
  Future<void> salirMeta(int metaId);
  Future<OperacionColaborativa> cancelarMeta(int metaId);
}
